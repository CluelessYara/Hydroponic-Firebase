import 'package:firebase_database/firebase_database.dart';
import '../models/plant_profile.dart';

class FirebaseService {
  final FirebaseDatabase _database = FirebaseDatabase.instanceFor(
    app: FirebaseDatabase.instance.app,
    databaseURL:
        'https://hydroponic-system-61a0f-default-rtdb.asia-southeast1.firebasedatabase.app',
  );

  // Edited to scope all user-owned RTDB data by Firebase Auth uid so users cannot overwrite each other.
  DatabaseReference userRootRef(String uid) => _database.ref('users/$uid');
  DatabaseReference plantProfilesRef(String uid) => userRootRef(uid).child('plantProfiles');
  DatabaseReference activeProfileRef(String uid) => userRootRef(uid).child('activeProfile');
  DatabaseReference systemStatusRef(String uid) => userRootRef(uid).child('systemStatus');

  // Edited to save each profile under the signed-in user's private profile collection.
  Future<String> savePlantProfile(String uid, PlantProfile plant) async {
    final ref = plant.id == null
        ? plantProfilesRef(uid).push()
        : plantProfilesRef(uid).child(plant.id!);
    await ref.set(plant.toRealtimeDatabaseMap());
    return ref.key!;
  }

  // Edited to load profiles from Firebase so the same account keeps profiles on every installed device.
  Future<List<PlantProfile>> getPlantProfiles(String uid) async {
    final event = await plantProfilesRef(uid).once();
    final value = event.snapshot.value;

    if (value == null) return [];
    if (value is! Map) return [];

    final plants = value.entries
        .where((entry) => entry.value is Map)
        .map(
          (entry) => PlantProfile.fromRealtimeDatabase(
            entry.key.toString(),
            Map<dynamic, dynamic>.from(entry.value as Map),
          ),
        )
        .toList();

    plants.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return plants;
  }

  // Edited to keep only one active profile within the signed-in user's own RTDB branch.
  Future<void> setActivePlant(String uid, String plantId) async {
    final plants = await getPlantProfiles(uid);
    final Map<String, Object?> updates = {};

    for (final plant in plants) {
      if (plant.id == null) continue;
      updates['plantProfiles/${plant.id}/isActive'] = plant.id == plantId;
    }

    final active = plants.firstWhere((plant) => plant.id == plantId);
    updates['activeProfile'] = active.copyWith(isActive: true).toRealtimeDatabaseMap()
      ..['id'] = active.id
      // Edited to satisfy the stricter RTDB activeProfile validation rule and prove which user owns this profile.
      ..['ownerUid'] = uid
      ..['updatedAt'] = DateTime.now().toIso8601String();

    await userRootRef(uid).update(updates);
  }

  // Edited to remove a profile from the signed-in user's cloud profile collection.
  Future<void> deletePlantProfile(String uid, String plantId) async {
    await plantProfilesRef(uid).child(plantId).remove();
  }

  // Edited to clear stale activeProfile data after the current user's last profile is deleted.
  Future<void> clearActiveProfile(String uid) async {
    await activeProfileRef(uid).remove();
  }

  // Edited to publish the selected profile to the user's own activeProfile node for the ESP32 to read.
  Future<void> uploadActiveProfile(String uid, PlantProfile plant) async {
    await activeProfileRef(uid).set({
      'id': plant.id,
      'name': plant.name,
      'phMin': plant.phMin,
      'phMax': plant.phMax,
      'tempMin': plant.tempMin,
      'tempMax': plant.tempMax,
      'tdsMin': plant.tdsMin,
      'tdsMax': plant.tdsMax,
      'wateringCycleHours': plant.wateringCycleHours,
      'isActive': plant.isActive,
      // Edited to satisfy the stricter RTDB activeProfile validation rule and prove which user owns this profile.
      'ownerUid': uid,
      'updatedAt': DateTime.now().toIso8601String(),
    });
  }

  // Edited to listen to the signed-in user's system status instead of the old global systemStatus node.
  Stream<DatabaseEvent> watchSystemStatus(String uid) {
    return systemStatusRef(uid).onValue;
  }
}
