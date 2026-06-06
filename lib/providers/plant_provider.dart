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
    _log('START loadPlants');
    _setLoading(true);
    try {
      _plants = await _firebaseService.getPlantProfiles();
      _log('loadPlants received ${_plants.length} profile(s)');

      if (_plants.isNotEmpty && !_plants.any((p) => p.isActive)) {
        final first = _plants.first;
        if (first.id != null) {
          _log('No active profile; activating first profile id=${first.id}');
          await _firebaseService.setActiveProfile(first);
          _plants = _plants
              .map((plant) => plant.id == first.id
                  ? plant.copyWith(isActive: true)
                  : plant.copyWith(isActive: false))
              .toList();
        }
      }

      _error = null;
      _log('DONE loadPlants');
      notifyListeners();
    } catch (error, stackTrace) {
      _log('ERROR loadPlants: $error');
      debugPrintStack(stackTrace: stackTrace);
      _error = _friendlyDataMessage('load plant profiles', error);
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> addPlant(PlantProfile plant) async {
    _log('START addPlant name=${plant.name} existingCount=${_plants.length}');
    try {
      if (_plants.isEmpty) {
        _log('addPlant saving and activating first profile');
        final id = await _firebaseService.savePlantProfileAndActivate(plant);
        _plants = [plant.copyWith(id: id, isActive: true)];
      } else {
        _log('addPlant saving non-active profile');
        final id = await _firebaseService.savePlantProfile(plant);
        _plants = [..._plants, plant.copyWith(id: id, isActive: false)];
      }

      _error = null;
      _log('DONE addPlant localCount=${_plants.length}');
      notifyListeners();
    } catch (error, stackTrace) {
      _log('ERROR addPlant: $error');
      debugPrintStack(stackTrace: stackTrace);
      _error = _friendlyDataMessage('save plant profile', error);
      notifyListeners();
      rethrow;
    }
  }

  Future<void> setActivePlant(String id) async {
    _log('START setActivePlant id=$id');
    try {
      final selectedPlant = _plants.firstWhere((plant) => plant.id == id);
      await _firebaseService.setActiveProfile(selectedPlant);
      _plants = _plants
          .map((plant) => plant.copyWith(isActive: plant.id == id))
          .toList();
      _error = null;
      _log('DONE setActivePlant id=$id');
      notifyListeners();
    } catch (error, stackTrace) {
      _log('ERROR setActivePlant id=$id: $error');
      debugPrintStack(stackTrace: stackTrace);
      _error = _friendlyDataMessage('set active plant profile', error);
      notifyListeners();
      rethrow;
    }
  }

  Future<void> updatePlant(PlantProfile plant) async {
    _log('START updatePlant id=${plant.id} name=${plant.name}');
    try {
      await _firebaseService.savePlantProfile(plant);
      final existingIndex = _plants.indexWhere((item) => item.id == plant.id);
      if (existingIndex == -1) {
        _plants = [..._plants, plant];
      } else {
        final updatedPlants = [..._plants];
        updatedPlants[existingIndex] = plant;
        _plants = updatedPlants;
      }

      final active = activePlant;
      if (active != null && active.id == plant.id) {
        await _firebaseService.setActiveProfile(active);
      }

      _error = null;
      _log('DONE updatePlant id=${plant.id}');
      notifyListeners();
    } catch (error, stackTrace) {
      _log('ERROR updatePlant id=${plant.id}: $error');
      debugPrintStack(stackTrace: stackTrace);
      _error = _friendlyDataMessage('update plant profile', error);
      notifyListeners();
      rethrow;
    }
  }

  Future<void> deletePlant(String id) async {
    _log('START deletePlant id=$id');
    try {
      await _firebaseService.deletePlantProfile(id);
      _plants = _plants.where((plant) => plant.id != id).toList();

      if (_plants.isNotEmpty && !_plants.any((p) => p.isActive)) {
        final first = _plants.first;
        if (first.id != null) {
          await setActivePlant(first.id!);
          return;
        }
      }

      _error = null;
      _log('DONE deletePlant id=$id localCount=${_plants.length}');
      notifyListeners();
    } catch (error, stackTrace) {
      _log('ERROR deletePlant id=$id: $error');
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
    // Use print so messages appear in VS Code's terminal/debug console.
    // ignore: avoid_print
    print('[PlantProvider][$_uid] $message');
  }

  void _setLoading(bool isLoading) {
    if (_isLoading == isLoading) return;
    _isLoading = isLoading;
    notifyListeners();
  }
}
