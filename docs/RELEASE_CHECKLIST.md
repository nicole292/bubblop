# Bubblop release checklist

Tick items as you go (in VS Code: change `[ ]` to `[x]`). Details for each step are in
[MOBILE_RELEASE_GUIDE.md](MOBILE_RELEASE_GUIDE.md); section numbers are in brackets.

## Done for you (2026-10-22)
- [x] Game finished; version 1.0.0 (build 1)
- [x] Automated checks pass: analyze, 27 app tests, 50 rules tests
- [x] Android release build tested on the emulator (launch, tutorial, chain, back, resume, saved progress)
- [x] Android upload key created; signed `app-release.aab` built and verified
- [x] Android: API 36 target, 64-bit, 16 KB pages, no user permissions
- [x] iOS project: iPhone only, portrait, iOS 15+, encryption declaration, Codemagic release workflow
- [x] Store texts and questionnaire answers (`docs/store/listing.md`)
- [x] Store images (`docs/store/assets/`)
- [x] Support and privacy web pages (`docs/index.html`, `docs/privacy.html`)

## Before anything else
- [ ] Copy the key password from `app/android/key.properties` into a password manager [7]
- [ ] Back up `C:\Users\User\pop-upload-key.jks` to two places off this PC [7]
- [ ] Create or confirm the support inbox bubblop.game@gmail.com [9A]
- [ ] Switch on GitHub Pages (Settings → Pages → main, /docs) [9A]
- [ ] Check both pages open: nicole292.github.io/bubblop/ and …/privacy.html [9A]
- [ ] Decide: keep the GitHub repo public, or move the pages and make it private [12]

## Google Play
- [ ] Create Play Console account, pay $25 [8]
- [ ] Identity (and phone) verification approved [8]
- [ ] Create app "Bubblop: Drop & Pop Puzzle", Game, Free [9B.1]
- [ ] App content: privacy policy, ads, app access, content rating, target audience, data safety, advertising ID, other declarations [9B.2]
- [ ] Main store listing: texts, icon, feature graphic, 5 screenshots [9B.3]
- [ ] Internal testing: upload `app-release.aab`, accept Play App Signing, install on your phone [9B.4]
- [ ] Real-phone checks: sound, vibration, smoothness, best score after reopening, pause on a call [6]
- [ ] Closed testing release sent for review [9B.5]
- [ ] 12+ testers opted in (list names here): …
- [ ] Day 1 of 14: ____ · Day 14: ____
- [ ] Apply for production access [9B.6]
- [ ] Production release sent for review [9B.7]
- [ ] **Live on Google Play** 🎉

## App Store
- [ ] Two-factor authentication on your Apple ID [8]
- [ ] Apple Developer Program, Individual, $99, approved [8]
- [ ] Register App ID com.bubblop.game [9C.1]
- [ ] Accept the Free Apps agreement [9C.2]
- [ ] EU trader status declared [9C.2]
- [ ] Create the app in App Store Connect [9C.2]
- [ ] App Store Connect API key created; `.p8`, Issuer ID, Key ID saved [9C.3]
- [ ] Codemagic personal account; repo added [9C.4]
- [ ] Integration "Bubblop ASC key" added [9C.5]
- [ ] Distribution certificate generated and saved; App Store profile created and fetched [9C.6]
- [ ] "iOS release (TestFlight)" build succeeded [9C.7]
- [ ] Played the TestFlight build on an iPhone [9C.8]
- [ ] Screenshots, texts, URLs, build selected [9C.9]
- [ ] App Privacy published ("Data Not Collected") [9C.9]
- [ ] Category, age rating, price and availability [9C.9]
- [ ] Submitted for review [9C.10]
- [ ] Approved, then **Release This Version** [9C.11]
- [ ] **Live on the App Store** 🎉

## Every later update
- [ ] Checks pass (`flutter analyze`, `flutter test`, `dart test`) [3]
- [ ] Version raised in `app/pubspec.yaml` (number after + goes up) [13]
- [ ] Privacy policy and data forms still true [13]
- [ ] New Android bundle uploaded; new iPhone build via Codemagic [13]
