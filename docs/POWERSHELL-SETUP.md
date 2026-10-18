# MikeGyver EarthCam v1.0.0 — PowerShell Setup Runbook

One part: build the iPhone app + widget in GitHub Actions and deliver it
to your phone through TestFlight. There is **no backend** — the app and
the widget fetch NASA GIBS imagery directly, so nothing to deploy and no
settings to enter.

**What you're building**

```
iPhone (EarthCam, SwiftUI)            NASA GIBS (free, no key)
┌──────────────────────────┐         ┌───────────────────────────────┐
│ App: latest GOES-East    │ HTTPS   │ WMS GetMap, EPSG:4326         │
│ frame over Tomball,      │ ──────► │ GOES-East_ABI_GeoColor       │
│ refresh button,          │         │ 800×800 JPEG, ~100 KB        │
│ "Updated" timestamp      │         └───────────────────────────────┘
│                          │
│ Widget (small + medium): │         No server, no App Groups, no
│ same frame on the Home   │         shared container — the widget
│ Screen, hourly refresh   │         downloads the JPEG itself.
└──────────────────────────┘
```

**Before you start:** the `earthcam-ios-v1.0.0.zip` from Wiggs, extracted
somewhere handy (these steps assume
`E:\Downloads\earthcam-ios-v1.0.0\earthcam-ios`). Your paid Apple
Developer membership, and the App Store Connect API key + Team ID from
SatPass/Cosmic Jukebox — the same MikeGyver CI key works for every app.

---

## 1. One-time Apple setup

1. **Register the bundle IDs:**
   https://developer.apple.com/account → **Certificates, Identifiers &
   Profiles** → **Identifiers** → **+** → **App IDs** → **App**
   - App: Description `EarthCam`, Bundle ID **Explicit** →
     `studio.mikegyver.earthcam` → no capabilities → **Register**
   - Widget: Description `EarthCam Widget`, Bundle ID **Explicit** →
     `studio.mikegyver.earthcam.widget` → no capabilities → **Register**
2. **Create the App Store Connect record:** App Store Connect →
   **My Apps** → **+** → **New App** → platform **iOS**, name
   `MikeGyver EarthCam`, Bundle ID `studio.mikegyver.earthcam`, SKU
   `earthcam-ios-001`. (If the name is taken, pick a close variant and
   tell Wiggs — he'll update the display name to match.)

## 2. Create the GitHub repo and push the code

On https://github.com/new (or under your `MikeGyver-SME` org): repository
name **`mikegyver-earthcam-ios`**, visibility **Private**, do **not** add a
README (the zip already has one).

Then in PowerShell:

```powershell
cd "E:\Downloads\earthcam-ios-v1.0.0\earthcam-ios"
git init -b main
git add -A
git commit -m "EarthCam iOS v1.0.0"
git remote add origin https://github.com/MikeGyver-SME/mikegyver-earthcam-ios.git
git branch -M main
git push -u origin main
```

> Shortcut: `scripts\push-earthcam-ios.ps1` in this folder does the
> commit/push/tag cycle for you on later versions — see the script's
> header comments.

## 3. Add the four secrets to the repo

Same four secrets as SatPass (same values — the API key is per-team, not
per-app). Repo page → **Settings** → **Secrets and variables** →
**Actions** → **New repository secret** (four times), or with the GitHub
CLI:

```powershell
$Repo = "MikeGyver-SME/mikegyver-earthcam-ios"

gh secret set ASC_KEY_ID    --body "BBJ549FJ72"   --repo $Repo
gh secret set ASC_ISSUER_ID --body "4221565d-4057-4c96-b54a-2f389cada063" --repo $Repo
gh secret set TEAM_ID       --body "WXMPJQBST7"   --repo $Repo

$P8 = Get-Content -Raw "E:\Downloads\AuthKey_BBJ549FJ72.p8"
gh secret set ASC_KEY_P8 --body $P8 --repo $Repo
```

(Don't have `gh`? `winget install GitHub.cli`, then `gh auth login`.
Never paste the `.p8` into chat — the commands above read it from disk.)

## 4. Trigger the build

The workflow runs on version tags. Push one:

```powershell
cd "E:\Downloads\earthcam-ios-v1.0.0\earthcam-ios"
git tag v1.0.0
git push origin v1.0.0
```

Watch it: repo → **Actions** → **Build and upload EarthCam to
TestFlight**. Roughly 10–15 minutes: fastlane `cert` + `sigh` (both
bundle IDs) → XcodeGen → archive with manual signing → export IPA →
`fastlane pilot upload`. A copy of the IPA is also kept as a workflow
artifact for 14 days.

## 5. Install on your iPhone via TestFlight

1. App Store Connect → **My Apps** → **MikeGyver EarthCam** →
   **TestFlight** → the new build appears under **iOS Builds**
   (processing takes a few minutes)
2. **Internal Testing** → add yourself as a tester
3. On your iPhone: install **TestFlight**, open the invite, install
   **MikeGyver EarthCam**

## 6. First launch + widget

1. Open EarthCam — the latest frame loads on appear. No setup, no
   settings. Tap the refresh arrow for a fresh frame anytime.
2. Add the widget: long-press the Home Screen → **Edit** → **+** →
   search **EarthCam** → pick **small** or **medium** → **Add Widget**.
3. Tapping the widget deep-links into the app (`earthcam://latest`).

## 7. Shipping v1.0.1 and beyond

1. Bump versions in `ios/project.yml`: `MARKETING_VERSION` (what users
   see) and `CURRENT_PROJECT_VERSION` (must increase every TestFlight
   upload)
2. Commit, push, tag the new version:
   ```powershell
   git add -A; git commit -m "EarthCam iOS v1.0.1"
   git push
   git tag v1.0.1; git push origin v1.0.1
   ```
3. TestFlight testers get the update automatically

---

## Troubleshooting

| Symptom | Fix |
|---|---|
| App shows "Couldn't load the latest frame" | Check connectivity; GIBS occasionally 503s — tap refresh. The widget retries on its own every 15 min |
| Widget says "Updating…" for a long time | iOS defers widget timelines to save battery; open the app once to confirm GIBS is reachable |
| Workflow fails at `sigh`: bundle ID not found | Do step 1: both bundle IDs must be registered before the first build |
| `pilot upload`: app not found | Do step 1(2): the App Store Connect app record must exist before the first upload |
| Frame is dark | GOES-East GeoColor is a daytime product — that's the night side of Earth, not a bug |
| Frame looks stale | GIBS frames lag real time ~10–30 min; the widget refreshes hourly and iOS may defer that further |
