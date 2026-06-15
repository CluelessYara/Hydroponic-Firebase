# hydroponic_clean

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## Firebase authentication and per-user RTDB layout

This app now expects Firebase Authentication and a per-user Realtime Database tree so one tester cannot overwrite another tester's active plant profile.

### Firebase console changes

1. Open **Firebase console > Authentication > Sign-in method**.
2. Enable **Email/Password** sign-in.
3. Open **Realtime Database > Rules** and publish rules like this for authenticated app users:

```json
{
  "rules": {
    "users": {
      "$uid": {
        ".read": "auth != null && auth.uid == $uid",
        ".write": "auth != null && auth.uid == $uid",
        "plantProfiles": {
          "$profileId": {
            ".validate": "newData.hasChildren(['name', 'phMin', 'phMax', 'tempMin', 'tempMax', 'tdsMin', 'tdsMax', 'wateringCycleHours', 'isActive'])"
          }
        },
        "activeProfile": {
          ".validate": "newData.hasChildren(['id', 'name', 'phMin', 'phMax', 'tempMin', 'tempMax', 'tdsMin', 'tdsMax', 'wateringCycleHours', 'isActive', 'ownerUid'])"
        },
        "systemStatus": {
          ".validate": "newData.hasChildren(['ph', 'temperature', 'tds', 'waterLevel', 'isFlooding', 'timestamp', 'overallStatus'])"
        }
      }
    }
  }
}
```

4. Move or recreate data under each user's Firebase Auth UID. The app will create `plantProfiles` and `activeProfile` automatically, and the ESP32 should write sensor readings to the matching `systemStatus` node:

```json
{
  "users": {
    "FIREBASE_AUTH_UID_HERE": {
      "plantProfiles": {
        "PROFILE_PUSH_KEY": {
          "name": "Lettuce",
          "phMin": 5.5,
          "phMax": 6.5,
          "tempMin": 18,
          "tempMax": 24,
          "tdsMin": 560,
          "tdsMax": 840,
          "wateringCycleHours": 4,
          "isActive": true,
          "updatedAt": "2026-06-06T00:00:00.000Z"
        }
      },
      "activeProfile": {
        "id": "PROFILE_PUSH_KEY",
        "ownerUid": "FIREBASE_AUTH_UID_HERE",
        "name": "Lettuce",
        "phMin": 5.5,
        "phMax": 6.5,
        "tempMin": 18,
        "tempMax": 24,
        "tdsMin": 560,
        "tdsMax": 840,
        "wateringCycleHours": 4,
        "isActive": true,
        "updatedAt": "2026-06-06T00:00:00.000Z"
      },
      "systemStatus": {
        "ph": 6.0,
        "temperature": 22.0,
        "tds": 700,
        "waterLevel": 80,
        "isFlooding": false,
        "timestamp": "2026-06-06T00:00:00.000Z",
        "warnings": [],
        "overallStatus": "Normal"
      }
    }
  }
}
```

### ESP32 targeting

Use the Firebase Auth UID for the account/device pair you want the ESP32 to serve. In firmware, read the target profile from:

```text
/users/<FIREBASE_AUTH_UID>/activeProfile
```

and write live readings to:

```text
/users/<FIREBASE_AUTH_UID>/systemStatus
```

The example rules require the ESP32 writes to be authenticated as the same Firebase Auth UID when it updates `systemStatus`. For quick testing with one ESP32, sign the firmware in with the same email/password account or temporarily loosen only the `systemStatus` write rule while you migrate firmware. For a production multi-device system, add a `devices/<deviceId>/ownerUid` assignment flow and use custom tokens or another server-side pairing step. For the current single-ESP32 test setup, hard-coding the selected test user's UID in firmware is the simplest routing option.
