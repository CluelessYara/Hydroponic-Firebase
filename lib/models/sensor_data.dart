class SensorData {
  final double ph;
  final double temperature;
  final double tds;
  final double waterLevel;
  final DateTime timestamp;

  SensorData({
    required this.ph,
    required this.temperature,
    required this.tds,
    required this.waterLevel,
    required this.timestamp,
  });
}