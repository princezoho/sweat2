import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/step_counter.dart';

/// Widget for manually inputting steps
class StepInput extends StatefulWidget {
  /// Called when steps are added
  final void Function(int steps) onStepsAdded;

  /// Current step count to display
  final int currentSteps;

  const StepInput({
    super.key,
    required this.onStepsAdded,
    required this.currentSteps,
  });

  @override
  State<StepInput> createState() => _StepInputState();
}

class _StepInputState extends State<StepInput> {
  final _controller = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _addSteps() {
    if (_formKey.currentState?.validate() ?? false) {
      final steps = int.parse(_controller.text);
      widget.onStepsAdded(steps);
      _controller.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Daily Steps: ${widget.currentSteps}',
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _controller,
                decoration: const InputDecoration(
                  labelText: 'Add Steps',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                ],
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a number';
                  }
                  final steps = int.tryParse(value);
                  if (steps == null || steps <= 0) {
                    return 'Please enter a positive number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: _addSteps,
                child: const Text('Add Steps'),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 