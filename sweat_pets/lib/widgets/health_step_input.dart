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
  
  /// Today's health metrics
  int _todaySteps = 0;
  int _flightsClimbed = 0;
  double _distanceWalkingRunning = 0.0; // in meters
  
  /// Whether permissions are granted
  bool _hasPermissions = false;
  
  /// Debug mode text controller
  final TextEditingController _debugStepsController = TextEditingController();
  
  /// Debug mode toggle
  bool _debugMode = false;
  
  @override
  void initState() {
    super.initState();
    _checkPermissionsAndFetchData();
  }
  
  @override
  void dispose() {
    _debugStepsController.dispose();
    super.dispose();
  }
  
  /// Check permissions and fetch data if available
  Future<void> _checkPermissionsAndFetchData() async {
    debugPrint('🩺 Checking health permissions on startup');
    final hasPermissions = await _healthService.hasPermissions();
    setState(() {
      _hasPermissions = hasPermissions;
    });
    
    if (hasPermissions) {
      debugPrint('🩺 Health permissions already granted, fetching data');
      _fetchHealthData();
    } else {
      debugPrint('🩺 No health permissions on startup');
    }
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
        _fetchHealthData();
      }
    } catch (e) {
      debugPrint('🩺 Error in _requestPermissions: $e');
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error requesting permissions: $e';
      });
    }
  }
  
  /// Fetch health data from health services
  Future<void> _fetchHealthData() async {
    if (!_hasPermissions) {
      debugPrint('🩺 Cannot fetch health data - no permissions');
      return;
    }
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    debugPrint('🩺 Fetching health data...');
    try {
      // Force permission check again to ensure we have access
      final hasPermissions = await _healthService.hasPermissions();
      if (!hasPermissions) {
        debugPrint('🩺 Lost health permissions, requesting again');
        final granted = await _healthService.requestPermissions();
        if (!granted) {
          setState(() {
            _isLoading = false;
            _errorMessage = 'Health permissions were denied';
          });
          return;
        }
      }
      
      final metrics = await _healthService.getHealthMetricsToday();
      debugPrint('🩺 Got health metrics: $metrics');
      
      setState(() {
        _todaySteps = metrics['steps'] as int;
        _flightsClimbed = metrics['flightsClimbed'] as int;
        _distanceWalkingRunning = metrics['distanceWalkingRunning'] as double;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('🩺 Error in _fetchHealthData: $e');
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error fetching health data: $e';
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
  
  /// Format distance in a readable way (convert to km if large enough)
  String _formatDistance(double meters) {
    if (meters >= 1000) {
      return '${(meters / 1000).toStringAsFixed(2)} km';
    } else {
      return '${meters.toStringAsFixed(0)} m';
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
      child: Column(
        children: [
          // Debug mode toggle
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              const Text('Debug Mode'),
              Switch(
                value: _debugMode,
                onChanged: (value) {
                  setState(() {
                    _debugMode = value;
                    if (value && !_hasPermissions) {
                      _todaySteps = 0;
                    }
                  });
                },
              ),
            ],
          ),
          
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
                
                // Debug mode input
                if (_debugMode) ...[
                  TextField(
                    controller: _debugStepsController,
                    decoration: const InputDecoration(
                      labelText: 'Enter step count',
                      hintText: 'Enter your actual step count',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      if (value.isNotEmpty) {
                        setState(() {
                          _todaySteps = int.tryParse(value) ?? 0;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton(
                        onPressed: () {
                          final steps = int.tryParse(_debugStepsController.text) ?? 0;
                          if (steps > 0) {
                            setState(() {
                              _todaySteps = steps;
                            });
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Set Steps'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ] else if (!_hasPermissions) ...[
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
                  // Health data display
                  Column(
                    children: [
                      // Steps
                      const Text(
                        'Today\'s Activity',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      
                      // Health metrics in a card layout
                      Row(
                        children: [
                          // Steps metric
                          Expanded(
                            child: _buildMetricCard(
                              Icons.directions_walk,
                              'Steps',
                              _todaySteps.toString(),
                              Colors.blue,
                            ),
                          ),
                          const SizedBox(width: 12),
                          
                          // Flights climbed metric
                          Expanded(
                            child: _buildMetricCard(
                              Icons.stairs,
                              'Flights',
                              _flightsClimbed.toString(),
                              Colors.orange,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      
                      // Distance metric
                      _buildMetricCard(
                        Icons.straighten,
                        'Distance',
                        _formatDistance(_distanceWalkingRunning),
                        Colors.green,
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Buttons
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          // Refresh button
                          ElevatedButton.icon(
                            onPressed: _isLoading ? null : _fetchHealthData,
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
                  ),
                ],
                
                // Always show Add Steps button in debug mode
                if (_debugMode && _todaySteps > 0) ...[
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _addStepsToGame,
                    icon: const Icon(Icons.add_circle_outline),
                    label: const Text('Add Steps to Pet'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                    ),
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
  
  /// Build a card displaying a health metric
  Widget _buildMetricCard(IconData icon, String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              color: color.withOpacity(0.8),
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
} 