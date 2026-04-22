class SystemStatus {
  final double ph;
  final double temperature;
  final double tds;
  final double waterLevel;
  final bool isFlooding;
  final DateTime timestamp;
  final List<String> warnings;
  final String overallStatus;

  SystemStatus({
    required this.ph,
    required this.temperature,
    required this.tds,
    required this.waterLevel,
    required this.isFlooding,
    required this.timestamp,
    required this.warnings,
    required this.overallStatus,
  });
}