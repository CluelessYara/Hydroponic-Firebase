import 'package:flutter/material.dart';
import 'create_plant_screen.dart';

class EmptyStateScreen extends StatelessWidget {
  const EmptyStateScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                'Create your first plant profile to start monitoring your hydroponic system.',
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