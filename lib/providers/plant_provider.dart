import 'package:flutter/material.dart';
import '../models/plant_profile.dart';
import '../services/firebase_service.dart';

class PlantProvider extends ChangeNotifier {
  // Edited to use FirebaseService for cloud profiles instead of device-only SQLite storage.
  final FirebaseService _firebaseService = FirebaseService();
  List<PlantProfile> _plants = [];
  String? _uid;
  bool _isLoading = false;

  List<PlantProfile> get plants => _plants;
  bool get isLoading => _isLoading;

  PlantProfile? get activePlant {
    try {
      return _plants.firstWhere((p) => p.isActive);
    } catch (_) {
      return _plants.isNotEmpty ? _plants.first : null;
    }
  }

  bool get hasPlants => _plants.isNotEmpty;

  Future<void> bindToUser(String uid) async {
    if (_uid == uid && _plants.isNotEmpty) return;

    // Edited to reload the profile list whenever a different Firebase Auth account signs in.
    _uid = uid;
    await loadPlants();
  }

  void clearForSignedOutUser() {
    // Edited to prevent a signed-out or newly switched user from seeing another user's cached profiles.
    _uid = null;
    _plants = [];
    notifyListeners();
  }

  Future<void> loadPlants() async {
    if (_uid == null) return;

    _isLoading = true;
    notifyListeners();

    _plants = await _firebaseService.getPlantProfiles(_uid!);

    if (_plants.isEmpty) {
      // Edited to ensure the ESP32 does not keep using a deleted profile when this account has none left.
      await _firebaseService.clearActiveProfile(_uid!);
    }

    if (_plants.isNotEmpty && !_plants.any((p) => p.isActive)) {
      final first = _plants.first;
      if (first.id != null) {
        await _firebaseService.setActivePlant(_uid!, first.id!);
        _plants = await _firebaseService.getPlantProfiles(_uid!);
      }
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> addPlant(PlantProfile plant) async {
    if (_uid == null) return;

    // Edited to make a user's first cloud profile active automatically for the ESP32 target branch.
    final shouldBecomeActive = _plants.isEmpty;
    final id = await _firebaseService.savePlantProfile(
      _uid!,
      plant.copyWith(isActive: shouldBecomeActive),
    );

    if (shouldBecomeActive) {
      await _firebaseService.setActivePlant(_uid!, id);
    }

    await loadPlants();
  }

  Future<void> setActivePlant(String id) async {
    if (_uid == null) return;

    // Edited so selecting a profile updates only this user's activeProfile RTDB path.
    await _firebaseService.setActivePlant(_uid!, id);
    await loadPlants();
  }

  Future<void> updatePlant(PlantProfile plant) async {
    if (_uid == null) return;

    // Edited to save edits to the user's cloud profile and refresh activeProfile when the edited profile is active.
    await _firebaseService.savePlantProfile(_uid!, plant);
    if (plant.isActive) {
      await _firebaseService.uploadActiveProfile(_uid!, plant);
    }
    await loadPlants();
  }

  Future<void> deletePlant(String id) async {
    if (_uid == null) return;

    // Edited to delete profiles from the current user's cloud branch and choose another active profile if needed.
    await _firebaseService.deletePlantProfile(_uid!, id);
    await loadPlants();

    if (_plants.isEmpty) {
      // Edited to ensure the ESP32 does not keep using a deleted profile when this account has none left.
      await _firebaseService.clearActiveProfile(_uid!);
    }

    if (_plants.isNotEmpty && !_plants.any((p) => p.isActive)) {
      final first = _plants.first;
      if (first.id != null) {
        await setActivePlant(first.id!);
      }
    }
  }
}
