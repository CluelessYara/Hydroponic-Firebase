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

  bool _isSaving = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    final plant = widget.existingPlant;

    nameController = TextEditingController(text: plant?.name ?? '');
    phMinController = TextEditingController(text: plant?.phMin.toString() ?? '');
    phMaxController = TextEditingController(text: plant?.phMax.toString() ?? '');
    tempMinController = TextEditingController(
      text: plant?.tempMin.toString() ?? '',
    );
    tempMaxController = TextEditingController(
      text: plant?.tempMax.toString() ?? '',
    );
    tdsMinController = TextEditingController(text: plant?.tdsMin.toString() ?? '');
    tdsMaxController = TextEditingController(text: plant?.tdsMax.toString() ?? '');
    wateringCycleController = TextEditingController(
      text: plant?.wateringCycleHours.toString() ?? '',
    );
  }

  @override
  void dispose() {
    nameController.dispose();
    phMinController.dispose();
    phMaxController.dispose();
    tempMinController.dispose();
    tempMaxController.dispose();
    tdsMinController.dispose();
    tdsMaxController.dispose();
    wateringCycleController.dispose();
    super.dispose();
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
              if (_errorMessage != null) ...[
                _errorBanner(_errorMessage!),
                const SizedBox(height: 12),
              ],
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: _isSaving ? null : () => _saveProfile(isEdit),
                child: _isSaving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(isEdit ? 'Save Changes' : 'Save Profile'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _saveProfile(bool isEdit) async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    final old = widget.existingPlant;

    final plant = PlantProfile(
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

    try {
      final provider = context.read<PlantProvider>();
      if (isEdit) {
        await provider.updatePlant(plant);
      } else {
        await provider.addPlant(plant);
      }

      if (!mounted) return;
      Navigator.pop(context);
    } catch (_) {
      if (!mounted) return;
      final providerError = context.read<PlantProvider>().error;
      setState(() {
        _errorMessage = providerError ??
            'Unable to save this plant profile. Check your Firebase '
                'connection and try again.';
        _isSaving = false;
      });
    }
  }

  Widget _errorBanner(String message) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.12),
        border: Border.all(color: Colors.red),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        message,
        style: const TextStyle(color: Colors.red),
      ),
    );
  }

  Widget _field(
    TextEditingController controller,
    String label, {
    bool isText = false,
  }) {
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