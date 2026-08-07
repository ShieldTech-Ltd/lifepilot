# LifePilot Brand Assets

This directory contains the public LifePilot identity used by the repository, product demo, and App Store preparation.

## Files

| File | Description |
|---|---|
| `lifepilot-app-icon.png` | Current 1024px product mark and source for repository previews. |
| `lifepilot-study-backdrop.jpg` | Previous user-provided illustrated study-wall backdrop retained for reference. |
| `lifepilot-monochrome-backdrop.jpg` | User-provided monochrome painting, restored to 3072 × 5504 for the native app. |
| `logo.svg` | Legacy vector lockup retained for historical documentation only. |

## Usage

- **README / GitHub:** references `Assets/brand/lifepilot-app-icon.png`.
- **App icon:** `App/LifePilotApp/Assets.xcassets/AppIcon.appiconset/AppIcon-1024.png` uses the same artwork without alpha.
- **In-app identity:** `LifePilotLogo.imageset` contains the optimised display asset used by launch, onboarding, and About.

## Export notes

The App Store icon must remain 1024 by 1024 pixels and must not contain an alpha channel. The in-app version may be smaller because it is rendered inside SwiftUI at display size.

```sh
# verify the current App Store source
sips -g pixelWidth -g pixelHeight -g hasAlpha \
  App/LifePilotApp/Assets.xcassets/AppIcon.appiconset/AppIcon-1024.png
```

When the mark changes, update the app icon, in-app image set, and this repository preview together.
