import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/plant_provider.dart';
import '../providers/sensor_provider.dart';
import 'plant_list_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final plantProvider = context.watch<PlantProvider>();
    final sensorProvider = context.watch<SensorProvider>();
    final plant = plantProvider.activePlant;
    final status = sensorProvider.currentStatus;

    if (plant == null) {
      return const Scaffold(
        body: Center(child: Text('No active plant profile found')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(plant.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.list),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PlantListScreen()),
              );
            },
          ),
        ],
      ),
      body: status == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _statusBanner(status.overallStatus),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(child: _sensorCard('pH', status.ph.toStringAsFixed(2), Colors.blue)),
                      const SizedBox(width: 12),
                      Expanded(child: _sensorCard('Temp', '${status.temperature.toStringAsFixed(1)} °C', Colors.orange)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: _sensorCard('TDS', '${status.tds.toStringAsFixed(0)} ppm', Colors.green)),
                      const SizedBox(width: 12),
                      Expanded(child: _sensorCard('Watering', 'Every ${plant.wateringCycleHours}h', Colors.purple)),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Warnings',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (sensorProvider.warnings.isEmpty)
                    _infoBox('No warnings. Conditions are within the optimal range.')
                  else
                    ...sensorProvider.warnings.map((w) => _warningTile(w)),
                ],
              ),
            ),
    );
  }

  Widget _sensorCard(String title, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color),
      ),
      child: Column(
        children: [
          Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 10),
          Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _statusBanner(String status) {
    final isNormal = status == 'Normal';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isNormal ? Colors.green.withOpacity(0.15) : Colors.red.withOpacity(0.15),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isNormal ? Colors.green : Colors.red),
      ),
      child: Text(
        'System Status: $status',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: isNormal ? Colors.green : Colors.red,
        ),
      ),
    );
  }

  Widget _warningTile(String text) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.warning_amber_rounded, color: Colors.red),
        title: Text(text),
      ),
    );
  }

  Widget _infoBox(String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(text),
    );
  }
}