# LifePilot 0.5.0 launch verification

Verification date: 1 August 2026
Version: 0.5.0
Build: 1
Bundle ID: `com.ritiksah.lifepilot`

## Automated evidence

- `swift test`: 62 tests passed, 0 failures, including next-event agenda separation.
- iOS Simulator build: succeeded with the app, widget and Share extension.
- Release archive: succeeded at `/tmp/LifePilot-PreCommit-Final.xcarchive`.
- `./AppStore/validate.sh`: all metadata and screenshot checks passed.
- `ALLOW_DEVELOPMENT=1 ./AppStore/preflight-archive.sh /tmp/LifePilot-PreCommit-Final.xcarchive`: all structural archive checks passed, with expected development-signing warnings.
- `actionlint .github/workflows/*.yml`: passed.
- Gitleaks scans of the working tree and full Git history: no leaks found.
- Web credential review: removed API-key URL, query-string and local-storage handling; TfL access is anonymous only.
- Sensitive-entry review: password demo fields do not request password AutoFill and are cleared when the app becomes inactive or the view closes.
- Share extension review: attachment count, text size and image size are bounded before parsing.
- `tidy -errors -quiet support.html demo/support.html privacy.html demo/privacy.html`: passed.
- `git diff --check`: passed.
- Repository em dash scan: no matches.

## Device and layout evidence

- Physical iPhone 14 Pro Max: secured Release archive installed and launched successfully.
- iPhone 17 Pro Simulator: complete feature walkthrough performed in light and dark appearance.
- iPhone 17 Pro Simulator: all five destination headers and native iOS 26 Liquid Glass tab chrome visually verified in light appearance.
- iPhone 17 Pro Simulator: Home and Settings visually verified in dark appearance after the shared surface redesign.
- iPhone 17 Pro Max Simulator: 6.9-inch App Store screenshots captured at 1320 by 2868.
- iPad Pro 13-inch Simulator: onboarding, Home, Timeline, Memory, Insights and Settings verified in portrait.
- iPad Pro 13-inch Simulator: Home and Timeline verified in landscape with readable content and no clipping.

## End-to-end feature walkthrough

| Area | Evidence | Result |
| --- | --- | --- |
| First launch | Completed all four onboarding screens from a clean install | Pass |
| Home briefing | UK BSc Computing data, readiness, schedule, signals and recommendations loaded | Pass |
| Next event MVP | Home displays the next event, time and location before briefing recommendations; later events remain in the agenda | Pass |
| Smart approvals | Approved and dismissed recommendations, then relaunched | Pass, decisions persisted |
| Timeline | Filters, entry details and mark-reviewed flow exercised | Pass |
| Screenshot import | Imported an event screenshot, reviewed OCR fields, saved and relaunched | Pass, event persisted |
| Share extension | Opened LifePilot from the Safari Share sheet, edited an event and added it | Pass, event appeared in Home |
| Memory | Confirmed, forgot and restored a fact | Pass |
| Insights | Readiness, metrics, trends and agent drill-down exercised | Pass |
| Profile | Changed and restored display name, selected and removed a profile image | Pass |
| Password safety | Password screen inspected; automated test verifies no password text is stored | Pass |
| Connected sources | Paused and restored Travel, then checked cross-screen updates | Pass |
| Appearance | System, Light and Dark tested; System restored | Pass |
| Approval preferences | High-risk alert setting toggled and restored | Pass |
| Widget | Upcoming-event snapshot refreshed with the real next event | Pass |
| Live Activity | Started, refreshed and ended; actual event, readiness and action count shown | Pass |
| Dynamic Island | Live Activity content exercised on a supported Simulator configuration | Pass |
| Privacy | In-app policy and reset explanation reviewed | Pass |
| Local reset | Reset local demo data and relaunched | Pass, onboarding returned |
| iPhone installation | Final Release archive installed and launched on the paired device | Pass |

## App Store asset evidence

- Five iPhone 6.9-inch screenshots: 1320 by 2868 JPEG, no alpha channel.
- Five iPad 13-inch screenshots: 2064 by 2752 JPEG, no alpha channel.
- App name: 29 of 30 characters.
- Subtitle: 26 of 30 characters.
- Promotional text: 147 of 170 characters.
- Description: 1,261 of 4,000 characters.
- Keywords: 91 of 100 UTF-8 bytes.
- App, widget and Share extension privacy manifests are embedded and declare no tracking or collected data.
- The archive declares `ITSAppUsesNonExemptEncryption` as `NO`.
- The monochrome background is a 3072 by 5504 native app asset, verified in light mode on iPhone 17 Pro Simulator.

## Remaining external gates

These items prevent an App Store Connect upload but do not affect the installed showcase build:

1. The Apple team currently provides only development signing. Production preflight correctly fails because `get-task-allow` is enabled in the app and both extensions, the identity is Apple Development, and the local trust chain is not an App Store distribution chain.
2. App Store Connect reports no provider for the signed-in user and does not permit creation of distribution profiles for the app, widget or Share extension.
3. The prepared privacy and support pages still need stable public URLs before submission; update the metadata URL files after publishing them. A marketing website is outside this release scope.
4. The Account Holder must provide the App Review phone number, answer the DSA trader-status question and complete current age-rating and content-rights declarations.
5. Written permission or an appropriate licence must be confirmed for the supplied app icon and monochrome background before public distribution.

After these gates are resolved, rerun the URL verifier and production archive preflight, export with `AppStore/ExportOptions.plist`, upload to App Store Connect and begin internal TestFlight.
