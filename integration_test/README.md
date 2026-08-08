# Integration tests

These run the app on a real device or emulator, where `flutter test` cannot:
real rendering, real gestures, real platform channels, real text scaling.

## Safety: these do not touch production Firebase

**Every suite here builds the app's widget tree with fakes.** None of them
calls `main()` from `lib/main.dart`, because that initialises the production
Firebase project — and an integration test that signs in, writes assessments
and deletes accounts against production would be operating on real people's
health records.

That is a deliberate limitation, not an oversight. It means these suites
prove the app's *own* behaviour on a device, and prove nothing about
Firestore, Firebase Auth, Google or Apple. Those need a Firebase Emulator
Suite configuration or a dedicated test project, neither of which exists in
this repository yet — see "Blocked" below.

## Running them

No device is required to *write* these; one is required to run them.

```
flutter devices                      # confirm something is attached
flutter test integration_test        # runs every suite on the attached device
```

A simulator or emulator will run them. A simulator result is **not**
equivalent to physical-device verification for anything native: Sign in with
Apple, Google Sign-In, camera and photo permissions, printing and the share
sheet, and whether a Crashlytics report actually arrives.

## What is covered here

| Suite | Proves |
|---|---|
| `critical_journeys_test.dart` | assessment → report → history → pet switching, on a device, with no cross-pet contamination |
| `startup_and_accessibility_test.dart` | the Firebase-unavailable screen and that its retry re-runs initialisation; and that the controls a screen reader must be able to operate are operable on a real platform |

## Blocked — needs work outside this repository

| Flow | Blocked on |
|---|---|
| Sign up / sign in / sign out end to end | Firebase Emulator Suite or a dedicated test project |
| Account deletion end to end | the same, plus a disposable test account — never a real one |
| Google Sign-In | real Google credentials + a device |
| Sign in with Apple | Apple Developer capability, Firebase Apple provider, and a physical iOS device |
| Crashlytics delivery | Firebase console + a physical device; a report reaching the dashboard cannot be asserted from a test |
| Camera / photo picker | native permission prompts, physical device |
| Print / share sheet | native sheets, physical device |
| Offline restore against real Firestore | emulator project with controllable connectivity |

## Adding an emulator project later

When a Firebase Emulator Suite configuration is added, the auth and Firestore
journeys above become runnable: point the app at the emulator hosts before
`runApp`, seed a disposable account, and drive the real `main()`. Until then,
do not repoint any suite here at the production project.
