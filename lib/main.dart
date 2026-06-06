import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';

import 'firebase_options.dart';
import 'providers/auth_provider.dart';
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
    return MultiProvider(
      providers: [
        // Edited to expose Firebase Auth state to every screen before profile or sensor providers are used.
        ChangeNotifierProvider(create: (_) => AppAuthProvider()),
        // Edited to keep PlantProvider available globally while binding it to the signed-in user in AuthGate.
        ChangeNotifierProvider(create: (_) => PlantProvider()),
        // Edited to keep SensorProvider available globally while binding its RTDB stream to the signed-in user in AuthGate.
        ChangeNotifierProvider(create: (_) => SensorProvider()),
      ],
      child: const MaterialApp(
        debugShowCheckedModeBanner: false,
        home: AuthGate(),
      ),
    );
  }
}

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  String? _boundUid;

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AppAuthProvider>();
    final user = authProvider.user;

    if (authProvider.isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (user == null) {
      if (_boundUid != null) {
        _boundUid = null;
        // Edited to defer provider clearing until after build so sign-out does not notify listeners mid-build.
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          context.read<PlantProvider>().clearForSignedOutUser();
          context.read<SensorProvider>().stopListening();
        });
      }
      return const AuthScreen();
    }

    if (_boundUid != user.uid) {
      _boundUid = user.uid;
      // Edited to bind all providers after auth so every screen reads/writes only this user's RTDB branch.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        context.read<PlantProvider>().bindToUser(user.uid);
        context.read<SensorProvider>().startListening(user.uid);
      });
    }

    return const RootScreen();
  }
}

class RootScreen extends StatelessWidget {
  const RootScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final plantProvider = context.watch<PlantProvider>();

    if (plantProvider.isLoading) {
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
