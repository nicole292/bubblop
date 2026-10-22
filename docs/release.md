# Release guide

Steps marked **(you)** need your accounts, passwords or a decision. Everything else is
already set up in the project.

## 0. Before the first upload: final name and app ID (you)
- Pick the final name. It must be available in both stores and should not clash with an
  existing trademark: search the Play Store, the App Store and the USPTO trademark search.
- The **application ID can never change after the first Google Play upload.** Then set it in:
  - `app/android/app/build.gradle.kts`: `applicationId` and `namespace`
  - `app/ios/Runner.xcodeproj` bundle identifier (`PRODUCT_BUNDLE_IDENTIFIER`)
  - Display names: `android:label` in `AndroidManifest.xml`, `CFBundleDisplayName` in
    `ios/Runner/Info.plist`, the window title in `windows/runner/main.cpp`
  - The in-game logo text in `lib/ui/home_screen.dart`

## 1. Android upload key (you, once)
Run in the VS Code terminal. Pick your own password and **store it in a password manager**.
```powershell
& "C:\Program Files\Android\Android Studio\jbr\bin\keytool.exe" -genkey -v `
  -keystore "$env:USERPROFILE\pop-upload-key.jks" -keyalg RSA -keysize 2048 `
  -validity 10000 -alias upload
```
Then create `app/android/key.properties` (Git ignores it, so it is never committed):
```
storeFile=C:\\Users\\User\\pop-upload-key.jks
storePassword=YOUR_PASSWORD
keyAlias=upload
keyPassword=YOUR_PASSWORD
```
Back up the `.jks` file somewhere safe (not in this repo). With Play App Signing (the
default), a lost upload key can be reset through Google support, but it is slow.

## 2. Build for Google Play
```powershell
cd C:\dev\project_pop\app
flutter build appbundle --release
```
Output: `app/build/app/outputs/bundle/release/app-release.aab` (about 54 MB for all CPU
types; per-phone downloads measured at 18–22 MB).

## 3. Google Play Console (you)
1. Create a developer account ($25 one-time) at play.google.com/console.
2. Create the app, then fill in the store listing (draft in `docs/store/listing.md`).
3. **Data safety:** the app collects no data and shares no data (see
   `docs/store/privacy-policy.md`). Upload the policy to a public URL first.
4. Content rating questionnaire: no violence, no user content, no purchases yet.
5. Target audience: 13+ is simplest; under-13 audiences bring the Families policy.
6. Upload the `.aab` to **Internal testing** first, install it on real phones via the
   testing link, then use closed testing with friends. New personal developer accounts
   must run a closed test with testers for a period before production access.

## 4. iOS without a Mac: Codemagic (you)
1. Put the repo on GitHub (private is fine).
2. Sign up at codemagic.io and connect the repo. `codemagic.yaml` (repo root) has an
   **iOS build check** that runs all tests and compiles iOS without signing. That proves
   the iOS build works.
3. To ship: join the Apple Developer Program ($99/year), create the app in App Store
   Connect, and add an App Store Connect API key to Codemagic as an integration named
   **Bubblop ASC key**. In Codemagic's code signing settings, generate (or upload) an
   Apple Distribution certificate and fetch the App Store profile for `com.bubblop.game`.
   Then run the **iOS release (TestFlight)** workflow in `codemagic.yaml`: it signs the
   build and uploads it to TestFlight, where you install it on an iPhone.
4. A Mac becomes necessary only if an iOS-specific bug needs hands-on debugging.

## 4b. Play on your own iPhone for free (no Apple Developer Program)
Uses a free Apple ID. The app stops opening after **7 days**; reinstall it the same way.
1. In Codemagic, run **iOS build check** and download `Bubblop-unsigned.ipa` from the
   build's artifacts.
2. On the PC, install **iTunes from apple.com** (not the Microsoft Store version) and
   **Sideloadly** (sideloadly.io).
3. Plug the iPhone in by USB, unlock it and tap **Trust**.
4. Open Sideloadly, drag in the `.ipa`, enter your Apple ID, press **Start**.
   If it complains about the bundle ID, tick the option to change it under Advanced Options.
5. On the iPhone:
   - Settings → Privacy & Security → **Developer Mode** → on (the phone restarts).
   - Settings → General → VPN & Device Management → your Apple ID → **Trust**.
6. Open Bubblop. A free Apple ID allows 3 sideloaded apps at a time.

## 5. Before each release (checklist)
- [ ] `dart test` in `packages/pop_core` and `flutter test` in `app` pass
- [ ] `flutter analyze` clean
- [ ] Play a full round on a real Android phone: sound, vibration, pause, background/resume
- [ ] Bump `version:` in `app/pubspec.yaml` (e.g. `1.0.1+2`; the number after `+` must increase)
- [ ] Update `docs/known-bugs.md`
