import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/plant_profile.dart';
import '../providers/plant_provider.dart';

class CreatePlantScreen extends StatefulWidget {
  final PlantProfile? existingPlant;

  const CreatePlantScreen({super.key, this.existingPlant});

  @override
  State<CreatePlantScreen> createState() => _CreatePlantScreenState();
}

class _CreatePlantScreenState extends State<CreatePlantScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController nameController;
  late final TextEditingController phMinController;
  late final TextEditingController phMaxController;
  late final TextEditingController tempMinController;
  late final TextEditingController tempMaxController;
  late final TextEditingController tdsMinController;
  late final TextEditingController tdsMaxController;
  late final TextEditingController wateringCycleController;

  @override
  void initState() {
    super.initState();
    final plant = widget.existingPlant;

    nameController = TextEditingController(text: plant?.name ?? '');
    phMinController = TextEditingController(text: plant?.phMin.toString() ?? '');
    phMaxController = TextEditingController(text: plant?.phMax.toString() ?? '');
    tempMinController = TextEditingController(text: plant?.tempMin.toString() ?? '');
    tempMaxController = TextEditingController(text: plant?.tempMax.toString() ?? '');
    tdsMinController = TextEditingController(text: plant?.tdsMin.toString() ?? '');
    tdsMaxController = TextEditingController(text: plant?.tdsMax.toString() ?? '');
    wateringCycleController = TextEditingController(
      text: plant?.wateringCycleHours.toString() ?? '',
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existingPlant != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Edit Plant Profile' : 'Create Plant Profile'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              _field(nameController, 'Plant Name', isText: true),
              _field(phMinController, 'pH Min'),
              _field(phMaxController, 'pH Max'),
              _field(tempMinController, 'Temperature Min'),
              _field(tempMaxController, 'Temperature Max'),
              _field(tdsMinController, 'TDS Min'),
              _field(tdsMaxController, 'TDS Max'),
              _field(wateringCycleController, 'Watering Cycle (hours)'),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async {
                  if (!_formKey.currentState!.validate()) return;

                  final old = widget.existingPlant;

                  final plant = PlantProfile(
                    // Edited to preserve the Firebase profile key when updating an existing cloud profile.
                    id: old?.id,
                    name: nameController.text.trim(),
                    phMin: double.parse(phMinController.text),
                    phMax: double.parse(phMaxController.text),
                    tempMin: double.parse(tempMinController.text),
                    tempMax: double.parse(tempMaxController.text),
                    tdsMin: double.parse(tdsMinController.text),
                    tdsMax: double.parse(tdsMaxController.text),
                    wateringCycleHours: int.parse(wateringCycleController.text),
                    isActive: old?.isActive ?? false,
                  );

                  // Edited to route saves through PlantProvider so profiles persist under the signed-in user's account.
                  if (isEdit) {
                    await context.read<PlantProvider>().updatePlant(plant);
                  } else {
                    await context.read<PlantProvider>().addPlant(plant);
                  }

                  if (!mounted) return;
                  Navigator.pop(context);
                },
                child: Text(isEdit ? 'Save Changes' : 'Save Profile'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _field(TextEditingController controller, String label, {bool isText = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        keyboardType: isText
            ? TextInputType.text
            : const TextInputType.numberWithOptions(decimal: true),
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        validator: (value) {
          if (value == null || value.trim().isEmpty) return 'Required';
          return null;
        },
      ),
    );
  }
}