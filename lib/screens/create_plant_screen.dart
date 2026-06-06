import 'dart:async';

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
  static const Duration _slowSaveWarningDelay = Duration(seconds: 8);
  static const Duration _screenSaveTimeout = Duration(seconds: 35);

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
  String? _infoMessage;
  String? _successMessage;
  Timer? _slowSaveTimer;
  Stopwatch? _saveStopwatch;

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
    _slowSaveTimer?.cancel();
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
              if (_infoMessage != null) ...[
                _messageBanner(_infoMessage!, Colors.orange),
                const SizedBox(height: 12),
              ],
              if (_successMessage != null) ...[
                _messageBanner(_successMessage!, Colors.green),
                const SizedBox(height: 12),
              ],
              if (_errorMessage != null) ...[
                _messageBanner(_errorMessage!, Colors.red),
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
      _infoMessage = 'Saving plant profile to Firebase...';
      _successMessage = null;
    });

    _saveStopwatch = Stopwatch()..start();
    _slowSaveTimer?.cancel();
    _slowSaveTimer = Timer(_slowSaveWarningDelay, () {
      if (!mounted || !_isSaving) return;
      debugPrint(
        '[CreatePlantScreen] Save still waiting after '
        '${_slowSaveWarningDelay.inSeconds}s',
      );
      setState(() {
        _infoMessage = 'Still saving... Firebase is taking longer than expected. '
            'If this does not finish soon, check database rules and network.';
      });
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

    final action = isEdit ? 'update' : 'create';
    debugPrint(
      '[CreatePlantScreen] Save started action=$action '
      'name=${plant.name} id=${plant.id}',
    );

    try {
      final provider = context.read<PlantProvider>();
      final saveFuture =
          isEdit ? provider.updatePlant(plant) : provider.addPlant(plant);
      await saveFuture.timeout(_screenSaveTimeout);

      final elapsed = _saveStopwatch?.elapsed.inMilliseconds ?? 0;
      debugPrint('[CreatePlantScreen] Save succeeded in ${elapsed}ms');

      if (!mounted) return;
      _slowSaveTimer?.cancel();
      setState(() {
        _isSaving = false;
        _infoMessage = null;
        _errorMessage = null;
        _successMessage = 'Saved successfully.';
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Plant profile saved successfully.')),
      );

      await Future<void>.delayed(const Duration(milliseconds: 700));
      if (!mounted) return;
      Navigator.pop(context);
    } on TimeoutException catch (error, stackTrace) {
      debugPrint('[CreatePlantScreen] Save timed out: $error');
      debugPrintStack(stackTrace: stackTrace);
      _showSaveError(
        'Saving is taking too long. Check your internet connection, Firebase '
        'Realtime Database rules, and that you deployed rules to the correct project.',
      );
    } catch (error, stackTrace) {
      debugPrint('[CreatePlantScreen] Save failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      if (!mounted) return;
      final providerError = context.read<PlantProvider>().error;
      _showSaveError(
        providerError ??
            'Unable to save this plant profile. Check your Firebase connection '
                'and try again.',
      );
    } finally {
      _slowSaveTimer?.cancel();
      _saveStopwatch?.stop();
    }
  }

  void _showSaveError(String message) {
    if (!mounted) return;
    setState(() {
      _errorMessage = message;
      _infoMessage = null;
      _successMessage = null;
      _isSaving = false;
    });
  }

  Widget _messageBanner(String message, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        border: Border.all(color: color),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        message,
        style: TextStyle(color: color),
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
