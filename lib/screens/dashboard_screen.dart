import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_auth_provider.dart';
import '../providers/plant_provider.dart';
import '../providers/sensor_provider.dart';
import 'plant_list_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AppAuthProvider>();
    final plantProvider = context.watch<PlantProvider>();
    final sensorProvider = context.watch<SensorProvider>();
    final plant = plantProvider.activePlant;
    final status = sensorProvider.currentStatus;

    if (plant == null) {
      return const Scaffold(
        body: Center(
          child: Text('No active plant profile found'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(plant.name),
        actions: [
          IconButton(
            tooltip: 'ESP32 user path',
            icon: const Icon(Icons.memory),
            onPressed: () {
              _showEsp32Path(context, authProvider.user!.uid);
            },
          ),
          IconButton(
            tooltip: 'Plant profiles',
            icon: const Icon(Icons.list),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const PlantListScreen(),
                ),
              );
            },
          ),
          IconButton(
            tooltip: 'Sign out',
            icon: const Icon(Icons.logout),
            onPressed: () => context.read<AppAuthProvider>().signOut(),
          ),
        ],
      ),
      body: status == null
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Waiting for ESP32 sensor readings at your user-specific systemStatus path.',
                  textAlign: TextAlign.center,
                ),
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _statusBanner(status.overallStatus),
                  const SizedBox(height: 16),

                  Row(
                    children: [
                      Expanded(
                        child: _sensorCard(
                          'pH',
                          status.ph.toStringAsFixed(2),
                          Colors.blue,
                          Icons.science,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _sensorCard(
                          'Temp',
                          '${status.temperature.toStringAsFixed(1)} °C',
                          Colors.orange,
                          Icons.thermostat,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  Row(
                    children: [
                      Expanded(
                        child: _sensorCard(
                          'TDS',
                          '${status.tds.toStringAsFixed(0)} ppm',
                          Colors.green,
                          Icons.opacity,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _sensorCard(
                          'Water Level',
                          '${status.waterLevel.toStringAsFixed(1)} %',
                          Colors.teal,
                          Icons.water,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  Row(
                    children: [
                      Expanded(
                        child: _sensorCard(
                          'Flood State',
                          status.isFlooding ? 'Flooding' : 'Draining',
                          status.isFlooding ? Colors.indigo : Colors.grey,
                          status.isFlooding ? Icons.waves : Icons.water_drop_outlined,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _sensorCard(
                          'Watering Cycle',
                          'Every ${plant.wateringCycleHours}h',
                          Colors.purple,
                          Icons.schedule,
                        ),
                      ),
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

                  const SizedBox(height: 20),

                  _infoBox(
                    'Last update: ${status.timestamp.toLocal()}',
                  ),
                ],
              ),
            ),
    );
  }

  void _showEsp32Path(BuildContext context, String uid) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ESP32 RTDB path'),
        content: SelectableText(
          'Configure the ESP32 firmware to read active profile values from '
          'users/$uid/activeProfile and write live readings to '
          'users/$uid/systemStatus.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _sensorCard(String title, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.14),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 30),
          const SizedBox(height: 10),
          Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusBanner(String status) {
    final isNormal = status.toLowerCase() == 'normal';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isNormal
            ? Colors.green.withOpacity(0.15)
            : Colors.red.withOpacity(0.15),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isNormal ? Colors.green : Colors.red,
        ),
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
        leading: const Icon(
          Icons.warning_amber_rounded,
          color: Colors.red,
        ),
        title: Text(text),
      ),
    );
  }

  Widget _infoBox(String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.blueGrey.withOpacity(0.10),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(text),
    );
  }
}