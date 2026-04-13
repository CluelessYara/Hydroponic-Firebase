import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/plant_provider.dart';
import 'providers/sensor_provider.dart';
import 'screens/empty_state_screen.dart';
import 'screens/dashboard_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => PlantProvider()..loadPlants()),
        ChangeNotifierProvider(create: (_) => SensorProvider()),
      ],
      child: const MaterialApp(
        debugShowCheckedModeBanner: false,
        home: RootScreen(),
      ),
    );
  }
}

class RootScreen extends StatefulWidget {
  const RootScreen({super.key});

  @override
  State<RootScreen> createState() => _RootScreenState();
}

class _RootScreenState extends State<RootScreen> {
  int? _lastPlantId;

  @override
  Widget build(BuildContext context) {
    final plantProvider = context.watch<PlantProvider>();
    final sensorProvider = context.read<SensorProvider>();
    final activePlant = plantProvider.activePlant;

    if (activePlant != null && activePlant.id != _lastPlantId) {
      _lastPlantId = activePlant.id;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        sensorProvider.startListening(activePlant);
      });
    }

    if (plantProvider.hasPlants) {
      return const DashboardScreen();
    } else {
      return const EmptyStateScreen();
    }
  }
}