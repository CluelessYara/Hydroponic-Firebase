class PlantProfile {
  final int? id;
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

  factory PlantProfile.fromMap(Map<String, dynamic> map) {
    return PlantProfile(
      id: map['id'],
      name: map['name'],
      phMin: (map['phMin'] as num).toDouble(),
      phMax: (map['phMax'] as num).toDouble(),
      tempMin: (map['tempMin'] as num).toDouble(),
      tempMax: (map['tempMax'] as num).toDouble(),
      tdsMin: (map['tdsMin'] as num).toDouble(),
      tdsMax: (map['tdsMax'] as num).toDouble(),
      wateringCycleHours: map['wateringCycleHours'],
      isActive: map['isActive'] == 1,
    );
  }

  PlantProfile copyWith({
    int? id,
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