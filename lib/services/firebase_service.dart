import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:firebase_database/firebase_database.dart';
import '../models/plant_profile.dart';

class FirebaseService {
  FirebaseService({required this.uid});

  static const Duration _operationTimeout = Duration(seconds: 12);

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
    _log('Loading plant profiles from ${plantProfilesRef.path}');
    final snapshot = await plantProfilesRef.get().timeout(_operationTimeout);
    final value = snapshot.value;

    if (value == null) {
      _log('No plant profiles found at ${plantProfilesRef.path}');
      return [];
    }
    if (value is! Map) {
      _log('Unexpected plant profile payload type: ${value.runtimeType}');
      return [];
    }

    final profiles = value.entries.map((entry) {
      final data = Map<String, dynamic>.from(entry.value as Map);
      return PlantProfile.fromMap(data, id: entry.key.toString());
    }).toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

    _log('Loaded ${profiles.length} plant profile(s) for uid=$uid');
    return profiles;
  }

  Future<String> savePlantProfile(PlantProfile plant) async {
    final ref = plant.id == null
        ? plantProfilesRef.push()
        : plantProfilesRef.child(plant.id!);
    final id = ref.key!;

    _log('Saving plant profile id=$id name=${plant.name} to ${ref.path}');
    await ref.set({
      ...plant.copyWith(id: id).toMap(),
      'updatedAt': ServerValue.timestamp,
    }).timeout(_operationTimeout);

    _log('Saved plant profile id=$id');
    return id;
  }

  Future<String> savePlantProfileAndActivate(PlantProfile plant) async {
    final ref = plant.id == null
        ? plantProfilesRef.push()
        : plantProfilesRef.child(plant.id!);
    final id = ref.key!;
    final activePlant = plant.copyWith(id: id, isActive: true);

    _log(
      'Saving and activating first plant profile id=$id '
      'name=${plant.name} under ${userRef.path}',
    );
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

    _log('Saved and activated plant profile id=$id');
    return id;
  }

  Future<void> deletePlantProfile(String id) async {
    _log('Deleting plant profile id=$id');
    await plantProfilesRef.child(id).remove().timeout(_operationTimeout);
    _log('Deleted plant profile id=$id');
  }

  Future<void> setActiveProfile(PlantProfile plant) async {
    if (plant.id == null) {
      throw ArgumentError('Cannot activate a plant profile without an id.');
    }

    _log('Setting active plant profile id=${plant.id} name=${plant.name}');
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
    _log('Active plant profile set to id=${plant.id}');
  }

  void _log(String message) {
    debugPrint('[FirebaseService][$uid] $message');
  }

  Stream<DatabaseEvent> watchSystemStatus() {
    return systemStatusRef.onValue;
  }
}
