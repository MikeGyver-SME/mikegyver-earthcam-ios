# MikeGyver EarthCam v1.0.0

A native iOS app + Home Screen widget showing the latest NASA GIBS
GOES-East satellite frame over Tomball, TX — the personal version of
the hourly EarthCam pipeline.

## How it works

```
iPhone (EarthCam, SwiftUI)            NASA GIBS (no backend, no key)
┌──────────────────────────┐         ┌───────────────────────────────┐
│ App: full-screen latest  │ HTTPS   │ WMS 1.3.0 GetMap, EPSG:4326   │
│ frame, refresh button,   │ ──────► │ GOES-East_ABI_GeoColor       │
│ "Updated" timestamp      │         │ 800×800 JPEG, ~100 KB        │
│                          │         └───────────────────────────────┘
│ Widget (small + medium): │
│ same frame on the Home   │         The widget fetches DIRECTLY
│ Screen, refreshed hourly │         from GIBS — no server, no App
│ by WidgetKit timeline    │         Groups, no shared container.
└──────────────────────────┘
```

There is no server to run and nothing to configure: the app and the
widget both call `EarthCamFeed.frameURL()` (a WMS GetMap request over
Tomball, 30.0702827, -95.7047924, 8° span) and download the JPEG with
`URLSession`. The widget timeline refreshes hourly on success and
retries every 15 minutes on failure.

## Layout

```
earthcam-ios/
├── ios/                     SwiftUI iPhone app + WidgetKit extension (XcodeGen)
│   ├── project.yml          MARKETING_VERSION / CURRENT_PROJECT_VERSION live here
│   ├── Shared/
│   │   ├── Brand.swift      MikeGyver Studio navy/gold palette
│   │   └── EarthCamFeed.swift  GIBS WMS URL builder + frame fetcher (Foundation only)
│   ├── EarthCam/
│   │   ├── EarthCamApp.swift
│   │   ├── ContentView.swift   Latest frame, refresh, "Updated" caption
│   │   ├── Info.plist          Display name "MikeGyver EarthCam", earthcam:// scheme
│   │   └── Assets.xcassets/    App icon set (PNGs supplied at package time)
│   └── EarthCamWidget/
│       ├── EarthCamWidget.swift      Widget definition (small + medium)
│       ├── WidgetProvider.swift      TimelineProvider: hourly refresh, 15-min retry
│       ├── EarthCamWidgetView.swift  Small (full-bleed + map pin) / medium views
│       └── Info.plist
├── .github/workflows/
│   └── testflight.yml       macos-26: sigh (both bundle IDs) → XcodeGen → archive → IPA → pilot
├── docs/
│   └── POWERSHELL-SETUP.md  Detailed PowerShell runbook (start here)
└── scripts/
    └── push-earthcam-ios.ps1  Commit/push/tag helper for Windows
```

## Quickstart

Follow **`docs/POWERSHELL-SETUP.md`** — it covers every command:

1. **Apple setup:** bundle IDs `studio.mikegyver.earthcam` and
   `studio.mikegyver.earthcam.widget` (no capabilities), App Store
   Connect record "MikeGyver EarthCam"
2. **GitHub:** repo `mikegyver-earthcam-ios` → 4 secrets (reuse the
   MikeGyver CI key) → `git tag v1.0.0` → TestFlight
3. **First launch:** the frame loads on appear — no setup needed
4. **Widget:** long-press Home Screen → **+** → **EarthCam** → small or
   medium. Tap it to open the app (`earthcam://latest`).

## Data sources

| Data | Source |
|---|---|
| Satellite imagery | NASA GIBS WMS (`gibs.earthdata.nasa.gov`), GOES-East ABI GeoColor layer, EPSG:4326 best |
| Coordinates | Tomball, TX: 30.0702827, -95.7047924 (hardcoded) |

## Honest limitations

- GOES-East GeoColor is a daytime true-color product — the frame is
  dark at night (that's the Earth, not a bug).
- GIBS frames lag real time by roughly 10–30 minutes; the widget's
  "Updated" timestamp is the fetch time, not the image capture time.
- The widget timeline is hourly — iOS may defer refreshes to save
  battery, so the Home Screen frame can lag the app's by an hour.
- The 8° span is a regional view, not street-level: Tomball sits at the
  center pin, but you won't see individual streets.

## Versioning

- `ios/project.yml`: `MARKETING_VERSION` (user-visible) and
  `CURRENT_PROJECT_VERSION` (must increase for every TestFlight upload).
- Tag `v*` (e.g. `git tag v1.0.1; git push origin v1.0.1`) to build + upload.
