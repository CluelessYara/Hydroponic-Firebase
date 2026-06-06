import 'dart:async';

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
    _log('START getPlantProfiles path=${plantProfilesRef.path}');
    final snapshot = await _withTimeout(
      plantProfilesRef.get(),
      'getPlantProfiles ${plantProfilesRef.path}',
    );
    final value = snapshot.value;

    if (value == null) {
      _log('DONE getPlantProfiles: no profiles found');
      return [];
    }
    if (value is! Map) {
      _log('DONE getPlantProfiles: unexpected payload ${value.runtimeType}');
      return [];
    }

    final profiles = value.entries.map((entry) {
      final data = Map<String, dynamic>.from(entry.value as Map);
      return PlantProfile.fromMap(data, id: entry.key.toString());
    }).toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

    _log('DONE getPlantProfiles count=${profiles.length}');
    return profiles;
  }

  Future<String> savePlantProfile(PlantProfile plant) async {
    final ref = plant.id == null
        ? plantProfilesRef.push()
        : plantProfilesRef.child(plant.id!);
    final id = ref.key!;

    _log('START savePlantProfile id=$id name=${plant.name} path=${ref.path}');
    await _withTimeout(
      ref.set({
        ...plant.copyWith(id: id).toMap(),
        'updatedAt': ServerValue.timestamp,
      }),
      'savePlantProfile ${ref.path}',
    );

    _log('DONE savePlantProfile id=$id');
    return id;
  }

  Future<String> savePlantProfileAndActivate(PlantProfile plant) async {
    final ref = plant.id == null
        ? plantProfilesRef.push()
        : plantProfilesRef.child(plant.id!);
    final id = ref.key!;
    final activePlant = plant.copyWith(id: id, isActive: true);

    _log(
      'START savePlantProfileAndActivate id=$id name=${plant.name} '
      'path=${userRef.path}',
    );
    await _withTimeout(
      userRef.update({
        'plantProfiles/$id': {
          ...activePlant.toMap(),
          'updatedAt': ServerValue.timestamp,
        },
        'activeProfile': {
          ...activePlant.toMap(),
          'ownerUid': uid,
          'updatedAt': ServerValue.timestamp,
        },
      }),
      'savePlantProfileAndActivate ${userRef.path}',
    );

    _log('DONE savePlantProfileAndActivate id=$id');
    return id;
  }

  Future<void> deletePlantProfile(String id) async {
    _log('START deletePlantProfile id=$id');
    await _withTimeout(
      plantProfilesRef.child(id).remove(),
      'deletePlantProfile ${plantProfilesRef.child(id).path}',
    );
    _log('DONE deletePlantProfile id=$id');
  }

  Future<void> setActiveProfile(PlantProfile plant) async {
    if (plant.id == null) {
      throw ArgumentError('Cannot activate a plant profile without an id.');
    }

    _log('START setActiveProfile id=${plant.id} name=${plant.name}');
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

    await _withTimeout(
      userRef.update(updates),
      'setActiveProfile ${userRef.path}',
    );
    _log('DONE setActiveProfile id=${plant.id}');
  }

  Future<T> _withTimeout<T>(Future<T> future, String operation) {
    return future.timeout(
      _operationTimeout,
      onTimeout: () {
        _log('TIMEOUT $operation after ${_operationTimeout.inSeconds}s');
        throw TimeoutException(
          '$operation timed out after ${_operationTimeout.inSeconds} seconds',
          _operationTimeout,
        );
      },
    );
  }

  void _log(String message) {
    // Use print so messages appear in VS Code's terminal/debug console.
    // ignore: avoid_print
    print('[FirebaseService][$uid] $message');
  }

  Stream<DatabaseEvent> watchSystemStatus() {
    return systemStatusRef.onValue;
  }
}
