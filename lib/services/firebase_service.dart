import 'package:firebase_database/firebase_database.dart';
import '../models/plant_profile.dart';

class FirebaseService {
  final FirebaseDatabase _database = FirebaseDatabase.instanceFor(
    app: FirebaseDatabase.instance.app,
    databaseURL:
        'https://hydroponic-system-61a0f-default-rtdb.asia-southeast1.firebasedatabase.app',
  );

  DatabaseReference get activeProfileRef => _database.ref('activeProfile');
  DatabaseReference get systemStatusRef => _database.ref('systemStatus');

  Future<void> uploadActiveProfile(PlantProfile plant) async {
    await activeProfileRef.set({
      'id': plant.id,
      'name': plant.name,
      'phMin': plant.phMin,
      'phMax': plant.phMax,
      'tempMin': plant.tempMin,
      'tempMax': plant.tempMax,
      'tdsMin': plant.tdsMin,
      'tdsMax': plant.tdsMax,
      'wateringCycleHours': plant.wateringCycleHours,
      'isActive': plant.isActive,
      'updatedAt': DateTime.now().toIso8601String(),
    });
  }

  Stream<DatabaseEvent> watchSystemStatus() {
    return systemStatusRef.onValue;
  }
}