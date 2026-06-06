import 'dart:async';

import 'package:firebase_database/firebase_database.dart';
import '../models/plant_profile.dart';

class FirebaseService {
  FirebaseService({required this.uid});

  static const Duration _operationTimeout = Duration(seconds: 15);

  final String uid;

  final FirebaseDatabase _database = FirebaseDatabase.instanceFor(
    app: FirebaseDatabase.instance.app,
    databaseURL:
        'https://hydroponic-system-61a0f-default-rtdb.asia-southeast1.firebasedatabase.app',
  );

  DatabaseReference get userRef => _database.ref('users/$uid');
  DatabaseReference get plantProfilesRef => userRef.child('plantProfiles');
  DatabaseReference get activeProfileRef => userRef.child('activeProfile');
  DatabaseReference get systemStatusRef => userRef.child('systemStatus');

  Future<List<PlantProfile>> getPlantProfiles() async {
    final snapshot = await plantProfilesRef.get().timeout(_operationTimeout);
    final value = snapshot.value;

    if (value == null) return [];
    if (value is! Map) return [];

    return value.entries.map((entry) {
      final data = Map<String, dynamic>.from(entry.value as Map);
      return PlantProfile.fromMap(data, id: entry.key.toString());
    }).toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
  }

  Future<String> savePlantProfile(PlantProfile plant) async {
    final ref = plant.id == null
        ? plantProfilesRef.push()
        : plantProfilesRef.child(plant.id!);
    final id = ref.key!;

    await ref.set({
      ...plant.copyWith(id: id).toMap(),
      'updatedAt': ServerValue.timestamp,
    }).timeout(_operationTimeout);

    return id;
  }

  Future<String> savePlantProfileAndActivate(PlantProfile plant) async {
    final ref = plant.id == null
        ? plantProfilesRef.push()
        : plantProfilesRef.child(plant.id!);
    final id = ref.key!;
    final activePlant = plant.copyWith(id: id, isActive: true);

    await userRef.update({
      'plantProfiles/$id': {
        ...activePlant.toMap(),
        'updatedAt': ServerValue.timestamp,
      },
      'activeProfile': {
        ...activePlant.toMap(),
        'ownerUid': uid,
        'updatedAt': ServerValue.timestamp,
      },
    }).timeout(_operationTimeout);

    return id;
  }

  Future<void> deletePlantProfile(String id) async {
    await plantProfilesRef.child(id).remove().timeout(_operationTimeout);
  }

  Future<void> setActiveProfile(PlantProfile plant) async {
    if (plant.id == null) {
      throw ArgumentError('Cannot activate a plant profile without an id.');
    }

    final profile = plant.copyWith(isActive: true);
    final updates = <String, Object?>{
      'activeProfile': {
        ...profile.toMap(),
        'ownerUid': uid,
        'updatedAt': ServerValue.timestamp,
      },
      'plantProfiles/${plant.id}/isActive': true,
      'plantProfiles/${plant.id}/updatedAt': ServerValue.timestamp,
    };

    final profiles = await getPlantProfiles();
    for (final existing in profiles) {
      if (existing.id != null && existing.id != plant.id) {
        updates['plantProfiles/${existing.id}/isActive'] = false;
      }
    }

    await userRef.update(updates).timeout(_operationTimeout);
  }

  Stream<DatabaseEvent> watchSystemStatus() {
    return systemStatusRef.onValue;
  }
}
