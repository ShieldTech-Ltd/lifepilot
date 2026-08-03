#!/usr/bin/env bash
# Enable solo-admin merge on LifePilot protected branches.
#
# GitHub never lets a PR author click "Approve" on their own PR. For a
# one-person repo the supported substitute is: keep PRs + required CI, but
# stop requiring an external approving review, and stop enforcing those rules
# against repository admins (so @TFT444 can merge their own work).
#
# Requires: gh CLI authenticated as a repo admin (your personal account, not
# the Cursor cloud agent token).
#
# Usage:
#   ./scripts/enable-solo-admin-merge.sh
#   ./scripts/enable-solo-admin-merge.sh --dry-run
#   BRANCHES="develop main" ./scripts/enable-solo-admin-merge.sh
#
# Re-tighten later (when a second human reviewer exists):
#   REQUIRED_APPROVALS=1 ENFORCE_ADMINS=true ./scripts/enable-solo-admin-merge.sh

set -euo pipefail

REPO="${REPO:-TFT444/lifepilot}"
BRANCHES="${BRANCHES:-develop main}"
REQUIRED_APPROVALS="${REQUIRED_APPROVALS:-0}"
ENFORCE_ADMINS="${ENFORCE_ADMINS:-false}"
REQUIRE_CODE_OWNERS="${REQUIRE_CODE_OWNERS:-false}"
DRY_RUN=false

for arg in "$@"; do
  case "$arg" in
    --dry-run) DRY_RUN=true ;;
    -h|--help)
      sed -n '2,20p' "$0"
      exit 0
      ;;
  esac
done

if ! command -v gh >/dev/null; then
  echo "error: gh CLI is required" >&2
  exit 1
fi

if ! command -v jq >/dev/null; then
  echo "error: jq is required" >&2
  exit 1
fi

echo "Repo:                $REPO"
echo "Branches:            $BRANCHES"
echo "Required approvals:  $REQUIRED_APPROVALS"
echo "Enforce admins:      $ENFORCE_ADMINS"
echo "Require code owners: $REQUIRE_CODE_OWNERS"
echo "Dry run:             $DRY_RUN"
echo

# Confirm the caller has admin (the Cursor agent token does not).
perm="$(gh api "repos/$REPO" --jq '.permissions.admin // false' 2>/dev/null || echo false)"
if [[ "$perm" != "true" ]]; then
  echo "error: authenticated gh user is not a repository admin for $REPO." >&2
  echo "       Run this from your machine while logged in as @TFT444:" >&2
  echo "         gh auth login" >&2
  echo "         ./scripts/enable-solo-admin-merge.sh" >&2
  exit 1
fi

patch_branch() {
  local branch="$1"
  echo "── $branch ──"

  if ! gh api "repos/$REPO/branches/$branch/protection" >/tmp/lp-protection-"$branch".json 2>/tmp/lp-protection-"$branch".err; then
    echo "  Could not read protection for $branch:"
    cat /tmp/lp-protection-"$branch".err >&2
    echo "  Create a branch protection / ruleset in GitHub Settings first, then re-run."
    return 1
  fi

  local payload
  payload="$(jq \
    --argjson approvals "$REQUIRED_APPROVALS" \
    --argjson enforce "$ENFORCE_ADMINS" \
    --argjson codeowners "$REQUIRE_CODE_OWNERS" \
    '
    {
      required_status_checks: (
        if .required_status_checks == null then null else {
          strict: (.required_status_checks.strict // true),
          contexts: (
            [
              (.required_status_checks.contexts // []),
              (.required_status_checks.checks // [] | map(.context))
            ] | add | unique
          )
        } end
      ),
      enforce_admins: $enforce,
      required_pull_request_reviews: {
        dismiss_stale_reviews: (.required_pull_request_reviews.dismiss_stale_reviews // true),
        require_code_owner_reviews: $codeowners,
        required_approving_review_count: $approvals,
        require_last_push_approval: (.required_pull_request_reviews.require_last_push_approval // false)
      },
      restrictions: (
        if .restrictions == null then null else {
          users: [.restrictions.users[].login],
          teams: [.restrictions.teams[].slug],
          apps: [.restrictions.apps[].slug]
        } end
      ),
      required_linear_history: (.required_linear_history.enabled // false),
      allow_force_pushes: (.allow_force_pushes.enabled // false),
      allow_deletions: (.allow_deletions.enabled // false),
      block_creations: (.block_creations.enabled // false),
      required_conversation_resolution: (.required_conversation_resolution.enabled // false)
    }
    ' /tmp/lp-protection-"$branch".json)"

  echo "$payload" | jq '{enforce_admins, required_pull_request_reviews, required_status_checks}'

  if [[ "$DRY_RUN" == "true" ]]; then
    echo "  (dry-run — not applied)"
    echo
    return 0
  fi

  echo "$payload" | gh api -X PUT "repos/$REPO/branches/$branch/protection" --input - >/dev/null
  echo "  Applied."
  echo
}

status=0
for branch in $BRANCHES; do
  patch_branch "$branch" || status=1
done

if [[ "$status" -eq 0 && "$DRY_RUN" != "true" ]]; then
  echo "Done. Admins can now merge their own PRs after required CI (no external Approve click)."
  echo "GitHub still will not let you Approve your own PR — that is a platform hard limit."
  echo "Optional: keep Cursor Approval Agents for a second-identity review when you want one."
fi

exit "$status"
