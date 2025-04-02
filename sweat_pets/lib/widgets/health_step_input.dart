import 'package:flutter/material.dart';
import '../services/health_service.dart';
import '../screens/interface_screen.dart';
import '../services/profile_service.dart';
import '../models/user_profile.dart';
import '../services/app_settings.dart';

// Define UI constants
const kTextColor = Colors.white;
const kTextSecondaryColor = Colors.white70;
const kAccentColor = Color(0xFF8A64FF);
const kCardColor = Color(0xFF2A2A2A);
const kProgressTrackColor = Color(0xFF3A3A3A);

/// A widget that fetches step data from health services
class HealthStepInput extends StatefulWidget {
  /// Callback when steps are fetched and ready to be added
  final Function(int) onStepsAdded;
  
  /// Current manually added steps to preserve
  final int currentManualSteps;

  /// Creates a health step input widget
  const HealthStepInput({
    Key? key,
    required this.onStepsAdded,
    this.currentManualSteps = 0,
  }) : super(key: key);

  @override
  State<HealthStepInput> createState() => _HealthStepInputState();
}

class _HealthStepInputState extends State<HealthStepInput> {
  /// Health service for step data
  final HealthService _healthService = HealthService();
  
  /// Loading state
  bool _isLoading = false;
  
  /// Today's health metrics
  int _stepsCount = 0;
  int _flightsClimbed = 0;
  double _distanceWalkingRunning = 0.0; // in meters
  
  /// Whether permissions are granted
  bool _hasPermissions = false;
  
  /// Health connection status
  String _connectionStatus = 'Not connected';
  
  /// User profile
  UserProfile? _userProfile;
  
  /// Whether we're in offline mode
  bool _isOfflineMode = false;
  
  @override
  void initState() {
    super.initState();
    _loadUserProfile();
    _checkOfflineMode();
    if (!_isOfflineMode) {
      _connectToHealth();
    } else {
      _connectionStatus = 'Offline Mode';
    }
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
  
  /// Check if we're in offline mode
  Future<void> _checkOfflineMode() async {
    await AppSettings.init(); // Make sure settings are initialized
    setState(() {
      _isOfflineMode = AppSettings.offlineMode;
    });
  }
  
  /// Toggle offline mode
  Future<void> _toggleOfflineMode() async {
    final newOfflineMode = await AppSettings.toggleOfflineMode();
    
    setState(() {
      _isOfflineMode = newOfflineMode;
      _connectionStatus = newOfflineMode ? 'Offline Mode' : 'Connecting...';
    });
    
    if (!newOfflineMode) {
      // If switching to online mode, try to connect
      await _connectToHealth();
    } else {
      // If switching to offline mode, update UI only
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Offline mode enabled'),
          backgroundColor: Colors.blue,
          duration: const Duration(seconds: 1),
        ),
      );
    }
  }
  
  /// Connect to health services
  Future<void> _connectToHealth() async {
    if (_isLoading || _isOfflineMode) return;
    
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
        
        // Check if the data is marked as offline
        final isOffline = metrics['isOffline'] as bool? ?? false;
        
        if (isOffline) {
          _connectionStatus = 'Offline Mode';
        } else {
          _connectionStatus = _hasPermissions ? 'Connected' : 'Partial connection';
        }
        
        _isLoading = false;
      });
      
      // Update user profile with new steps if greater than current steps
      if (_stepsCount > 0 && _userProfile != null) {
        await applyNewStepsToProfile(_stepsCount);
        // Reload profile after update
        _loadUserProfile();
      }
      
      // Only show a success message if we got steps and are not refreshing on startup
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
      
      // Get health steps
      int healthSteps = metrics['steps'] as int;
      
      setState(() {
        _stepsCount = healthSteps;
        _flightsClimbed = metrics['flightsClimbed'] as int;
        _distanceWalkingRunning = metrics['distanceWalkingRunning'] as double;
        _isLoading = false;
      });
      
      // Update user profile with new steps if they're higher than current profile steps
      if (_stepsCount > 0 && _userProfile != null) {
        // Use the profile service to update steps
        await applyNewStepsToProfile(_stepsCount);
        // Reload profile after update
        _loadUserProfile();
      }
      
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
          
          // Today's Stats Card - styled like pet bar meter
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: kCardColor,
              borderRadius: BorderRadius.circular(12),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  kCardColor,
                  kCardColor.withOpacity(0.8),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
              border: Border.all(
                color: kAccentColor.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Today\'s Activity',
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
                      tooltip: 'Refresh health data',
                    ),
                  ],
                ),
                
                // Profile stats section
                if (_userProfile != null) Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Profile Stats',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: kTextColor,
                            ),
                          ),
                          Text(
                            'Last sync: ${_formatLastSync()}',
                            style: TextStyle(
                              fontSize: 12,
                              color: kTextSecondaryColor,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      
                      // Total steps
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Total steps:',
                            style: TextStyle(
                              fontSize: 14,
                              color: kTextColor,
                            ),
                          ),
                          Text(
                            '${_userProfile!.steps}',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: kTextColor,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      
                      // Pet level
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Pet Level:',
                            style: TextStyle(
                              fontSize: 14,
                              color: kTextColor,
                            ),
                          ),
                          Text(
                            '${_userProfile!.activePetState?.currentLevel ?? 0}',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: kAccentColor,
                            ),
                          ),
                        ],
                      ),
                      
                      // Recent history heading
                      const SizedBox(height: 12),
                      if (_userProfile!.history.isNotEmpty) Text(
                        'Recent History:',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: kTextColor,
                        ),
                      ),
                      
                      // History list
                      if (_userProfile!.history.isNotEmpty) 
                        ..._buildHistoryItems(),
                    ],
                  ),
                ),
                
                // Steps progress bar
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.directions_walk, color: Colors.blue, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                'Steps',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: kTextColor,
                                ),
                              ),
                            ],
                          ),
                          Text(
                            '$_stepsCount',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: kTextColor,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      // Progress bar showing steps progress toward daily goal
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: _stepsCount / 10000, // Assuming 10k steps goal
                          backgroundColor: kProgressTrackColor,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                          minHeight: 8,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Floors progress bar
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.stairs, color: Colors.orange, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                'Floors',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: kTextColor,
                                ),
                              ),
                            ],
                          ),
                          Text(
                            '$_flightsClimbed',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: kTextColor,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: _flightsClimbed / 10, // Assuming 10 floors goal
                          backgroundColor: kProgressTrackColor,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
                          minHeight: 8,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Distance progress bar
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.straighten, color: Colors.green, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                'Distance',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: kTextColor,
                                ),
                              ),
                            ],
                          ),
                          Text(
                            '${(_distanceWalkingRunning / 1000).toStringAsFixed(1)} km',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: kTextColor,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: _distanceWalkingRunning / 5000, // Assuming 5km goal
                          backgroundColor: kProgressTrackColor,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
                          minHeight: 8,
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _stepsCount > 0 
                      ? () async {
                          // Update the profile with steps
                          await applyNewStepsToProfile(_stepsCount);
                          
                          // Also call the callback for backward compatibility
                          widget.onStepsAdded(_stepsCount);
                          
                          // Reload profile to get updated values
                          _loadUserProfile();
                          
                          if (!mounted) return;
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
          
          // Offline mode toggle
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Offline Mode:',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[700],
                  ),
                ),
                Switch(
                  value: _isOfflineMode,
                  onChanged: (value) {
                    _toggleOfflineMode();
                  },
                  activeColor: Colors.blue,
                ),
              ],
            ),
          ),
          
          Text(
            'Status: $_connectionStatus',
            style: TextStyle(
              fontSize: 14,
              color: _isOfflineMode ? Colors.blue : 
                     _connectionStatus == 'Connected' ? Colors.green : 
                     _connectionStatus == 'Partial connection' ? Colors.orange : Colors.red,
            ),
          ),
        ],
      ),
    );
  }
  
  // Get status color based on connection status
  Color _getStatusColor() {
    switch (_connectionStatus) {
      case 'Connected':
        return Colors.green;
      case 'Partial connection':
        return Colors.amber;
      case 'Permission denied':
        return Colors.red;
      case 'Connecting...':
        return kAccentColor;
      default:
        return Colors.grey;
    }
  }
  
  // Helper method to format last sync time
  String _formatLastSync() {
    if (_userProfile?.lastSync == null) return 'Never';
    
    final now = DateTime.now();
    final lastSync = _userProfile!.lastSync!;
    final difference = now.difference(lastSync);
    
    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }
  
  // Build history items list
  List<Widget> _buildHistoryItems() {
    // Get up to 5 most recent history entries, newest first
    final historyItems = _userProfile!.history.reversed.take(5).toList();
    
    return historyItems.map((item) {
      final date = item['date'] as String;
      final steps = item['steps'] as int;
      
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              date,
              style: TextStyle(
                fontSize: 12,
                color: kTextSecondaryColor,
              ),
            ),
            Text(
              '$steps steps',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: kTextColor,
              ),
            ),
          ],
        ),
      );
    }).toList();
  }
} 