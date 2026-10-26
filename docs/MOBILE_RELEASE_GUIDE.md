# Bubblop: mobile release guide (Android + iPhone)

Written for a first release. Work through it with the checklist in
[RELEASE_CHECKLIST.md](RELEASE_CHECKLIST.md) beside you. All paths are relative to
`C:\dev\project_pop`. Commands are for the VS Code terminal (PowerShell).

> **Nothing here publishes anything by itself.** Building a file does not upload it, and
> uploading does not release it. Each store has a final button you press yourself.

---

## 1. What is already done

| Area | Status |
|---|---|
| Game | Finished and tested (see section 6). Version **1.0.0**, build number **1**. |
| App identity | Name **Bubblop**, app ID **com.bubblop.game** (Android and iOS), app icon, launch screen. |
| Android | Signed release bundle built: `app\build\app\outputs\bundle\release\app-release.aab`. Targets Android 16 (API 36), minimum Android 7 (API 24); 64-bit; native code 16 KB-page compatible; **no permissions** players see. |
| Android signing | Upload key created at `C:\Users\User\pop-upload-key.jks`; password in `app\android\key.properties` (not in Git). **You must back these up**, section 7. |
| iPhone | Project set up for iPhone only, portrait only, iOS 15+. Cloud build workflow ready in `codemagic.yaml` (no Mac needed). Not built yet: that needs your Apple account. |
| Store texts | `docs\store\listing.md`: titles, descriptions, keywords, categories and every questionnaire answer. |
| Store images | `docs\store\assets\`: 5 iPhone screenshots (1320×2868), 5 Android screenshots (1080×1920), Play feature graphic (1024×500), Play icon (512×512). Made from the real game. |
| Web pages | Support page `docs\index.html` and privacy policy `docs\privacy.html`, ready for free hosting on GitHub Pages (one switch, part A below). |

## 2. What was changed for release, and why

| Change | Why |
|---|---|
| Version 0.1.0 → **1.0.0+1** (`app\pubspec.yaml`) | First public version. |
| iOS: iPhone only, portrait only, full screen (`app\ios\Runner.xcodeproj\project.pbxproj`, `app\ios\Runner\Info.plist`) | The game is portrait-only. iPad support would need iPad screenshots and all four orientations. iPads can still run the iPhone version. |
| iOS: `ITSAppUsesNonExemptEncryption = NO` (`Info.plist`) | The game uses no encryption, so App Store Connect stops asking the export-compliance question on every upload. |
| `codemagic.yaml`: new **iOS release (TestFlight)** workflow | Builds, signs and uploads the iPhone version from the cloud, so you don't need a Mac. |
| Android upload key and `key.properties` | Google Play only accepts signed bundles. |
| Privacy policy update (`docs\store\privacy-policy.md`, `docs\privacy.html`) | Lists the saved settings (sound, music, vibration), mentions phone backups, and states that there is no third-party ad, analytics or tracking code (verified: the only libraries are the game engine, sound and on-device storage). The music is three Pixabay tracks, used under the Pixabay Content License. |
| Store screenshots tool (`tools\make_store_assets.py`) and a 3× option for the screenshot driver | So the store images can be remade after updates. |
| Game fixes earlier today | Taps that sometimes did nothing, a tutorial that could stall, Android Back button; see `docs\known-bugs.md`. Later: new layout, background music (Pixabay), softer sounds. |

## 3. Build commands

Run in `C:\dev\project_pop\app`:

```powershell
# Checks (run before every release)
flutter analyze
flutter test
cd ..\packages\pop_core; dart test; cd ..\..\app

# Android: the file you upload to Google Play
flutter build appbundle --release
# → app\build\app\outputs\bundle\release\app-release.aab

# Android: an installable test file for your own phone (optional)
flutter build apk --release
# → app\build\app\outputs\flutter-apk\app-release.apk
```

**iPhone:** can't be built on Windows. Run the **iOS release (TestFlight)** workflow on
codemagic.io (part C). The finished `.ipa` goes straight to TestFlight and can also be
downloaded from the build page.

## 4. Where the release files are

| File | Path |
|---|---|
| Android bundle for Google Play | `app\build\app\outputs\bundle\release\app-release.aab` (71 MB including the music; a single-phone install is about 40 MB) |
| Android test APK | `app\build\app\outputs\flutter-apk\app-release.apk` |
| Android upload key | `C:\Users\User\pop-upload-key.jks` |
| Key password | `app\android\key.properties` (`storePassword` line) |
| Store images | `docs\store\assets\` |
| Store texts | `docs\store\listing.md` |
| iPhone build | on codemagic.io, in the build's **Artifacts** |

The `build` folder is not in Git. If it's ever deleted, rerun the build command.

## 5. Tools you need

Already installed on this PC: Flutter, Android Studio (Android SDK, emulator), Git, Python.

| Tool | Cost | For |
|---|---|---|
| A password manager (Bitwarden is free, or your browser's) | Free | Storing the key password and account logins |
| **Google Play Console** account | **$25 once** | Publishing on Android |
| **Apple Developer Program** membership | **$99 per year** | Publishing on iPhone (also needed for TestFlight) |
| **Codemagic** personal account (codemagic.io) | Free: 500 Mac build minutes per month, reset on the 1st | Building the iPhone version without a Mac. One build takes ~10–20 minutes. Free minutes only apply to a **personal** account, not a Team. |
| TestFlight app on an iPhone | Free | Testing the iPhone version before release |

## 6. How to test

**Automated (I ran these on 2026-10-22, all passed):** `flutter analyze` (no issues),
`flutter test` (27 tests), `dart test` in `packages\pop_core` (50 tests).

**Android emulator (release build, 2026-10-22, passed):** the app opens, the first-time
tutorial plays, a missed drop shows the retry hint, a held press drops the ball and sets
off the chain, Back opens the pause menu, leaving and returning to the app keeps the
round paused, and after a full restart the tutorial isn't shown again (progress saved).
No crashes in the log.

**Still needs a real phone** (emulators can't check these properly):
1. Sound and vibration feel right. Nobody has listened to the sounds on a phone yet.
2. Smooth animation on an older, cheaper phone.
3. A full round to game over, then close and reopen the app: the best score is still there.
4. A phone call or notification during a round: the game pauses.

How: Android: in Play Console, **Test and release → Testing → Internal testing**,
upload the `.aab`, add yourself as a tester and install from the link. iPhone: install
**TestFlight** and open the build Codemagic uploaded.

## 7. Signing credentials: create once, protect forever

**Android upload key** (already created):
1. Open `app\android\key.properties` in VS Code. Copy the `storePassword` value into your
   password manager as "Bubblop Android upload key". (`keyPassword` is the same.)
2. Copy `C:\Users\User\pop-upload-key.jks` to **two** safe places that aren't this PC,
   for example a USB stick and your Google Drive.
3. Never commit either file to Git. Git already ignores `key.properties`, and the `.jks`
   lives outside the project.
4. Google Play keeps the real app-signing key itself (**Play App Signing**, the default).
   If you ever lose the upload key, Google support can reset it, but it takes days.

**Apple:** the certificate and profile are created during part C and stored in your
Codemagic account. The App Store Connect API key (`.p8` file) can only be downloaded
once, so keep it in your password manager as an attachment.

## 8. Register the accounts

**Who owns the accounts:** both stores require the account holder to be an adult (18+,
or the legal age where you live). If a parent creates them, **every legal field is the
parent's**: name, address, ID, phone, payment card, and accepting the agreements. They can
then invite you as a team member (Play Console **Users and permissions**, App Store
Connect **Users and Access**), and the games can be transferred to your own account later.

### Google Play Console
1. Go to **play.google.com/console** and sign in with the **account holder's own** Google
   account (the parent's, not elishakov.studio@gmail.com: that Gmail belongs to someone
   under 18, and Google can refuse developer sign-up and payments on it). Afterwards,
   invite elishakov.studio@gmail.com under **Users and permissions**.
2. Choose **Yourself** (personal account), pay **$25**.
3. **Developer name** (shown publicly under every game): `Elishakov Studio`. Developer
   email: `elishakov.studio@gmail.com`.
4. Verify the account holder's identity: legal name, address, and a photo of their ID.
   You may also be asked to verify a phone number and to sign in to the **Play Console
   app on a real Android phone**. Verification can take a few days.

### Apple Developer Program
1. Make sure the account holder's Apple ID has **two-factor authentication** on (iPhone
   **Settings → your name → Sign-In & Security**).
2. Install the **Apple Developer** app on the iPhone, open **Account → Enroll Now**, and
   choose **Individual**. Pay **$99**. Approval usually takes 1–2 days. On an individual
   account the account holder's **legal name** is shown as the seller on the App Store
   ("Elishakov Studio" would need a registered company).

## 9. Upload and fill in the listings

### Part A: put the support and privacy pages online (free, 2 minutes)
1. Open **github.com/nicole292/bubblop → Settings → Pages**.
2. Under **Build and deployment**: Source **Deploy from a branch**, Branch **main**, folder
   **/docs**, then **Save**.
3. After 1–2 minutes, check that **https://nicole292.github.io/bubblop/** and
   **https://nicole292.github.io/bubblop/privacy.html** open.
4. Support email: **elishakov.studio@gmail.com** (the studio inbox, used for every game).
   Check it regularly; store reviewers and players write there.

### Part B: Google Play
1. **Play Console → Create app**: name `Bubblop: Drop & Pop Puzzle`, default language
   English, **Game**, **Free**. Tick the declarations and press **Create app**.
2. **Dashboard → Set up your app**: complete every item using the answers in
   `docs\store\listing.md` ("Google Play → App content").
3. **Grow users → Store presence → Main store listing**: paste the texts, then upload the
   icon, feature graphic and 5 phone screenshots from `docs\store\assets\`.
4. **Test and release → Testing → Internal testing → Create new release**: upload
   `app-release.aab`. Accept **Play App Signing** if asked. Release name `1.0.0 (1)`. Add
   yourself under **Testers**, open the link on your phone and install. Play a round.
5. **Closed testing (required for new personal accounts):** Google requires **at least 12
   testers who stay opted in for 14 days in a row** before you can release publicly.
   Internal testing doesn't count.
   1. **Test and release → Testing → Closed testing → Create track** (or use **Alpha**).
   2. **Create new release**, choose the same bundle from the library, **Save**, then
      **Send for review**.
   3. **Testers**: create an email list with your testers' Gmail addresses (friends and
      family with Android phones). Share the opt-in link. Each tester taps **Become a
      tester**, then installs from Google Play.
   4. Ask them to keep it installed and play now and then for the full 14 days. Invite a
      few extra people in case someone drops out.
6. After 14 days, **Dashboard → Apply for production**, and answer the questions about
   your test honestly.
7. Once approved: **Test and release → Production → Create new release**, add the bundle,
   **Next → Save → Send for review**. Google's review usually takes a few days. After
   approval, the release goes live (or press **Publish** if managed publishing is on).

### Part C: App Store (iPhone, without a Mac)
1. **Register the app ID:** developer.apple.com → **Account → Certificates, IDs & Profiles
   → Identifiers → +** → **App IDs → App** → description `Bubblop`, **Explicit** bundle ID
   `com.bubblop.game` → **Continue → Register**.
2. **App Store Connect** (appstoreconnect.apple.com):
   1. **Business** (or **Agreements, Tax, and Banking**): accept the **Free Apps** agreement.
      No bank details are needed for a free app.
   2. **EU Digital Services Act / trader status**: if you aren't selling as a business,
      choose **not a trader**. Your app then can't be offered in the EU until you
      declare, so do this before release.
   3. **Apps → + → New App**: platform **iOS**, name `Bubblop: Drop & Pop Puzzle`,
      language English, bundle ID **com.bubblop.game**, SKU `bubblop`, **Full Access**.
3. **API key for Codemagic:** **Users and Access → Integrations → App Store Connect API →
   Team Keys → Generate API Key**, name `Codemagic`, access **App Manager**. Download the
   `.p8` file (only possible once), and note the **Issuer ID** and **Key ID**.
4. **Codemagic** (codemagic.io): sign up with GitHub (personal account), **Add application**,
   pick `nicole292/bubblop`, type **Flutter App**, and choose to configure with
   `codemagic.yaml`.
5. In your Codemagic **personal settings → Integrations → Developer Portal → Connect**,
   upload the `.p8` and enter the Issuer ID and Key ID. Name the key exactly
   **`Bubblop ASC key`**.
6. **Code signing identities** (in the same settings):
   1. **iOS certificates → Generate certificate**, type **Apple Distribution**. Download the
      certificate when offered and save it with its password in your password manager.
   2. On developer.apple.com: **Profiles → + → App Store Connect** (under Distribution) →
      App ID `com.bubblop.game` → select the new certificate → name `Bubblop App Store` →
      **Generate**.
   3. Back in Codemagic: **iOS provisioning profiles → Fetch profiles**, and select
      `Bubblop App Store`.
7. In the app's page on Codemagic, **Start new build → workflow "iOS release (TestFlight)"
   → branch main → Start**. In ~15 minutes the build appears in App Store Connect under
   **TestFlight** (Apple processes it for another 5–30 minutes).
8. **TestFlight:** add yourself under **Internal Testing**. Install **TestFlight** on your
   iPhone and play the game.
9. **App Store page** (App Store Connect → your app → **iOS App 1.0**):
   1. Screenshots: drag in `ios-6.9in-1.png` … `ios-6.9in-5.png` under **iPhone 6.9"
      Display**. If App Store Connect asks for a different size first, see section 14.
   2. Promotional text, description, keywords, support URL, marketing URL and copyright
      from `docs\store\listing.md`.
   3. **Build** → **+** → pick the TestFlight build.
   4. **App Review Information**: your name, phone and email. Sign-in **not required**.
      Notes: `Free offline puzzle game. No account, no ads, no purchases.`
   5. **Version Release**: choose **Manually release this version** for full control.
   6. Left menu **App Privacy**: privacy policy URL, then **Get Started → No, we do not
      collect data**. **Publish**.
   7. **App Information**: category **Games → Puzzle**, secondary **Games → Casual**,
      **Age Rating → Edit**, all **None/No**.
   8. **Pricing and Availability**: **Free**, all countries (EU only after the trader step).
10. Press **Add for Review → Submit to App Review**. Usually 1–3 days. If Apple rejects
    something, copy their message to me and I'll help fix it.
11. When approved, press **Release This Version**.

## 10. Costs

| | Amount | Mandatory? |
|---|---|---|
| Google Play developer account | $25 once | Yes, for Android |
| Apple Developer Program | $99 every year | Yes, for iPhone. If it lapses, the game disappears from the App Store. |
| Codemagic | $0 within 500 macOS minutes per month | No (free tier is enough). Extra minutes only if you turn on billing yourself. |
| GitHub Pages hosting | $0 | No |
| Domain name, paid testers, ads, D-U-N-S number | — | **Not needed** |

## 11. Information only you can provide

- Your legal name, address, phone number and ID document (both stores verify identity).
- Payment card for the $25 and $99 fees.
- The studio email `elishakov.studio@gmail.com` (done) and the developer name **Elishakov Studio**.
- 12+ people with Android phones for Google's 14-day closed test.
- Your name for the App Store copyright line and the App Review contact details.
- The EU trader status declaration (your own legal statement).

## 12. Remaining blockers, and how to clear each

1. **Upload key isn't backed up yet:** section 7, steps 1–2.
2. ~~Support email~~: done, `elishakov.studio@gmail.com`.
3. **Privacy and support pages are offline:** part A (one switch in GitHub settings).
4. **No developer accounts yet:** section 8.
5. **Google's 14-day closed test with 12 testers:** part B step 5. Start it as early as
   possible, because it's the longest wait.
6. **iPhone build not produced yet:** needs your Apple account and part C steps 1–7.
7. **Not tested on a real phone:** section 6 ("Still needs a real phone").
8. **Code is public on GitHub** (github.com/nicole292/bubblop): anyone can see and copy
   the game's code. Pages also needs the repo public on a free account. If you'd prefer
   it private: host the two web pages on Google Sites instead, then **Settings →
   General → Danger Zone → Change visibility → Private**. Codemagic works with private
   repos.

## 13. Publishing an update later

1. Make the change, then run the checks from section 3.
2. Raise the version in `app\pubspec.yaml`. For example `version: 1.0.1+2`: the part
   before `+` is what players see; the number after `+` **must go up with every upload**
   to either store (TestFlight too).
3. Android: `flutter build appbundle --release`, then **Production → Create new release**
   in Play Console, upload, add release notes, **Send for review**.
4. iPhone: push to GitHub, run the Codemagic workflow, then in App Store Connect **+ Version**
   (top left of the app page), enter `1.0.1`, pick the new build, add "What's New", submit.
5. If the update changes what data the game handles (for example ads), update the privacy
   policy and both stores' data forms **before** submitting.

## 14. Remaking the store images

1. Capture raw screenshots at 1320×2868 with the developer screenshot driver, for example:
   ```powershell
   cd C:\dev\project_pop\app
   flutter run -d windows --profile --dart-define=POP_PHONE=440x956+62+34 `
     --dart-define=POP_SHOT_SCALE=3 --dart-define=POP_SEED=11 `
     "--dart-define=POP_SHOT=wait 2.5; shot home; wait 2.5; tap 220 755; wait 1.5; shot round_start"
   ```
   Shots land in `app\build\shots\`. Copy the ones you want into `app\build\store_raw\`
   with the names listed in `tools\make_store_assets.py` (`chain_04`, `aim`, `chain_03`,
   `round_mid`, `home`). The chain shots come from `--dart-define=POP_DEMO=chain` and
   dropping into column 5. Ask me if you'd rather I do it.
2. `python tools\make_store_assets.py` rebuilds everything in `docs\store\assets\`.
3. For a different iPhone size (for example 6.3", 1206×2622), change the phone size to
   `402x874` and the `1320, 2868` numbers in the script.

## Appendix: play on your own iPhone for free (no Apple membership)

Uses a free Apple ID. The app stops opening after **7 days**, and you reinstall the same way.
1. In Codemagic, run **iOS build check** and download `Bubblop-unsigned.ipa` from the build.
2. On the PC, install **iTunes from apple.com** (not the Microsoft Store version) and
   **Sideloadly** (sideloadly.io).
3. Plug in the iPhone, unlock it, tap **Trust**.
4. In Sideloadly, drag in the `.ipa`, enter your Apple ID, press **Start**.
5. On the iPhone: **Settings → Privacy & Security → Developer Mode → On** (it restarts),
   then **Settings → General → VPN & Device Management → your Apple ID → Trust**.

## Money: should the game earn something?

It ships **free, with no ads and no purchases**, which is the simplest and fastest path
through review, and the privacy answers stay "no data". If you want income later, the
gentlest options for a casual puzzle game are:

1. **One optional rewarded ad** ("watch an ad to continue once after game over"). Players
   choose it, so it doesn't interrupt play. Trade-offs: adds Google AdMob (an SDK that
   collects device data), so you would need a consent pop-up in Europe, Apple's tracking
   prompt on iPhone, an updated privacy policy and data forms, and a 13+ audience stays
   simpler. Earnings are small until there are many players.
2. **A one-time "Supporter" purchase** (for example a colour theme). No data collection,
   no consent pop-ups. Apple and Google keep 15% (small-business rate), and payout needs
   tax and bank details in both stores.

Neither is in the game, and I won't add one unless you ask. Get real players first, then
decide.
