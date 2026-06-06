# Hydroponic Firebase Monitor

Flutter mobile app for managing hydroponic plant profiles, viewing live ESP32 sensor data, and publishing the currently active plant profile to Firebase Realtime Database.

## Authentication and per-user data

The app now uses Firebase Authentication email/password accounts. After sign-in, every user's data is scoped under their Firebase Auth UID in Realtime Database:

```text
users/{uid}/plantProfiles/{profileId}
users/{uid}/activeProfile
users/{uid}/systemStatus
```

This lets the same installed app retain plant profiles across devices for the same account while preventing another user from overwriting the active profile path used by your account.

## ESP32 user selection

For ESP32 firmware, configure the target user UID and point the device at the same per-user paths as the app:

- Read desired plant parameters from `users/{uid}/activeProfile`.
- Write live readings and warnings to `users/{uid}/systemStatus`.

The dashboard includes an ESP32 path button that shows the signed-in user's exact UID-based RTDB paths. In production, the ESP32 should authenticate with Firebase using a device-owned credential or another backend-issued credential that is authorized to access only the selected user's device path.

## Firebase rules

`database.rules.json` scopes reads and writes to `auth.uid == $uid`, so signed-in users can only access their own subtree. Deploy rules with the Firebase CLI from the project root after confirming the target Firebase project:

```bash
firebase deploy --only database
```

## Troubleshooting profile saves

If the create-profile screen keeps waiting or shows a Firebase error after you
tap **Save Profile**, check these items first:

1. Confirm the app is signed in with a Firebase Auth user.
2. Enable **Authentication > Sign-in method > Email/Password** in Firebase
   Console.
3. Deploy `database.rules.json` to the same Firebase project used by the app.
4. Confirm your local app has network access to the RTDB URL in
   `lib/services/firebase_service.dart`.

The app adds a timeout around profile save/load operations so failed Firebase
permissions or network problems now return an error message instead of looking
like the form is frozen.

## Development

Install Flutter dependencies before running the app:

```bash
flutter pub get
flutter run
```
