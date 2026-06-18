import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
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
            icon: const Icon(Icons.logout),
            tooltip: 'Sign out',
            onPressed: () {
              // Edited to allow testers to switch Firebase accounts on the same installed app.
              context.read<AppAuthProvider>().signOut();
            },
          ),
          IconButton(
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
        ],
      ),
      body: status == null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  // Edited to show the exact user-scoped RTDB path the ESP32 should write before sensor data exists.
                  'Waiting for ESP32 sensor data at users/${authProvider.user?.uid}/systemStatus',
                  textAlign: TextAlign.center,
                ),
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _statusBanner(status.overallStatus, sensorProvider.warnings),
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

  Widget _statusBanner(String status, List<String> warnings) {
    final isNormal = status.toLowerCase() == 'normal';
    // Edited to show the first exact warning in the banner instead of only the generic "Warning" summary.
    final displayText = !isNormal && warnings.isNotEmpty
        ? 'System Warning: ${warnings.first}'
        : 'System Status: $status';

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
        displayText,
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