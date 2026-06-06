import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';

import 'firebase_options.dart';
import 'providers/app_auth_provider.dart';
import 'providers/plant_provider.dart';
import 'providers/sensor_provider.dart';
import 'screens/auth_screen.dart';
import 'screens/empty_state_screen.dart';
import 'screens/dashboard_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AppAuthProvider(),
      child: const AppShell(),
    );
  }
}

class AppShell extends StatelessWidget {
  const AppShell({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AppAuthProvider>();
    final user = authProvider.user;

    final Widget home;
    if (authProvider.isLoading) {
      home = const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    } else if (user == null) {
      home = const AuthScreen();
    } else {
      home = const RootScreen();
    }

    final app = MaterialApp(
      debugShowCheckedModeBanner: false,
      home: home,
    );

    if (user == null || authProvider.isLoading) {
      return app;
    }

    // Keep user-scoped providers above MaterialApp/Navigator so pushed routes
    // such as CreatePlantScreen can read the same PlantProvider instance.
    return MultiProvider(
      key: ValueKey(user.uid),
      providers: [
        ChangeNotifierProvider(
          create: (_) => PlantProvider(uid: user.uid)..loadPlants(),
        ),
        ChangeNotifierProvider(
          create: (_) => SensorProvider(uid: user.uid)..startListening(),
        ),
      ],
      child: app,
    );
  }
}

class RootScreen extends StatelessWidget {
  const RootScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final plantProvider = context.watch<PlantProvider>();

    if (plantProvider.isLoading && !plantProvider.hasPlants) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (plantProvider.hasPlants) {
      return const DashboardScreen();
    } else {
      return const EmptyStateScreen();
    }
  }
}
