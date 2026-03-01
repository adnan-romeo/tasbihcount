# Tasbih Count (Flutter)

This app is wired for Firebase Authentication + Firestore and is ready for final project linking.

## What is already done

- Firebase packages added (`firebase_core`, `firebase_auth`, `cloud_firestore`)
- Firebase initialization added in `lib/main.dart`
- Auth service implemented in `lib/services/auth_service.dart`
- Counter cloud sync service implemented in `lib/services/counter_service.dart`
- Login/Create Account/Main Counter screens wired to Firebase services
- Platform folders created (`android`, `ios`, `web`, `windows`, `macos`, `linux`)

## Final connect step (required once)

You must link this app to your own Firebase project.

Security note: Firebase credential files are intentionally not committed (`android/app/google-services.json`, `ios/Runner/GoogleService-Info.plist`, `lib/firebase_options.dart`).

Run in PowerShell:

```powershell
powershell -ExecutionPolicy Bypass -File .\tool\setup_firebase.ps1 -ProjectId "YOUR_FIREBASE_PROJECT_ID"
```

This command will:

1. Ask you to log in to Firebase CLI.
2. Run `flutterfire configure`.
3. Generate real Firebase config (`lib/firebase_options.dart`) and platform files.

Template values are available in `lib/firebase_options.example.dart`.

## After connecting

```powershell
flutter clean
flutter pub get
flutter run
```

## Notes

- If PowerShell execution policy blocks commands, use `npm.cmd` / `firebase.cmd` directly.
- For Android release builds, set your real application id in `android/app/build.gradle.kts`.
