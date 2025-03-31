import 'package:flutter/material.dart';
import '../screens/interface_screen.dart';

/// A widget for manual step input with presets
class EnhancedStepInput extends StatefulWidget {
  /// Callback when steps are added
  final Function(int) onStepsAdded;

  /// Creates an enhanced step input widget
  const EnhancedStepInput({
    Key? key,
    required this.onStepsAdded,
  }) : super(key: key);

  @override
  State<EnhancedStepInput> createState() => _EnhancedStepInputState();
}

class _EnhancedStepInputState extends State<EnhancedStepInput> {
  bool _showCustomInput = false;
  final TextEditingController _customStepsController = TextEditingController(text: '1000');
  
  // Preset step values
  final List<int> _presets = [100, 500, 1000, 2000, 5000, 10000];
  
  // Activity-based step estimates
  final Map<String, Map<String, dynamic>> _activities = {
    'Walking': {
      'icon': Icons.directions_walk,
      'color': Colors.blue,
      'steps': 1500,
      'description': '15 minutes',
    },
    'Running': {
      'icon': Icons.directions_run,
      'color': Colors.orange,
      'steps': 3000,
      'description': '15 minutes',
    },
    'Hiking': {
      'icon': Icons.terrain,
      'color': Colors.green,
      'steps': 5000,
      'description': '45 minutes',
    },
    'Cycling': {
      'icon': Icons.directions_bike,
      'color': Colors.red,
      'steps': 2000,
      'description': '30 minutes',
    },
  };

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          Padding(
            padding: const EdgeInsets.only(left: 8, bottom: 8, top: 4),
            child: Text(
              'Manual Step Entry',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: kTextColor,
              ),
            ),
          ),
          
          // Description
          Padding(
            padding: const EdgeInsets.only(left: 8, right: 8, bottom: 16),
            child: Text(
              'Add steps manually to help your pet grow faster',
              style: TextStyle(
                fontSize: 14,
                color: kTextSecondaryColor,
              ),
            ),
          ),
          
          // Quick Add Section
          Padding(
            padding: const EdgeInsets.only(left: 8, bottom: 8),
            child: Text(
              'Quick Add',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: kTextColor,
              ),
            ),
          ),
          
          // Preset buttons grid
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 3,
            childAspectRatio: 2.5,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            children: _presets.map((steps) {
              return _buildPresetButton(steps);
            }).toList(),
          ),
          
          // Custom input button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: InkWell(
              onTap: () {
                setState(() {
                  _showCustomInput = !_showCustomInput;
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: kCardColor,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: kTextSecondaryColor.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Custom Steps',
                      style: TextStyle(
                        color: kTextColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Icon(
                      _showCustomInput ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                      color: kTextSecondaryColor,
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          // Custom input field (conditionally shown)
          if (_showCustomInput)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: kCardColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: _customStepsController,
                    keyboardType: TextInputType.number,
                    style: TextStyle(color: kTextColor),
                    decoration: InputDecoration(
                      labelText: 'Enter custom steps',
                      labelStyle: TextStyle(color: kTextSecondaryColor),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: kTextSecondaryColor.withOpacity(0.3)),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: kAccentColor),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      filled: true,
                      fillColor: kBackgroundColor,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () {
                      final value = int.tryParse(_customStepsController.text);
                      if (value != null && value > 0) {
                        widget.onStepsAdded(value);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kAccentColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      minimumSize: const Size(double.infinity, 45),
                    ),
                    child: const Text('Add Custom Steps'),
                  ),
                ],
              ),
            ),
          
          // Activity-based section
          Padding(
            padding: const EdgeInsets.only(left: 8, top: 16, bottom: 8),
            child: Text(
              'Add by Activity',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: kTextColor,
              ),
            ),
          ),
          
          // Activity tiles
          ..._activities.entries.map((entry) {
            return _buildActivityTile(
              entry.key,
              entry.value['description'],
              entry.value['steps'],
              entry.value['icon'],
              entry.value['color'],
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildPresetButton(int steps) {
    return InkWell(
      onTap: () {
        widget.onStepsAdded(steps);
      },
      child: Container(
        decoration: BoxDecoration(
          color: kCardColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: kTextSecondaryColor.withOpacity(0.3),
          ),
        ),
        child: Center(
          child: Text(
            '+$steps',
            style: TextStyle(
              color: kTextColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildActivityTile(
    String activity,
    String description,
    int steps,
    IconData icon,
    Color color,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: kCardColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: color,
            size: 20,
          ),
        ),
        title: Text(
          activity,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: kTextColor,
          ),
        ),
        subtitle: Text(
          description,
          style: TextStyle(
            color: kTextSecondaryColor,
            fontSize: 12,
          ),
        ),
        trailing: ElevatedButton(
          onPressed: () {
            widget.onStepsAdded(steps);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: kCardColor,
            foregroundColor: color,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            elevation: 0,
            side: BorderSide(color: color),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          ),
          child: Text('+$steps', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }
} 