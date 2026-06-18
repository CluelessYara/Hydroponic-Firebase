class PlantProfile {
  // Edited to use String ids because Firebase RTDB push keys are strings and must sync across devices.
  final String? id;
  final String name;
  final double phMin;
  final double phMax;
  final double tempMin;
  final double tempMax;
  final double tdsMin;
  final double tdsMax;
  final int wateringCycleHours;
  final bool isActive;

  PlantProfile({
    this.id,
    required this.name,
    required this.phMin,
    required this.phMax,
    required this.tempMin,
    required this.tempMax,
    required this.tdsMin,
    required this.tdsMax,
    required this.wateringCycleHours,
    this.isActive = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'phMin': phMin,
      'phMax': phMax,
      'tempMin': tempMin,
      'tempMax': tempMax,
      'tdsMin': tdsMin,
      'tdsMax': tdsMax,
      'wateringCycleHours': wateringCycleHours,
      'isActive': isActive ? 1 : 0,
    };
  }

  // Edited to store booleans naturally in Firebase while keeping the old local SQLite map available.
  Map<String, dynamic> toRealtimeDatabaseMap() {
    return {
      'name': name,
      'phMin': phMin,
      'phMax': phMax,
      'tempMin': tempMin,
      'tempMax': tempMax,
      'tdsMin': tdsMin,
      'tdsMax': tdsMax,
      'wateringCycleHours': wateringCycleHours,
      'isActive': isActive,
      'updatedAt': DateTime.now().toIso8601String(),
    };
  }

  factory PlantProfile.fromMap(Map<String, dynamic> map) {
    return PlantProfile(
      // Edited to safely accept both legacy integer ids and Firebase string ids during migration.
      id: map['id']?.toString(),
      name: map['name']?.toString() ?? '',
      phMin: (map['phMin'] as num).toDouble(),
      phMax: (map['phMax'] as num).toDouble(),
      tempMin: (map['tempMin'] as num).toDouble(),
      tempMax: (map['tempMax'] as num).toDouble(),
      tdsMin: (map['tdsMin'] as num).toDouble(),
      tdsMax: (map['tdsMax'] as num).toDouble(),
      wateringCycleHours: (map['wateringCycleHours'] as num).toInt(),
      // Edited to read either Firebase bools or legacy SQLite integer flags.
      isActive: map['isActive'] == true || map['isActive'] == 1,
    );
  }

  // Edited to rebuild Firebase list entries from their RTDB key plus the saved profile values.
  factory PlantProfile.fromRealtimeDatabase(String id, Map<dynamic, dynamic> map) {
    return PlantProfile.fromMap({
      'id': id,
      'name': map['name'],
      'phMin': map['phMin'],
      'phMax': map['phMax'],
      'tempMin': map['tempMin'],
      'tempMax': map['tempMax'],
      'tdsMin': map['tdsMin'],
      'tdsMax': map['tdsMax'],
      'wateringCycleHours': map['wateringCycleHours'],
      'isActive': map['isActive'],
    });
  }

  PlantProfile copyWith({
    String? id,
    String? name,
    double? phMin,
    double? phMax,
    double? tempMin,
    double? tempMax,
    double? tdsMin,
    double? tdsMax,
    int? wateringCycleHours,
    bool? isActive,
  }) {
    return PlantProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      phMin: phMin ?? this.phMin,
      phMax: phMax ?? this.phMax,
      tempMin: tempMin ?? this.tempMin,
      tempMax: tempMax ?? this.tempMax,
      tdsMin: tdsMin ?? this.tdsMin,
      tdsMax: tdsMax ?? this.tdsMax,
      wateringCycleHours: wateringCycleHours ?? this.wateringCycleHours,
      isActive: isActive ?? this.isActive,
    );
  }
}
