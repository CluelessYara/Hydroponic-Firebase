import 'package:flutter/material.dart';
import '../models/plant_profile.dart';
import '../services/firebase_service.dart';

class PlantProvider extends ChangeNotifier {
  PlantProvider({required String uid}) : _firebaseService = FirebaseService(uid: uid);

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
    _setLoading(true);
    try {
      _plants = await _firebaseService.getPlantProfiles();

      if (_plants.isNotEmpty && !_plants.any((p) => p.isActive)) {
        final first = _plants.first;
        if (first.id != null) {
          await setActivePlant(first.id!);
          return;
        }
      }

      _error = null;
      notifyListeners();
    } catch (error) {
      _error = 'Unable to load plant profiles: $error';
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> addPlant(PlantProfile plant) async {
    try {
      final shouldActivate = _plants.isEmpty;
      final id = await _firebaseService.savePlantProfile(plant);
      await loadPlants();

      if (shouldActivate) {
        await setActivePlant(id);
      }
    } catch (error) {
      _error = 'Unable to save plant profile: $error';
      notifyListeners();
      rethrow;
    }
  }

  Future<void> setActivePlant(String id) async {
    final selectedPlant = _plants.firstWhere((plant) => plant.id == id);
    await _firebaseService.setActiveProfile(selectedPlant);
    await loadPlants();
  }

  Future<void> updatePlant(PlantProfile plant) async {
    try {
      await _firebaseService.savePlantProfile(plant);
      await loadPlants();

      final active = activePlant;
      if (active != null && active.id == plant.id) {
        await _firebaseService.setActiveProfile(active);
      }
    } catch (error) {
      _error = 'Unable to update plant profile: $error';
      notifyListeners();
      rethrow;
    }
  }

  Future<void> deletePlant(String id) async {
    await _firebaseService.deletePlantProfile(id);
    await loadPlants();

    if (_plants.isNotEmpty && !_plants.any((p) => p.isActive)) {
      final first = _plants.first;
      if (first.id != null) {
        await setActivePlant(first.id!);
      }
    }
  }

  void _setLoading(bool isLoading) {
    if (_isLoading == isLoading) return;
    _isLoading = isLoading;
    notifyListeners();
  }
}
