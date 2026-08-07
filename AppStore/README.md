# App Store and TestFlight handoff

This directory contains the reviewed en-GB submission copy and real Simulator screenshots for LifePilot 0.5.0 build 1.

## Submission identity

- App Store name: `LifePilot: Daily Life Planner`
- On-device display name: `LifePilot`
- Primary language: English (UK)
- Primary category: Productivity
- Secondary category: Education
- Bundle ID: `com.ritiksah.lifepilot`
- Widget bundle ID: `com.ritiksah.lifepilot.widgets`
- Share extension bundle ID: `com.ritiksah.lifepilot.share`
- SKU suggestion: `LIFEPILOT-IOS-2026`
- Version: `0.5.0`
- Build: `1`
- Price: Free
- In-App Purchases: None
- Sign-in: None
- Release method: Manual release after approval

The plain name `LifePilot` is already used by current App Store listings. Confirm availability and reserve the longer listing name before uploading a build. The bundle display name does not need to change.

## Prepared assets

- `Metadata/en-GB` contains name, subtitle, promotional text, description, keywords, URLs, copyright and release notes.
- `TestFlight/en-GB` contains the beta description and end-to-end test instructions.
- `ReviewNotes.txt` explains the sample-data scope and gives App Review a complete walkthrough.
- `ExportOptions.plist` is ready for an automatic-signing App Store Connect upload once the Apple team grants distribution access.
- `VERIFICATION.md` records the automated, Simulator, iPad and physical-device evidence for the final build.
- `Screenshots/en-GB/iPhone-6.9` contains five 1320 by 2868 JPEG screenshots.
- `Screenshots/en-GB/iPad-13` contains five 2064 by 2752 JPEG screenshots.

## App privacy answers

For version 0.5.0 build 1, select **Data Not Collected**. The build has no analytics, advertising, account sign-in or backend. Profile details, preferences, approvals and imported events remain on device. Selected schedule screenshots are processed on device and are not retained by LifePilot.

If any network service, analytics SDK, account connection or server-side AI feature is added, review these answers and the privacy policy before uploading that build.

## Export compliance

The app declares `ITSAppUsesNonExemptEncryption` as `NO`. It uses only encryption supplied by Apple system services and does not implement proprietary or non-exempt encryption.

## Review declarations

- Age rating expectation: 4+, subject to completing Apple's current questionnaire.
- Content rights: confirm written permission or an appropriate licence for the supplied study-room background and app icon before public distribution.
- Product identity: present LifePilot as an independent personal planning app, with no organisational affiliation or endorsement.
- Digital Services Act: the Account Holder must answer the trader-status question in App Store Connect.
- Accessibility: declare only the features verified in the final archive and device pass.

## Remaining external gates

1. An Account Holder, Admin or App Manager must grant the current Apple account access to App Store Connect and permission to create distribution profiles.
2. Register or enable App Store identifiers and profiles for the app, widget and Share extension, including the App Group `group.com.ritiksah.lifepilot`.
3. Publish `privacy.html` and `support.html`. The intended Vercel URLs currently return HTTP 404 and must be live before submission.
4. Add a real App Review contact phone number in App Store Connect. Do not place credentials in this repository.
5. Confirm rights for all supplied visual assets.
6. Archive with Apple Distribution signing, upload to App Store Connect, wait for processing and select the build.
7. Complete the age rating, content rights, App Privacy, export compliance and DSA questionnaires.
8. Upload both screenshot sets, paste the metadata and use `ReviewNotes.txt` for App Review.
9. Start with internal TestFlight, then submit the first external build for Beta App Review.
10. After the final test pass, submit the app with manual release selected.

## Validation

Run:

```sh
./AppStore/validate.sh
./AppStore/verify-public-urls.sh
./AppStore/preflight-archive.sh /path/to/LifePilot.xcarchive
```

The first validator checks metadata limits, forbidden em dashes, screenshot dimensions and alpha channels. The second requires network access and verifies that every public App Store URL returns HTTP 200. The archive preflight checks bundle identity, versions, extensions, privacy manifests, App Group entitlements, encryption metadata and production signing.

For an installed development archive only, run the structural checks with warnings instead of distribution-signing failures:

```sh
ALLOW_DEVELOPMENT=1 ./AppStore/preflight-archive.sh /path/to/LifePilot.xcarchive
```

Apple's current limits used by the validator are 30 characters for name and subtitle, 170 for promotional text, 4,000 for description and 100 UTF-8 bytes for keywords.
