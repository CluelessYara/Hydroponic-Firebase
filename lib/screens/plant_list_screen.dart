import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/plant_provider.dart';
import 'create_plant_screen.dart';

class PlantListScreen extends StatelessWidget {
  const PlantListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PlantProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Plant Profiles')),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CreatePlantScreen()),
          );
        },
        child: const Icon(Icons.add),
      ),
      body: ListView.builder(
        itemCount: provider.plants.length,
        itemBuilder: (context, index) {
          final plant = provider.plants[index];

          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: ListTile(
              title: Text(plant.name),
              subtitle: Text(
                'pH ${plant.phMin}-${plant.phMax} | Temp ${plant.tempMin}-${plant.tempMax} | TDS ${plant.tdsMin}-${plant.tdsMax} | Every ${plant.wateringCycleHours}h',
              ),
              leading: Icon(
                plant.isActive ? Icons.check_circle : Icons.eco_outlined,
              ),
              onTap: () async {
                if (plant.id != null) {
                  await context.read<PlantProvider>().setActivePlant(plant.id!);
                  if (context.mounted) Navigator.pop(context);
                }
              },
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => CreatePlantScreen(existingPlant: plant),
                        ),
                      );
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () async {
                      if (plant.id != null) {
                        await context.read<PlantProvider>().deletePlant(plant.id!);
                      }
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}