import 'dart:async';
import 'package:flutter/material.dart';
import '../models/plant_profile.dart';
import '../models/system_status.dart';
import '../services/mock_sensor_service.dart';

class SensorProvider extends ChangeNotifier {
  final MockSensorService _mockSensorService = MockSensorService();
  StreamSubscription? _subscription;

  SystemStatus? _currentStatus;
  SystemStatus? get currentStatus => _currentStatus;

  List<String> _warnings = [];
  List<String> get warnings => _warnings;

  PlantProfile? _currentProfile;
  PlantProfile? get currentProfile => _currentProfile;

  void startListening(PlantProfile profile) {
    _subscription?.cancel();
    _currentProfile = profile;

    _subscription = _mockSensorService.sensorStream(profile).listen((status) {
      _currentStatus = status;
      _warnings = status.warnings;
      notifyListeners();
    });
  }

  void stopListening() {
    _subscription?.cancel();
    _subscription = null;
    _currentStatus = null;
    _warnings = [];
    notifyListeners();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}