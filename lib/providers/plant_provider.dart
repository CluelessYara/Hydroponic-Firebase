import 'package:flutter/material.dart';
import '../models/plant_profile.dart';
import '../services/database_service.dart';
import '../services/firebase_service.dart';
final FirebaseService _firebaseService = FirebaseService();

class PlantProvider extends ChangeNotifier {
  List<PlantProfile> _plants = [];

  List<PlantProfile> get plants => _plants;

  PlantProfile? get activePlant {
    try {
      return _plants.firstWhere((p) => p.isActive);
    } catch (_) {
      return _plants.isNotEmpty ? _plants.first : null;
    }
  }

  bool get hasPlants => _plants.isNotEmpty;

  Future<void> loadPlants() async {
    _plants = await DatabaseService.instance.getPlants();

    if (_plants.isNotEmpty && !_plants.any((p) => p.isActive)) {
      final first = _plants.first;
      if (first.id != null) {
        await DatabaseService.instance.setActivePlant(first.id!);
        _plants = await DatabaseService.instance.getPlants();
      }
    }

    notifyListeners();
  }

  Future<void> addPlant(PlantProfile plant) async {
    await DatabaseService.instance.insertPlant(plant);
    await loadPlants();

    if (_plants.length == 1 && _plants.first.id != null) {
      await setActivePlant(_plants.first.id!);
    }
  }

  Future<void> setActivePlant(int id) async {
    await DatabaseService.instance.setActivePlant(id);
    await loadPlants();
    final active = activePlant;
    if (active != null) {
      print('Uploading active profile: ${active.name}');
      await _firebaseService.uploadActiveProfile(active);
  }
  }

  Future<void> updatePlant(PlantProfile plant) async {
    await DatabaseService.instance.updatePlant(plant);
    await loadPlants();
    final active = activePlant;
    if (active != null) {
      print('Uploading active profile: ${active.name}');
      await _firebaseService.uploadActiveProfile(active);
  }
  }

  Future<void> deletePlant(int id) async {
    await DatabaseService.instance.deletePlant(id);
    await loadPlants();

    if (_plants.isNotEmpty && !_plants.any((p) => p.isActive)) {
      final first = _plants.first;
      if (first.id != null) {
        await setActivePlant(first.id!);
      }
    }
  }
}