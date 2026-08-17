# MyPetFit

A Flutter application for assessing a pet's health and tracking it over time.

## Overview

MyPetFit guides an owner through a structured health questionnaire about their
pet, scores the answers, and presents the result as a report card that can be
saved, revisited and shared with a veterinarian. Reports accumulate per pet, so
repeat assessments build a history that shows whether an animal's health is
improving or declining.

The app supports multiple pets per account. All data is scoped to the
authenticated user and synchronised to Firebase, so a signed-in owner sees the
same records on any device.

## Features

**Assessment and scoring**
- A 45-question health questionnaire across 9 categories. Categories 1–8 are
  scored; category 9 is informational only.
- Per-option scoring with an overall fitness percentage and a per-category
  breakdown.
- Progress is saved per pet, so a part-finished assessment can be resumed and
  switching pets does not carry answers across.

**Reports**
- A report card for each completed assessment, with the score, category
  breakdown and comparison against the pet's previous result.
- Report history per pet, retained on-device and in Firestore.
- Export to PDF, plus system share and print.

**Analytics**
- Trend graph across a pet's assessment history.
- Category evolution, health milestones and derived insights.
- Progressive disclosure so the detail is available without crowding the page.

**Pets and owner**
- Multiple pet profiles with breed, age, sex, weight, height and microchip
  number.
- Owner profile with contact and veterinarian details.
- Profile photos for the owner and each pet, stored in Firebase Storage.
- Saved delivery addresses with a default address.

**Accounts**
- Email/password sign-up and sign-in.
- Google Sign-In.
- Sign in with Apple.
- Account deletion, which removes the account's stored documents and files.

**Shop**
- A product catalogue served from Firestore, with product detail and a cart.
- Ordering is intentionally disabled in this build — see
  [Shop availability](#shop-availability).

**Platform**
- Light and dark appearance, following the system setting or an explicit choice.
- Dynamic Type support up to a 1.3 scale factor.
- Crash reporting via Firebase Crashlytics.

## Technology stack

- **Flutter** / **Dart** — `sdk: ^3.11.3`
- **Firebase Core**, **Authentication**, **Cloud Firestore**, **Storage**,
  **Crashlytics**
- **provider** — state management
- **go_router** — routing, including a stateful shell for the bottom navigation
- **shared_preferences** — local cache
- **pdf**, **printing**, **share_plus** — report export
- **image_picker**, **path_provider** — profile photos
- **google_sign_in**, **sign_in_with_apple**, **crypto** — federated sign-in
- **flutter_svg**, **lottie**, **video_player** — assets and motion

## Project structure

```
lib/
  analytics/      report analytics — domain, adapters, presentation, widgets
  config/         routes, theme tokens, asset paths, composition root
  data/           the questionnaire and static catalogue data
  models/         typed models (pet, owner, address, product, score result)
  providers/      ChangeNotifier state, including cloud sync
  screens/        one directory per flow (auth, quiz, report, shop, account…)
  services/       Firebase access, photo upload/storage, PDF, crash reporting
  widgets/        shared UI components
assets/           artwork, fonts and PDF resources
android/          Android host project
ios/              iOS host project
test/             unit and widget tests
integration_test/ end-to-end tests
firestore.rules   Firestore security rules
storage.rules     Firebase Storage security rules
```

## Requirements

- Flutter SDK with Dart `^3.11.3` (developed against Flutter 3.41.5, stable)
- **Android** — SDK levels follow the Flutter toolchain defaults for the
  installed SDK; Java 17
- **iOS** — deployment target 15.0, Xcode with CocoaPods

## Getting started

```bash
git clone <repository-url>
cd MyPetFit_App
flutter pub get
flutter run
```

Android additionally needs `android/local.properties` pointing at your Flutter
and Android SDK installations. Flutter generates this on first build; it is not
committed because it contains machine-specific paths.

## Firebase configuration

The app is wired to the Firebase project `mypetfit-c530e`:

| Platform | Identifier |
| --- | --- |
| Android | `com.mypetfit.in` |
| iOS | `com.mypetfit.app` |

The client configuration files (`android/app/google-services.json` and
`ios/GoogleService-Info.plist`) are committed, as is normal for Firebase mobile
apps — they contain public client identifiers, not secrets. Access is enforced
by the security rules in `firestore.rules` and `storage.rules`, which scope
every document and file to the authenticated user's UID.

No service-account credentials or private keys are stored in this repository.

Firebase services in use: Authentication, Cloud Firestore, Storage and
Crashlytics.

## Android

Debug builds require no additional setup beyond `local.properties`.

Release builds are signed with an upload keystore configured through
`android/key.properties`. Neither that file nor the keystore is committed — see
[Release and signing](#release-and-signing). Without them the release build
falls back to debug signing, so a local `flutter build apk --release` still
works for testing.

## iOS

Open `ios/Runner.xcworkspace` in Xcode (not the `.xcodeproj`). CocoaPods
dependencies install automatically on the first Flutter build, or manually:

```bash
cd ios && pod install
```

Release builds require a valid Apple Developer team and provisioning profile
configured in Xcode. Sign in with Apple is enabled via the entitlement in
`ios/Runner/Runner.entitlements`.

## Development commands

```bash
flutter pub get       # fetch dependencies
flutter analyze       # static analysis
flutter test          # unit and widget tests
flutter run           # run on a connected device or simulator
```

Launcher icons are generated from the artwork in `assets/v3/`:

```bash
dart run flutter_launcher_icons
```

## Release and signing

Production signing credentials are deliberately excluded from version control:

- `android/key.properties`
- `android/upload-keystore.jks`
- iOS certificates and provisioning profiles

These are maintained separately by whoever holds release authority. The Android
upload keystore in particular is what Google Play uses to authenticate every
future update — losing it means the app can no longer be updated under the same
listing.

Release builds:

```bash
flutter build appbundle --release   # Android — Play Store
flutter build ipa --release         # iOS — App Store
```

## Shop availability

The shop's catalogue, product detail and cart are enabled. Checkout and order
placement are **disabled** by a flag in `lib/config/routes.dart`:

```dart
static const bool shopBrowsable = true;   // catalogue, product detail, cart
static const bool shopEnabled  = false;   // checkout, orders, tracking
```

Ordering is closed because no order is persisted and no payment is taken — the
success screen's reference number is generated on the device. Enabling
`shopEnabled` before order persistence and a payment provider exist would tell a
customer their order was placed when nothing recorded it.

## Important notes

- **Notifications are not implemented.** There is no FCM integration, no local
  notification scheduling and no notification permission request. The
  "Reminders & notifications" screen currently stores its toggles in local
  screen state only.
- **Assessment retention** is capped per pet, so older reports are trimmed as
  new ones are recorded.
- **The delivery address** is stored against the account in Firestore, with the
  device copy acting only as an offline cache.
- **Profile photos** are uploaded to Firebase Storage and referenced by download
  URL. Records created before this behaviour may still hold a local file path;
  the renderer handles both.
