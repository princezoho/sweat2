import 'package:flutter/material.dart';
import 'package:sweat_pets/services/health_service.dart';

/// A widget that fetches step data from health services
class HealthStepInput extends StatefulWidget {
  /// Callback when steps are fetched and ready to be added
  final Function(int steps) onStepsAdded;

  /// Creates a health step input widget
  const HealthStepInput({
    super.key,
    required this.onStepsAdded,
  });

  @override
  State<HealthStepInput> createState() => _HealthStepInputState();
}

class _HealthStepInputState extends State<HealthStepInput> {
  /// Health service for step data
  final HealthService _healthService = HealthService();
  
  /// Loading state
  bool _isLoading = false;
  
  /// Error message
  String? _errorMessage;
  
  /// Today's step count
  int _todaySteps = 0;
  
  /// Whether permissions are granted
  bool _hasPermissions = false;
  
  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }
  
  /// Check if health permissions are granted
  Future<void> _checkPermissions() async {
    final hasPermissions = await _healthService.hasPermissions();
    setState(() {
      _hasPermissions = hasPermissions;
    });
  }
  
  /// Request health permissions
  Future<void> _requestPermissions() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      final granted = await _healthService.requestPermissions();
      setState(() {
        _hasPermissions = granted;
        _isLoading = false;
        if (!granted) {
          _errorMessage = 'Health permissions were denied';
        }
      });
      
      if (granted) {
        _fetchStepData();
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error requesting permissions: $e';
      });
    }
  }
  
  /// Fetch step data from health services
  Future<void> _fetchStepData() async {
    if (!_hasPermissions) {
      return;
    }
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      final steps = await _healthService.getStepsToday();
      setState(() {
        _todaySteps = steps;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error fetching step data: $e';
      });
    }
  }
  
  /// Add steps to the game
  void _addStepsToGame() {
    if (_todaySteps > 0) {
      widget.onStepsAdded(_todaySteps);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Added $_todaySteps steps to your pet!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
      child: Column(
        children: [
          // Health connection card
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Health icon and title
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.favorite,
                        color: Colors.red,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Health Integration',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                // Permission status and controls
                if (!_hasPermissions) ...[
                  const Text(
                    'Connect to Health app to automatically track your steps',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _requestPermissions,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text('Connect to Health'),
                  ),
                ] else ...[
                  // Step data display
                  Text(
                    'Today\'s Steps: $_todaySteps',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  
                  // Refresh and add buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // Refresh button
                      ElevatedButton.icon(
                        onPressed: _isLoading ? null : _fetchStepData,
                        icon: _isLoading
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  color: Colors.blue,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.refresh),
                        label: const Text('Refresh'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey.shade200,
                          foregroundColor: Colors.blue,
                        ),
                      ),
                      
                      // Add steps button
                      ElevatedButton.icon(
                        onPressed: _todaySteps > 0 ? _addStepsToGame : null,
                        icon: const Icon(Icons.add_circle_outline),
                        label: const Text('Add Steps'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ],
                
                // Error message
                if (_errorMessage != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    _errorMessage!,
                    style: const TextStyle(
                      color: Colors.red,
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
} 