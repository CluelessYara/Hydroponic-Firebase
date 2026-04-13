import 'dart:async';
import 'dart:math';
import '../models/plant_profile.dart';
import '../models/system_status.dart';

class MockSensorService {
  final Random _random = Random();

  Stream<SystemStatus> sensorStream(PlantProfile profile) async* {
    while (true) {
      await Future.delayed(const Duration(seconds: 3));

      final ph = 5.0 + _random.nextDouble() * 3.5;
      final temp = 16 + _random.nextDouble() * 16;
      final tds = 300 + _random.nextDouble() * 900;

      final warnings = <String>[];

      if (ph < profile.phMin) {
        warnings.add('pH is below the optimal range');
      } else if (ph > profile.phMax) {
        warnings.add('pH is above the optimal range');
      }

      if (temp < profile.tempMin) {
        warnings.add('Water temperature is below the optimal range');
      } else if (temp > profile.tempMax) {
        warnings.add('Water temperature is above the optimal range');
      }

      if (tds < profile.tdsMin) {
        warnings.add('TDS is below the optimal range');
      } else if (tds > profile.tdsMax) {
        warnings.add('TDS is above the optimal range');
      }

      final overallStatus = warnings.isEmpty ? 'Normal' : 'Warning';

      yield SystemStatus(
        ph: ph,
        temperature: temp,
        tds: tds,
        timestamp: DateTime.now(),
        warnings: warnings,
        overallStatus: overallStatus,
      );
    }
  }
}