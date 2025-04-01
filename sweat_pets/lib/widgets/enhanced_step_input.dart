import 'package:flutter/material.dart';
import '../screens/interface_screen.dart';
import '../widgets/step_input.dart';
import '../services/profile_service.dart';
import '../models/user_profile.dart';

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
  final TextEditingController _customStepController = TextEditingController();
  int _customSteps = 0;
  bool _showCustomInput = false;
  
  // User profile
  UserProfile? _userProfile;
  
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
    'Tennis': {
      'icon': Icons.sports_tennis,
      'color': Colors.lime,
      'steps': 3600,
      'description': '1 hour',
    },
    'Yoga': {
      'icon': Icons.self_improvement,
      'color': Colors.purple,
      'steps': 1200,
      'description': '1 hour',
    },
    'Swimming': {
      'icon': Icons.pool,
      'color': Colors.lightBlue,
      'steps': 2500,
      'description': '30 minutes',
    },
    'Basketball': {
      'icon': Icons.sports_basketball,
      'color': Colors.deepOrange,
      'steps': 4000,
      'description': '1 hour',
    },
  };

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }
  
  /// Load user profile
  Future<void> _loadUserProfile() async {
    try {
      final profile = await UserProfile.load();
      setState(() {
        _userProfile = profile;
      });
    } catch (e) {
      debugPrint('Error loading user profile: $e');
    }
  }

  @override
  void dispose() {
    _customStepController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Dark theme colors
    const Color kCardColor = Color(0xFF2C2C2C);
    const Color kAccentColor = Color(0xFF38B6FF);
    const Color kTextColor = Colors.white;
    const Color kTextSecondaryColor = Color(0xFFAAAAAA);
    const Color kButtonColor = Color(0xFF3A3A3A);
    const Color kDangerColor = Color(0xFFE53935); // Red for remove/reset actions
    
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title and description
            const Text(
              'Add Steps Manually',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: kTextColor,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Choose a preset or enter custom steps',
              style: TextStyle(
                fontSize: 14,
                color: kTextSecondaryColor,
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Preset buttons in a grid
            GridView.count(
              crossAxisCount: 3,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 2.5,
              children: _presets.map((steps) {
                return _buildPresetButton(context, steps, kAccentColor);
              }).toList(),
            ),
            
            const SizedBox(height: 12),
            
            // Button to show/hide custom input
            InkWell(
              onTap: () {
                setState(() {
                  _showCustomInput = !_showCustomInput;
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                decoration: BoxDecoration(
                  color: kButtonColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Custom Steps',
                      style: TextStyle(
                        fontSize: 16,
                        color: kTextColor,
                      ),
                    ),
                    Icon(
                      _showCustomInput ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                      color: kTextColor,
                    ),
                  ],
                ),
              ),
            ),
            
            // Custom input (conditionally shown)
            if (_showCustomInput)
              Container(
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: kButtonColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    TextField(
                      controller: _customStepController,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(color: kTextColor),
                      decoration: const InputDecoration(
                        labelText: 'Enter steps',
                        labelStyle: TextStyle(color: kTextSecondaryColor),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: kTextSecondaryColor),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: kAccentColor),
                        ),
                      ),
                      onChanged: (value) {
                        setState(() {
                          _customSteps = int.tryParse(value) ?? 0;
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kAccentColor,
                        foregroundColor: Colors.white,
                        minimumSize: const Size.fromHeight(50),
                      ),
                      onPressed: _customSteps > 0
                          ? () {
                              _addSteps(_customSteps);
                              _customStepController.clear();
                              setState(() {
                                _customSteps = 0;
                              });
                            }
                          : null,
                      child: const Text('Add Custom Steps'),
                    ),
                  ],
                ),
              ),
            
            const SizedBox(height: 24),
            
            // Activity-based step estimates
            const Text(
              'Activities',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: kTextColor,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Add steps based on activities',
              style: TextStyle(
                fontSize: 14,
                color: kTextSecondaryColor,
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Activity cards
            ..._activities.entries.map((entry) {
              final activity = entry.key;
              final data = entry.value;
              final icon = data['icon'] as IconData;
              final color = data['color'] as Color;
              final steps = data['steps'] as int;
              final description = data['description'] as String;
              
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: kButtonColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: color.withOpacity(0.3)),
                ),
                child: InkWell(
                  onTap: () => _addSteps(steps),
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(25),
                          ),
                          child: Icon(
                            icon,
                            color: color,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                activity,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: kTextColor,
                                ),
                              ),
                              Text(
                                description,
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: kTextSecondaryColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '$steps',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: color,
                              ),
                            ),
                            const Text(
                              'steps',
                              style: TextStyle(
                                fontSize: 12,
                                color: kTextSecondaryColor,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          Icons.add_circle,
                          color: color,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
            
            const SizedBox(height: 24),
            
            // Management actions (Remove and Reset)
            const Text(
              'Step Management',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: kTextColor,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Remove steps or reset your progress',
              style: TextStyle(
                fontSize: 14,
                color: kTextSecondaryColor,
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Remove steps section
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: kButtonColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: kDangerColor.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Remove Steps',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: kDangerColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Subtract steps from your daily count',
                    style: TextStyle(
                      fontSize: 14,
                      color: kTextSecondaryColor,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: kTextColor),
                    decoration: const InputDecoration(
                      labelText: 'Steps to remove',
                      labelStyle: TextStyle(color: kTextSecondaryColor),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: kTextSecondaryColor),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: kDangerColor),
                      ),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _customSteps = int.tryParse(value) ?? 0;
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kDangerColor,
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(40),
                    ),
                    onPressed: _customSteps > 0
                        ? () {
                            _showConfirmDialog(
                              context,
                              'Remove Steps',
                              'Are you sure you want to remove $_customSteps steps?',
                              () => _removeSteps(_customSteps),
                            );
                          }
                        : null,
                    child: const Text('Remove Steps'),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Reset buttons
            Row(
              children: [
                Expanded(
                  child: _buildResetButton(
                    context,
                    'Reset Daily Steps',
                    'This will reset your daily steps to zero, but keep your total steps and history.',
                    _resetDaily,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildResetButton(
                    context,
                    'Reset Pet Completely',
                    'This will completely reset your pet and all progress. This cannot be undone!',
                    _resetComplete,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPresetButton(BuildContext context, int steps, Color color) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: color.withOpacity(0.2),
        foregroundColor: color,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: color.withOpacity(0.5)),
        ),
      ),
      onPressed: () => _addSteps(steps),
      child: Text('$steps'),
    );
  }
  
  Widget _buildResetButton(BuildContext context, String title, String message, VoidCallback onConfirm) {
    // Dark theme colors
    const Color kDangerColor = Color(0xFFE53935);
    
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: kDangerColor.withOpacity(0.2),
        foregroundColor: kDangerColor,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: kDangerColor.withOpacity(0.5)),
        ),
        padding: const EdgeInsets.symmetric(vertical: 12),
      ),
      onPressed: () => _showConfirmDialog(context, title, message, onConfirm),
      child: Text(
        title,
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 14),
      ),
    );
  }
  
  void _showConfirmDialog(BuildContext context, String title, String message, VoidCallback onConfirm) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2C2C2C),
        title: Text(
          title,
          style: const TextStyle(color: Colors.white),
        ),
        content: Text(
          message,
          style: const TextStyle(color: Color(0xFFAAAAAA)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              onConfirm();
            },
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFFE53935),
            ),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }

  /// Adds the steps and calls the callback
  Future<void> _addSteps(int steps) async {
    // For backward compatibility, still call the original callback
    widget.onStepsAdded(steps);
    
    // Use the profile service to add manual steps
    await addManualStepsToProfile(steps);
    
    // Reload the profile to get updated data
    _loadUserProfile();
    
    // Show a snackbar to confirm
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Added $steps steps manually'),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  /// Removes steps from the profile
  Future<void> _removeSteps(int steps) async {
    // For backward compatibility
    widget.onStepsAdded(-steps);
    
    // Use the profile service to remove steps
    await removeStepsFromProfile(steps);
    
    // Reload the profile
    _loadUserProfile();
    
    // Show confirmation
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Removed $steps steps'),
        backgroundColor: Colors.orange,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  /// Reset daily steps
  Future<void> _resetDaily() async {
    // For backward compatibility
    widget.onStepsAdded(-99999);
    
    // Use the profile service to reset daily steps
    await resetDailySteps();
    
    // Reload the profile
    _loadUserProfile();
    
    // Show confirmation
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Reset daily steps'),
        backgroundColor: Colors.orange,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  /// Reset everything
  Future<void> _resetComplete() async {
    // For backward compatibility
    widget.onStepsAdded(-999999);
    
    // Use the profile service to reset everything
    await resetComplete();
    
    // Reload the profile
    _loadUserProfile();
    
    // Show confirmation
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Reset pet completely'),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 2),
      ),
    );
  }
} 