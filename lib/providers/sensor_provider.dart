import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import '../models/system_status.dart';
import '../services/firebase_service.dart';

class SensorProvider extends ChangeNotifier {
  final FirebaseService _firebaseService = FirebaseService();
  StreamSubscription<DatabaseEvent>? _subscription;

  SystemStatus? _currentStatus;
  SystemStatus? get currentStatus => _currentStatus;

  List<String> _warnings = [];
  List<String> get warnings => _warnings;

  void startListening() {
    _subscription?.cancel();

    _subscription = _firebaseService.watchSystemStatus().listen((event) {
      final data = event.snapshot.value;

      if (data == null) {
        return;
      }

      final map = Map<String, dynamic>.from(data as Map);

      List<String> warningsList = [];

      final warningsRaw = map['warnings'];
      if (warningsRaw is Map) {
        warningsList =
            warningsRaw.values.map((e) => e.toString()).toList();
      } else if (warningsRaw is List) {
        warningsList = warningsRaw.map((e) => e.toString()).toList();
      }

      _currentStatus = SystemStatus(
        ph: ((map['ph'] ?? 0) as num).toDouble(),
        temperature: ((map['temperature'] ?? 0) as num).toDouble(),
        tds: ((map['tds'] ?? 0) as num).toDouble(),
        waterLevel: ((map['waterLevel'] ?? 0) as num).toDouble(),
        isFlooding: (map['isFlooding'] ?? false) as bool,
        timestamp: DateTime.tryParse(map['timestamp']?.toString() ?? '') ??
            DateTime.now(),
        warnings: warningsList,
        overallStatus: map['overallStatus']?.toString() ?? 'Unknown',
      );

      _warnings = warningsList;
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