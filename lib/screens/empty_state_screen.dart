import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import 'create_plant_screen.dart';

class EmptyStateScreen extends StatelessWidget {
  const EmptyStateScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hydroponic Monitor'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Sign out',
            onPressed: () {
              // Edited to let users leave an empty account and sign into a different Firebase account.
              context.read<AppAuthProvider>().signOut();
            },
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.eco, size: 80),
              const SizedBox(height: 20),
              const Text(
                'No plant profiles found',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              const Text(
                // Edited to clarify that profiles are now stored under the signed-in Firebase account.
                'Create your first cloud plant profile for this account to start monitoring your hydroponic system.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const CreatePlantScreen(),
                    ),
                  );
                },
                child: const Text('Create Plant Profile'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}