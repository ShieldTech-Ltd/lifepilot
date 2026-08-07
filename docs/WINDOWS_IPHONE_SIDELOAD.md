# Install LifePilot on an iPhone from Windows

This workflow installs a private development build. It does not publish
LifePilot to the App Store or TestFlight.

## What the workflow does

GitHub Actions builds the device version of LifePilot on a hosted macOS runner
and uploads `LifePilot-unsigned.ipa` as a workflow artifact. AltStore Classic
then uses an Apple Account to sign and install that IPA from Windows.

No Apple Account password, app-specific password, certificate, or private key
belongs in this repository or in a GitHub issue, pull request, or chat.

## Windows prerequisites

- An iPhone running iOS 17 or later
- A USB data cable
- iTunes and iCloud downloaded directly from Apple, not the Microsoft Store
- AltServer for Windows from AltStore
- An Apple Account with two-factor authentication enabled

Follow AltStore's current Windows installation instructions:
<https://faq.altstore.io/altstore-classic/how-to-install-altstore-windows>

## Download the LifePilot IPA

1. Open the GitHub Actions run for the LifePilot pull request or branch.
2. Wait for the `Native App` job to pass.
3. Download the artifact named `LifePilot-unsigned-ipa-<run-id>`.
4. Extract the downloaded artifact ZIP. It contains
   `LifePilot-unsigned.ipa`.
5. Put the IPA somewhere available in the iPhone Files app, such as iCloud
   Drive.

## Install AltStore on the iPhone

1. Connect the unlocked iPhone to Windows with USB and choose **Trust** when
   prompted.
2. Open iTunes, select the iPhone, enable **Sync with this iPhone over Wi-Fi**,
   and apply the change.
3. Run AltServer as administrator.
4. From the AltServer tray icon, select **Install AltStore**, then choose the
   connected iPhone.
5. Complete the Apple Account authentication locally in AltServer.
6. On the iPhone, trust the development profile if iOS requests it.
7. On iOS 16 or later, enable **Settings > Privacy & Security > Developer
   Mode** and restart when requested.

## Install LifePilot

1. Keep AltServer running and keep the iPhone connected by USB or on the same
   Wi-Fi network.
2. Open AltStore on the iPhone.
3. Open **My Apps**, select the add button, and choose
   `LifePilot-unsigned.ipa` from Files.
4. Wait for LifePilot to appear under **My Apps**, then open it from the Home
   Screen.

With a free Apple Account, Apple limits the number of active sideloaded apps
and the development signature expires after seven days. Keep AltServer
available and use **Refresh All** in AltStore before it expires.

## Important limitations

- This is a development installation, not a public distribution channel.
- The IPA is unsigned when downloaded. Do not distribute it as a release.
- Only install IPA artifacts produced by this repository's trusted workflow.
- Some Apple capabilities may require paid-program entitlements even though the
  base app installs with a personal Apple Account.
