import 'package:flutter/material.dart';
import '../services/health_service.dart';
import '../screens/interface_screen.dart';

/// A widget that fetches step data from health services
class HealthStepInput extends StatefulWidget {
  /// Callback when steps are fetched and ready to be added
  final Function(int) onStepsAdded;

  /// Debug mode
  final bool debugMode;

  /// Creates a health step input widget
  const HealthStepInput({
    Key? key,
    required this.onStepsAdded,
    this.debugMode = false,
  }) : super(key: key);

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
  int _stepsCount = 0;
  int _flightsClimbed = 0;
  double _distanceWalkingRunning = 0.0; // in meters
  
  /// Whether permissions are granted
  bool _hasPermissions = false;
  
  /// Debug mode text controller
  final TextEditingController _stepsController = TextEditingController(text: '100');
  
  /// Debug mode toggle
  bool _debugMode = false;
  
  /// Health connection status
  String _connectionStatus = 'Not connected';
  
  /// Manual steps input
  int _manualSteps = 100;
  
  @override
  void initState() {
    super.initState();
    _debugMode = widget.debugMode;
    _connectToHealth();
  }
  
  @override
  void dispose() {
    _stepsController.dispose();
    super.dispose();
  }
  
  /// Connect to health services
  Future<void> _connectToHealth() async {
    if (_isLoading) return;
    
    setState(() {
      _isLoading = true;
      _connectionStatus = 'Connecting...';
    });
    
    try {
      // First, check if we already have permissions
      _hasPermissions = await _healthService.hasPermissions();
      
      if (!_hasPermissions) {
        // If we don't have permissions, request them
        debugPrint('🩺 No health permissions, requesting...');
        
        // Request permissions with a button click listener
        final permissionGranted = await _healthService.requestPermissions();
        
        if (!permissionGranted) {
          setState(() {
            _connectionStatus = 'Permission denied';
            _isLoading = false;
            _hasPermissions = false;
          });
          return;
        }
        
        // Double-check permissions after request
        _hasPermissions = await _healthService.hasPermissions();
        if (!_hasPermissions) {
          debugPrint('🩺 Permission request succeeded but permissions check failed');
          // We'll continue anyway in case we can still get data
        }
      }
      
      // Try to fetch health data
      final metrics = await _healthService.getHealthMetricsToday();
      
      setState(() {
        _stepsCount = metrics['steps'] as int;
        _flightsClimbed = metrics['flightsClimbed'] as int;
        _distanceWalkingRunning = metrics['distanceWalkingRunning'] as double;
        _connectionStatus = _hasPermissions ? 'Connected' : 'Partial connection';
        _isLoading = false;
      });
      
      // Show a success message if we got steps
      if (_stepsCount > 0) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Found $_stepsCount steps today from Health app!'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      debugPrint('🩺 Error in health connection: $e');
      setState(() {
        _connectionStatus = 'Error: ${e.toString()}';
        _isLoading = false;
      });
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error connecting to Health: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }
  
  Future<void> _refreshHealthData() async {
    if (_isLoading) return;
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      final metrics = await _healthService.getHealthMetricsToday();
      
      setState(() {
        _stepsCount = metrics['steps'] as int;
        _flightsClimbed = metrics['flightsClimbed'] as int;
        _distanceWalkingRunning = metrics['distanceWalkingRunning'] as double;
        _isLoading = false;
      });
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Health data refreshed: $_stepsCount steps'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 1),
        ),
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error refreshing health data'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          Padding(
            padding: const EdgeInsets.only(left: 8, bottom: 12),
            child: Text(
              'Health App Integration',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: kTextColor,
              ),
            ),
          ),
          
          // Debug Mode Toggle (only in dev)
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                'Debug Mode',
                style: TextStyle(
                  fontSize: 12,
                  color: kTextSecondaryColor,
                ),
              ),
              Switch(
                value: _debugMode,
                activeColor: kAccentColor,
                onChanged: (value) {
                  setState(() {
                    _debugMode = value;
                  });
                },
              ),
            ],
          ),
          
          // Health Connection Status Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: kCardColor,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Health Connection',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: kTextColor,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getStatusColor().withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _connectionStatus,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: _getStatusColor(),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'Connect to Apple Health to automatically track your steps and feed your pet.',
                  style: TextStyle(
                    fontSize: 14,
                    color: kTextSecondaryColor,
                  ),
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: _isLoading ? null : _connectToHealth,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kAccentColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    minimumSize: const Size(double.infinity, 45),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Connect to Health'),
                ),
                if (_connectionStatus == 'Permission denied')
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      'Please go to Settings > Privacy & Health > Health > SweatPet to enable permissions',
                      style: TextStyle(
                        color: Colors.red,
                        fontSize: 12,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          
          // Add Health Steps Button Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: kCardColor,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Today\'s Stats',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: kTextColor,
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.refresh,
                        color: kAccentColor,
                      ),
                      onPressed: _isLoading ? null : _refreshHealthData,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                
                // Stats Rows
                _buildStatRow('Steps', '$_stepsCount', Icons.directions_walk, Colors.blue),
                _buildStatRow('Floors', '$_flightsClimbed', Icons.stairs, Colors.orange),
                _buildStatRow(
                  'Distance', 
                  '${(_distanceWalkingRunning / 1000).toStringAsFixed(1)} km', 
                  Icons.straighten, 
                  Colors.green
                ),
                
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _stepsCount > 0 
                      ? () {
                          widget.onStepsAdded(_stepsCount);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Added $_stepsCount steps to your pet!'),
                              backgroundColor: Colors.green,
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kCardColor,
                    foregroundColor: kAccentColor,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    side: BorderSide(color: kAccentColor),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    minimumSize: const Size(double.infinity, 45),
                    disabledBackgroundColor: kCardColor.withOpacity(0.7),
                    disabledForegroundColor: kTextSecondaryColor,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_circle_outline, color: _stepsCount > 0 ? kAccentColor : kTextSecondaryColor),
                      const SizedBox(width: 8),
                      Text(
                        'Add Health Steps to Pet',
                        style: TextStyle(
                          color: _stepsCount > 0 ? kAccentColor : kTextSecondaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                if (_stepsCount == 0 && _connectionStatus == 'Connected')
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      'No steps recorded today in Health app yet. Try taking a walk!',
                      style: TextStyle(
                        color: Colors.amber,
                        fontSize: 12,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          
          // Debug Input (only in debug mode)
          if (_debugMode) ...[
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: kCardColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.amber.withOpacity(0.5),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.bug_report,
                        color: Colors.amber,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Debug Mode',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.amber,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _stepsController,
                    keyboardType: TextInputType.number,
                    style: TextStyle(color: kTextColor),
                    decoration: InputDecoration(
                      labelText: 'Enter steps manually',
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
                    onChanged: (value) {
                      setState(() {
                        _manualSteps = int.tryParse(value) ?? 100;
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () {
                      widget.onStepsAdded(_manualSteps);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Added $_manualSteps steps to your pet (debug)!'),
                          backgroundColor: Colors.amber,
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      minimumSize: const Size(double.infinity, 45),
                    ),
                    child: const Text('Add Steps (Debug)'),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
  
  Widget _buildStatRow(String label, String value, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
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
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: kTextSecondaryColor,
                    fontSize: 14,
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    color: kTextColor,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Color _getStatusColor() {
    switch (_connectionStatus) {
      case 'Connected':
        return Colors.green;
      case 'Connecting...':
        return Colors.amber;
      case 'Not connected':
        return kTextSecondaryColor;
      case 'Partial connection':
        return Colors.orange;
      default:
        return Colors.red;
    }
  }
} 