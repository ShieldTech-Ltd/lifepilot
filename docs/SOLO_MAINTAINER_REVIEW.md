# Solo maintainer PR review and admin self-merge

LifePilot is currently a **one-person** repository (`@TFT444`). Tracked in issue [#7](https://github.com/TFT444/lifepilot/issues/7).

## Hard GitHub limit

GitHub **never** lets a pull-request author click **Approve** on their own PR. No setting turns that on — not even for repository admins.

What we *can* do for a solo admin:

1. **Primary (recommended for solo):** stop requiring an external approving review, keep PRs + CI, and allow admins to merge their own work.
2. **Optional:** keep 1 required approval and let **Cursor Approval Agents** approve as the `cursor` identity (second pair of eyes).

---

## Primary path — admin can merge their own code

### One-command (from your machine as `@TFT444`)

```bash
gh auth login   # personal account with admin on TFT444/lifepilot
./scripts/enable-solo-admin-merge.sh --dry-run   # preview
./scripts/enable-solo-admin-merge.sh             # apply to develop + main
```

That script sets:

| Setting | Solo value | Why |
|---|---|---|
| Required approving reviews | `0` | No external Approve needed |
| Require review from Code Owners | off | `@TFT444` alone in CODEOWNERS cannot satisfy code-owner review on their own PRs |
| Enforce admins / “Do not allow bypassing” | off | Admin retains break-glass merge |

CI status checks stay required if they were already configured.

### Same change in the GitHub UI

Repo → **Settings** → **Branches** (or **Rules** → rulesets) for `develop` and `main`:

1. **Require a pull request before merging** — keep enabled  
2. **Required approvals** → **0**  
3. Uncheck **Require review from Code Owners**  
4. Uncheck **Do not allow bypassing the above settings** (or turn off “Enforce admins”)  
5. Keep required status checks (Build / Lint / Test / CI Status)

After this, open any of your PRs that is CI-green and merge with the normal green button — no `--admin` override needed.

### Re-tighten when a second human joins

```bash
REQUIRED_APPROVALS=1 ENFORCE_ADMINS=true REQUIRE_CODE_OWNERS=true \
  ./scripts/enable-solo-admin-merge.sh
```

---

## Optional path — Cursor bot as second identity

Use this when you want **1 required approval** again, but still need a non-`@TFT444` approver.

### 1) Connect GitHub to Cursor

1. Open [cursor.com/dashboard/integrations](https://cursor.com/dashboard/integrations)
2. Connect **GitHub**
3. Grant access to `TFT444/lifepilot`

### 2) Enable Bugbot

1. Open [cursor.com/dashboard/bugbot](https://cursor.com/dashboard/bugbot)
2. Enable Bugbot for `lifepilot`
3. Manual trigger comments: `cursor review` or `bugbot run`

Bugbot uses `.cursor/BUGBOT.md`. Bugbot comments are **not** a GitHub Approve.

### 3) Enable Approval Agents

1. Open [Approval Agents](https://cursor.com/docs/approval-agents) in the Cursor dashboard  
2. Create a **Pull Request Approver**
3. Triggers: PR opened / PR pushed  
4. Scope: `TFT444/lifepilot`  
5. Enable **Use Bugbot Review Context** + primary action **Approve PR**  
6. Point at `APPROVAL_POLICY.md` and `.cursor/approval-policies/ROUTING.md`

Approvals appear as the **`cursor`** GitHub identity.

**Note:** If branch protection also requires **Code Owners** and CODEOWNERS only lists `@TFT444`, a Cursor approve still will not clear that gate — turn code-owner requirement off while solo (the script does this).

---

## What this agent cannot do

Cloud / CI tokens for this repo do **not** have admin on branch protection (API returns 403). Only `@TFT444` (or another admin PAT) can run `scripts/enable-solo-admin-merge.sh` or change Settings.

---

## Verify

1. Run the script (or UI steps) as admin  
2. Open a PR authored by you with green CI  
3. Confirm **Review required** is not blocking (or shows 0 required)  
4. Merge with the normal button  

Optional: keep Bugbot for review comments even when approvals are not required.

## Files

| File | Purpose |
|---|---|
| `scripts/enable-solo-admin-merge.sh` | Admin-run branch-protection patch |
| `.cursor/BUGBOT.md` | Bugbot focus |
| `APPROVAL_POLICY.md` | When Cursor may approve |
| `.cursor/approval-policies/ROUTING.md` | Approval Agent routing |
| `.github/workflows/request-cursor-review.yml` | Reminder checklist on PRs |
