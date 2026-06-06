import 'dart:async';

import 'package:flutter/material.dart';
import '../models/plant_profile.dart';
import '../services/firebase_service.dart';

class PlantProvider extends ChangeNotifier {
  PlantProvider({required String uid})
      : _uid = uid,
        _firebaseService = FirebaseService(uid: uid);

  final String _uid;
  final FirebaseService _firebaseService;

  List<PlantProfile> _plants = [];
  bool _isLoading = false;
  String? _error;

  List<PlantProfile> get plants => _plants;
  bool get isLoading => _isLoading;
  String? get error => _error;

  PlantProfile? get activePlant {
    try {
      return _plants.firstWhere((p) => p.isActive);
    } catch (_) {
      return _plants.isNotEmpty ? _plants.first : null;
    }
  }

  bool get hasPlants => _plants.isNotEmpty;

  Future<void> loadPlants() async {
    _log('loadPlants started');
    _setLoading(true);
    try {
      _plants = await _firebaseService.getPlantProfiles();
      _log('loadPlants received ${_plants.length} profile(s)');

      if (_plants.isNotEmpty && !_plants.any((p) => p.isActive)) {
        final first = _plants.first;
        if (first.id != null) {
          _log(
            'No active profile found; activating first profile id=${first.id}',
          );
          await _firebaseService.setActiveProfile(first);
          _plants = await _firebaseService.getPlantProfiles();
          _log('loadPlants received ${_plants.length} profile(s)');
        }
      }

      _error = null;
      _log('loadPlants completed successfully');
      notifyListeners();
    } catch (error, stackTrace) {
      _log('loadPlants failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      _error = _friendlyDataMessage('load plant profiles', error);
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> addPlant(PlantProfile plant) async {
    _log(
      'addPlant started for name=${plant.name} existingCount=${_plants.length}',
    );
    try {
      if (_plants.isEmpty) {
        _log('addPlant will save and activate first profile');
        await _firebaseService.savePlantProfileAndActivate(plant);
      } else {
        _log('addPlant will save non-active profile');
        await _firebaseService.savePlantProfile(plant);
      }

      await loadPlants();
      _log('addPlant completed successfully');
    } catch (error, stackTrace) {
      _log('addPlant failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      _error = _friendlyDataMessage('save plant profile', error);
      notifyListeners();
      rethrow;
    }
  }

  Future<void> setActivePlant(String id) async {
    _log('setActivePlant started for id=$id');
    try {
      final selectedPlant = _plants.firstWhere((plant) => plant.id == id);
      await _firebaseService.setActiveProfile(selectedPlant);
      await loadPlants();
      _log('setActivePlant completed for id=$id');
    } catch (error, stackTrace) {
      _log('setActivePlant failed for id=$id: $error');
      debugPrintStack(stackTrace: stackTrace);
      _error = _friendlyDataMessage('set active plant profile', error);
      notifyListeners();
      rethrow;
    }
  }

  Future<void> updatePlant(PlantProfile plant) async {
    _log('updatePlant started for id=${plant.id} name=${plant.name}');
    try {
      await _firebaseService.savePlantProfile(plant);
      await loadPlants();

      final active = activePlant;
      if (active != null && active.id == plant.id) {
        await _firebaseService.setActiveProfile(active);
        await loadPlants();
      }
      _log('updatePlant completed for id=${plant.id}');
    } catch (error, stackTrace) {
      _log('updatePlant failed for id=${plant.id}: $error');
      debugPrintStack(stackTrace: stackTrace);
      _error = _friendlyDataMessage('update plant profile', error);
      notifyListeners();
      rethrow;
    }
  }

  Future<void> deletePlant(String id) async {
    _log('deletePlant started for id=$id');
    try {
      await _firebaseService.deletePlantProfile(id);
      await loadPlants();

      if (_plants.isNotEmpty && !_plants.any((p) => p.isActive)) {
        final first = _plants.first;
        if (first.id != null) {
          await setActivePlant(first.id!);
        }
      }
      _log('deletePlant completed for id=$id');
    } catch (error, stackTrace) {
      _log('deletePlant failed for id=$id: $error');
      debugPrintStack(stackTrace: stackTrace);
      _error = _friendlyDataMessage('delete plant profile', error);
      notifyListeners();
      rethrow;
    }
  }

  String _friendlyDataMessage(String action, Object error) {
    if (error is TimeoutException) {
      return 'Unable to $action because Firebase did not respond. Check '
          'your internet connection, Firebase project, and database rules.';
    }

    return 'Unable to $action: $error';
  }

  void _log(String message) {
    debugPrint('[PlantProvider][$_uid] $message');
  }

  void _setLoading(bool isLoading) {
    if (_isLoading == isLoading) return;
    _isLoading = isLoading;
    notifyListeners();
  }
}
