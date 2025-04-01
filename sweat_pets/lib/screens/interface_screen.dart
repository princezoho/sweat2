import 'package:flutter/material.dart';
import '../game/game_reference.dart';
import '../models/pet_state.dart';
import '../models/evolution_system.dart';
import '../screens/stats_screen.dart';
import '../services/health_service.dart';
import '../widgets/enhanced_step_input.dart';
import '../widgets/health_step_input.dart';
import '../widgets/level_up_notification.dart';
import '../widgets/achievement_notification.dart';
import 'package:sweat_pets/models/achievements.dart';
import 'package:sweat_pets/models/user_profile.dart';
import '../screens/profile_screen.dart';
import '../screens/pet_selection_screen.dart';
import '../models/pet.dart';
import '../models/pet_collection.dart';

// Dark theme colors
const Color kBackgroundColor = Color(0xFF1E1E1E); // Charcoal gray
const Color kCardColor = Color(0xFF2C2C2C);
const Color kAccentColor = Color(0xFF38B6FF); // Blue accent
const Color kTextColor = Colors.white;
const Color kTextSecondaryColor = Color(0xFFAAAAAA);
const Color kProgressBarColor = Color(0xFF4CAF50); // Green
const Color kProgressTrackColor = Color(0xFF3A3A3A);

// Achievement definitions
final Map<String, Map<String, dynamic>> achievements = {
  'first_steps': {
    'title': 'First Steps',
    'description': 'Take your first steps with your pet',
    'icon': Icons.directions_walk,
    'condition': (PetState state) => state.totalSteps > 0,
  },
  'step_100': {
    'title': 'Century Stepper',
    'description': 'Reach 100 total steps',
    'icon': Icons.directions_run,
    'condition': (PetState state) => state.totalSteps >= 100,
  },
  'step_1000': {
    'title': 'Dedicated Walker',
    'description': 'Reach 1,000 total steps',
    'icon': Icons.fitness_center,
    'condition': (PetState state) => state.totalSteps >= 1000,
  },
  'step_10000': {
    'title': 'Step Master',
    'description': 'Reach 10,000 total steps',
    'icon': Icons.emoji_events,
    'condition': (PetState state) => state.totalSteps >= 10000,
  },
  'level_3': {
    'title': 'Pet Evolution',
    'description': 'Evolve your pet to level 3',
    'icon': Icons.trending_up,
    'condition': (PetState state) => state.currentLevel >= 3,
  },
  'level_5': {
    'title': 'Advanced Evolution',
    'description': 'Evolve your pet to level 5',
    'icon': Icons.star,
    'condition': (PetState state) => state.currentLevel >= 5,
  },
  'level_10': {
    'title': 'Master Trainer',
    'description': 'Evolve your pet to level 10',
    'icon': Icons.military_tech,
    'condition': (PetState state) => state.currentLevel >= 10,
  },
};

class InterfaceScreen extends StatefulWidget {
  final GameReference gameRef;

  const InterfaceScreen({
    Key? key, 
    required this.gameRef,
  }) : super(key: key);

  @override
  State<InterfaceScreen> createState() => _InterfaceScreenState();
}

class _InterfaceScreenState extends State<InterfaceScreen> with SingleTickerProviderStateMixin {
  int _selectedTab = 0;
  bool _showLevelUp = false;
  bool _showAchievementNotification = false;
  String _currentAchievement = '';
  bool _showInput = false; // Start with input panel hidden for less scrolling
  bool _showStatsScreen = false;
  bool _showAddStepsModal = false;
  bool _isConnectingToHealth = false;
  bool _healthConnected = false;
  bool _showProfileScreen = false;
  bool _showPetSelectionScreen = false;
  
  // Health data map
  Map<String, dynamic> _healthData = {
    'steps': 0,
    'flightsClimbed': 0,
    'distanceWalkingRunning': 0.0,
  };
  
  // Health connection status
  String _connectionStatus = 'Not connected';
  
  // Health service
  final HealthService _healthService = HealthService();
  
  // Refresh animation controller
  late AnimationController _refreshController;
  
  // Page controller for swiping between daily and average pets
  late PageController _pageController;
  int _currentPetView = 0; // 0 = daily, 1 = average
  
  // Bottom navigation and input panel heights
  final double _navBarHeight = 56.0;
  final double _bottomPadding = 16.0;
  
  /// Current unlocked achievement to display
  Achievement? _currentUnlockedAchievement;
  
  /// Queue of achievements to display
  List<Achievement> _achievementQueue = [];
  
  /// User profile
  UserProfile? _userProfile;
  
  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);
    
    // Initialize refresh animation controller
    _refreshController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 800),
    );
    
    // Connect to HealthKit automatically on startup
    _connectToHealthKit();
    
    // Check for any achievements that may have been earned
    _checkForAchievements();
    
    // Load user profile
    _loadUserProfile();
  }
  
  @override
  void dispose() {
    _pageController.dispose();
    _refreshController.dispose();
    super.dispose();
  }
  
  /// Connect to HealthKit to fetch live data
  Future<void> _connectToHealthKit() async {
    setState(() {
      _isConnectingToHealth = true;
    });
    
    try {
      // Make sure user profile is loaded
      if (_userProfile == null) {
        await _loadUserProfile();
      }
      
      // Request permissions
      final hasPermissions = await _healthService.hasPermissions();
      if (!hasPermissions) {
        final granted = await _healthService.requestPermissions();
        if (!granted) {
          setState(() {
            _isConnectingToHealth = false;
            _healthConnected = false;
            _connectionStatus = 'Permission denied';
          });
          return;
        }
      }
      
      // Get health data
      final healthData = await _healthService.getHealthMetricsToday();
      int steps = healthData['steps'] as int;
      
      // If steps are greater than 0, we consider health connected regardless of permissions check
      // This is because the permissions check sometimes fails even when we can get data
      final bool dataReceived = steps > 0;
      
      // Get weekly data for average
      final weeklyData = await _healthService.getStepsForPastWeek();
      double averageSteps = 0;
      if (weeklyData.isNotEmpty) {
        int totalSteps = 0;
        for (final steps in weeklyData.values) {
          totalSteps += steps;
        }
        averageSteps = totalSteps / weeklyData.length;
      }
      
      // Store health data for display
      _healthData = healthData;
      
      // Update the pet state with real health data - BUT AVOID DUPLICATING STEPS
      if (_userProfile != null && widget.gameRef.currentPet != null) {
        // Get current state
        final currentState = widget.gameRef.currentPet!;
        
        // IMPORTANT: Reset the daily steps first to avoid duplication
        // This makes sure we're not adding to existing steps but replacing them
        PetState resetState = currentState.resetDailySteps();
        
        // Now add the health steps to the reset state
        // Since we reset first, this won't duplicate steps
        if (steps > 0) {
          // Add steps to the reset state (not duplicating because we reset first)
          PetState newState = resetState.addSteps(steps);
          
          // Update the game
          widget.gameRef.updatePetState(newState);
          
          // Also update the profile
          if (_userProfile!.petStates.containsKey(_userProfile!.activePetId)) {
            _userProfile!.petStates[_userProfile!.activePetId] = newState;
            await _userProfile!.save();
          }
        } else {
          // Even if no steps, update with the reset state
          widget.gameRef.updatePetState(resetState);
          
          if (_userProfile!.petStates.containsKey(_userProfile!.activePetId)) {
            _userProfile!.petStates[_userProfile!.activePetId] = resetState;
            await _userProfile!.save();
          }
        }
      }
      
      setState(() {
        _isConnectingToHealth = false;
        _healthConnected = dataReceived; // Use data success instead of permissions check
        _connectionStatus = hasPermissions ? 'Connected' : 'Partial connection';
      });
    } catch (e) {
      debugPrint('Error connecting to HealthKit: $e');
      setState(() {
        _isConnectingToHealth = false;
        _healthConnected = false;
        _connectionStatus = 'Connection error';
      });
    }
  }

  /// Check for achievements that should be unlocked
  void _checkForAchievements() {
    if (widget.gameRef.currentPet == null) return;
    
    final currentPet = widget.gameRef.currentPet!;
    final currentAchievements = currentPet.achievements;
    bool newAchievementEarned = false;
    
    // Check each achievement
    for (final entry in achievements.entries) {
      final id = entry.key;
      final achievement = entry.value;
      final condition = achievement['condition'] as Function;
      
      // If achievement isn't already earned and condition is met
      if (!currentAchievements.contains(id) && condition(currentPet)) {
        // Create a new state with the achievement added
        final newState = currentPet.copyWith(
          achievements: List<String>.from(currentAchievements)..add(id),
        );
        
        // Update the game state
        widget.gameRef.updatePetState(newState);
        
        // Show achievement notification
        setState(() {
          _showAchievementNotification = true;
          _currentAchievement = id;
        });
        
        newAchievementEarned = true;
        break; // Only show one achievement at a time
      }
    }
  }

  /// Load user profile
  Future<void> _loadUserProfile() async {
    final profile = await UserProfile.load();
    setState(() {
      _userProfile = profile;
    });
    
    // Check for achievements
    _checkProfileAchievements();
  }
  
  /// Check for achievements in user profile
  Future<void> _checkProfileAchievements() async {
    if (_userProfile == null) return;
    
    final newAchievements = await Achievements.checkForNewAchievements(_userProfile!);
    
    if (newAchievements.isNotEmpty) {
      setState(() {
        _achievementQueue.addAll(newAchievements);
        // Show the first achievement if not already showing one
        if (!_showAchievementNotification) {
          _showNextAchievement();
        }
      });
    }
  }
  
  /// Show the next achievement in the queue
  void _showNextAchievement() {
    if (_achievementQueue.isEmpty) {
      setState(() {
        _showAchievementNotification = false;
      });
      return;
    }
    
    setState(() {
      _currentUnlockedAchievement = _achievementQueue.removeAt(0);
      _showAchievementNotification = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_showStatsScreen) {
      return StatsScreen(
        gameRef: widget.gameRef,
        onBackPressed: () {
          setState(() {
            _showStatsScreen = false;
          });
        },
      );
    }
    
    if (_showProfileScreen) {
      return ProfileScreen(
        onBackPressed: () {
          setState(() {
            _showProfileScreen = false;
          });
        },
        onSelectPet: () {
          setState(() {
            _showProfileScreen = false;
            _showPetSelectionScreen = true;
          });
        },
      );
    }
    
    if (_showPetSelectionScreen && widget.gameRef.currentPet != null) {
      return PetSelectionScreen(
        currentState: widget.gameRef.currentPet!,
        onPetSelected: (Pet selectedPet) {
          _changePet(selectedPet);
          setState(() {
            _showPetSelectionScreen = false;
          });
        },
        onBackPressed: () {
          setState(() {
            _showPetSelectionScreen = false;
          });
        },
      );
    }
    
    final size = MediaQuery.of(context).size;
    final petState = widget.gameRef.currentPet;
    final petObject = widget.gameRef.game.currentPet;
    final safeArea = MediaQuery.of(context).padding;
    
    // Calculate bottom nav area total height
    final bottomNavTotalHeight = _navBarHeight + _bottomPadding + safeArea.bottom;
    
    // Get pet metrics based on current view
    final int steps = _currentPetView == 0 
        ? widget.gameRef.dailySteps 
        : widget.gameRef.averageSteps.toInt();
    final int level = _currentPetView == 0 
        ? widget.gameRef.dailyLevel 
        : widget.gameRef.averageLevel;
    final String petType = _currentPetView == 0 ? "Daily" : "Weekly";
    
    // Check if we need to show the health connect prompt
    final bool showHealthConnectPrompt = !_healthConnected && !_isConnectingToHealth && petState?.dailySteps == 0;
    
    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text(
          "Hi, ${_userProfile?.name ?? 'Trainer'}!",
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.pets, color: kAccentColor),
            onPressed: () {
              setState(() {
                _showPetSelectionScreen = true;
              });
            },
          ),
        ],
      ),
      body: SafeArea(
        bottom: false,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Main scrollable content area
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              bottom: bottomNavTotalHeight,
              child: Column(
                children: [
                  // Top row with level, steps counter and heart
                  Container(
                    height: 60,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Level indicator
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: kAccentColor.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.star_rate_rounded,
                                color: Colors.amber,
                                size: 20,
                              ),
                              const SizedBox(width: 2),
                              Text(
                                'Level $level',
                                style: const TextStyle(
                                  color: kTextColor,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        // Steps counter
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          decoration: BoxDecoration(
                            color: kCardColor,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    '$steps Steps',
                                    style: const TextStyle(
                                      color: kTextColor,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      height: 1.1,
                                    ),
                                  ),
                                  if (_isConnectingToHealth)
                                    Container(
                                      margin: const EdgeInsets.only(left: 4),
                                      width: 12,
                                      height: 12,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: kAccentColor,
                                      ),
                                    ),
                                ],
                              ),
                              Text(
                                '$petType Pet (Swipe)',
                                style: const TextStyle(
                                  color: kTextSecondaryColor,
                                  fontSize: 10,
                                  height: 1.0,
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        // Profile and stats buttons
                        Row(
                          children: [
                            // Profile button
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  _showProfileScreen = true;
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                margin: const EdgeInsets.only(right: 8),
                                decoration: BoxDecoration(
                                  color: Colors.purple.withOpacity(0.2),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.person,
                                  color: Colors.purple,
                                  size: 20,
                                ),
                              ),
                            ),
                            // Heart button
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  _showStatsScreen = true;
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.red.withOpacity(0.2),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.favorite,
                                  color: Colors.redAccent,
                                  size: 20,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  
                  // Health connection status indicator
                  if (_healthConnected || _isConnectingToHealth)
                    Container(
                      height: 24,
                      margin: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _isConnectingToHealth
                            ? SizedBox(
                                width: 12,
                                height: 12,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: kAccentColor,
                                ),
                              )
                            : Icon(
                                _connectionStatus == 'Connected' ? Icons.check_circle : Icons.info,
                                color: _connectionStatus == 'Connected' ? kProgressBarColor : Colors.amber,
                                size: 16,
                              ),
                          const SizedBox(width: 4),
                          Text(
                            _isConnectingToHealth 
                              ? 'Connecting to Health...' 
                              : _connectionStatus,
                            style: TextStyle(
                              color: _isConnectingToHealth 
                                ? kAccentColor 
                                : (_connectionStatus == 'Connected' ? kProgressBarColor : Colors.amber),
                              fontSize: 12,
                            ),
                          ),
                          IconButton(
                            icon: AnimatedBuilder(
                              animation: _refreshController,
                              builder: (context, child) {
                                return Transform.rotate(
                                  angle: _refreshController.value * 2.0 * 3.14159,
                                  child: Icon(
                                    Icons.refresh,
                                    color: kAccentColor,
                                  ),
                                );
                              },
                            ),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            onPressed: _isConnectingToHealth 
                              ? null 
                              : () {
                                  // Start rotation animation
                                  _refreshController.forward(from: 0.0);
                                  // Connect to health kit
                                  _connectToHealthKit();
                                },
                          ),
                        ],
                      ),
                    ),
                  
                  // Pet Selection Button
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _showPetSelectionScreen = true;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: kAccentColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.pets,
                            color: kAccentColor,
                            size: 18,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Change Pet',
                            style: TextStyle(
                              color: kAccentColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  // Main scrollable content
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          // Health connect prompt if needed
                          if (showHealthConnectPrompt)
                            Container(
                              width: size.width * 0.9,
                              margin: const EdgeInsets.symmetric(vertical: 16),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: kCardColor,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: kAccentColor.withOpacity(0.5),
                                  width: 1,
                                ),
                              ),
                              child: Column(
                                children: [
                                  const Text(
                                    'Connect to Health',
                                    style: TextStyle(
                                      color: kTextColor,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  const Text(
                                    'To show your actual step count, connect your Health app data.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: kTextSecondaryColor,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  ElevatedButton(
                                    onPressed: _connectToHealthKit,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: kAccentColor,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 24,
                                        vertical: 12,
                                      ),
                                    ),
                                    child: const Text('Connect Now'),
                                  ),
                                ],
                              ),
                            ),
                          
                          // Swipeable pet display area
                          SizedBox(
                            height: size.height * 0.45,
                            child: PageView(
                              controller: _pageController,
                              onPageChanged: (index) {
                                setState(() {
                                  _currentPetView = index;
                                });
                              },
                              children: [
                                // Daily Pet View
                                _buildPetView(
                                  context,
                                  widget.gameRef.dailyLevel,
                                  widget.gameRef.dailySteps,
                                  petState?.getProgressToNextLevel() ?? 0.0,
                                  petState?.getNextLevelThreshold() ?? 1000,
                                  "Daily",
                                ),
                                
                                // Average Pet View
                                _buildPetView(
                                  context,
                                  widget.gameRef.averageLevel,
                                  widget.gameRef.averageSteps.toInt(),
                                  petState?.getAverageProgressToNextLevel() ?? 0.0,
                                  petState?.getAverageNextLevelThreshold() ?? 1000,
                                  "Weekly Average",
                                ),
                              ],
                            ),
                          ),
                          
                          // Page indicator
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _buildPageIndicator(0),
                              const SizedBox(width: 8),
                              _buildPageIndicator(1),
                            ],
                          ),
                          
                          // Health Stats Card - directly on main screen
                          Container(
                            width: size.width * 0.9,
                            margin: const EdgeInsets.only(top: 16, bottom: 16),
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
                                      'Today\'s Stats',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: kTextColor,
                                      ),
                                    ),
                                    IconButton(
                                      icon: AnimatedBuilder(
                                        animation: _refreshController,
                                        builder: (context, child) {
                                          return Transform.rotate(
                                            angle: _refreshController.value * 2.0 * 3.14159,
                                            child: Icon(
                                              Icons.refresh,
                                              color: kAccentColor,
                                            ),
                                          );
                                        },
                                      ),
                                      onPressed: _isConnectingToHealth 
                                        ? null 
                                        : () {
                                            // Start rotation animation
                                            _refreshController.forward(from: 0.0);
                                            // Connect to health kit
                                            _connectToHealthKit();
                                          },
                                    ),
                                  ],
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
                                            '${widget.gameRef.dailySteps}',
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
                                          value: widget.gameRef.dailySteps / 10000, // Assuming 10k steps goal
                                          backgroundColor: kProgressTrackColor,
                                          valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                                          minHeight: 8,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                
                                // Only show additional health data if connected
                                if (_healthConnected) ...[
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
                                              '${_getHealthData('floors')}',
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
                                            value: (_getHealthData('floors') as int) / 10, // Assuming 10 floors goal
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
                                              '${_getHealthData('distance')} km',
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
                                            value: double.parse(_getHealthData('distance').toString()) / 5, // Assuming 5km goal
                                            backgroundColor: kProgressTrackColor,
                                            valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
                                            minHeight: 8,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          
                          // Bottom padding to ensure content doesn't get hidden
                          SizedBox(height: 16),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // Input panel - conditionally shown
            if (_showInput)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                bottom: bottomNavTotalHeight,
                child: DraggableScrollableSheet(
                  initialChildSize: 0.6,
                  minChildSize: 0.3,
                  maxChildSize: 0.9,
                  builder: (context, scrollController) {
                    return Container(
                      decoration: BoxDecoration(
                        color: kCardColor,
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(20),
                          bottomRight: Radius.circular(20),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 10,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Handle bar
                          Container(
                            width: 40,
                            height: 5,
                            margin: const EdgeInsets.only(top: 10, bottom: 5),
                            decoration: BoxDecoration(
                              color: Colors.grey.withOpacity(0.5),
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          
                          // Simple title instead of tabs
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  _selectedTab == 0 ? 'Connect to Health' : 'Add Steps Manually',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: kTextColor,
                                  ),
                                ),
                                IconButton(
                                  icon: Icon(Icons.close, color: kTextColor),
                                  padding: EdgeInsets.zero,
                                  constraints: BoxConstraints(),
                                  onPressed: () {
                                    setState(() {
                                      _showInput = false;
                                    });
                                  },
                                ),
                              ],
                            ),
                          ),
                          
                          const Divider(color: Color(0xFF3A3A3A), height: 1),
                          
                          // Tab content - Expanded to allow scrolling
                          Expanded(
                            child: _selectedTab == 0
                              ? HealthStepInput(onStepsAdded: _addSteps)
                              : EnhancedStepInput(onStepsAdded: _addSteps),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            
            // Bottom navigation buttons - fixed at bottom
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              height: bottomNavTotalHeight,
              child: Container(
                color: kBackgroundColor,
                child: Column(
                  children: [
                    const SizedBox(height: 8),
                    Center(
                      child: Container(
                        width: size.width * 0.8,
                        height: _navBarHeight,
                        decoration: BoxDecoration(
                          color: kCardColor,
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 8,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildNavButton('Health', Icons.favorite, 0),
                            _buildNavButton('Manual', Icons.edit, 1),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: safeArea.bottom),
                  ],
                ),
              ),
            ),
            
            // Add Steps modal
            if (_showAddStepsModal)
              _buildAddStepsModal(context),
            
            // Level up notification
            if (_showLevelUp)
              LevelUpNotification(
                newLevel: widget.gameRef.dailyLevel,
                onDismissed: () {
                  setState(() {
                    _showLevelUp = false;
                  });
                  
                  // Check for achievements after level up
                  _checkProfileAchievements();
                },
              ),
            
            // Achievement notification
            if (_showAchievementNotification && _currentUnlockedAchievement != null)
              AchievementNotification(
                achievement: _currentUnlockedAchievement!,
                onDismissed: () {
                  // Show the next achievement or hide
                  _showNextAchievement();
                },
              ),
          ],
        ),
      ),
    );
  }
  
  // Build page indicator dot
  Widget _buildPageIndicator(int pageIndex) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: _currentPetView == pageIndex 
            ? kAccentColor 
            : Colors.grey.withOpacity(0.5),
      ),
    );
  }
  
  // Build pet view for either daily or average
  Widget _buildPetView(
    BuildContext context, 
    int level, 
    int steps, 
    double progress, 
    int nextThreshold,
    String petTitle,
  ) {
    final size = MediaQuery.of(context).size;
    
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Pet display
        Container(
          height: size.height * 0.32,
          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
          decoration: BoxDecoration(
            color: kCardColor,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Center(
            child: Hero(
              tag: petTitle == "Daily" ? 'pet_avatar_daily' : 'pet_avatar_average',
              child: Image.asset(
                widget.gameRef.game.currentPet != null 
                  ? 'assets/pets/${widget.gameRef.game.currentPet!.id}$level.png' 
                  : 'assets/sweatpet$level.png',
                height: size.height * 0.405,
                errorBuilder: (context, error, stackTrace) {
                  // Fallback to a colored circle if image not found
                  final petObject = widget.gameRef.game.currentPet;
                  return Container(
                    height: size.height * 0.405,
                    width: size.height * 0.405,
                    decoration: BoxDecoration(
                      color: petObject != null && level < petObject.evolutionColors.length 
                           ? petObject.evolutionColors[level] 
                           : kAccentColor,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        petObject != null 
                           ? petObject.name.substring(0, 1) 
                           : 'S',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: size.height * 0.08,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
        
        // Progress info
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: kCardColor,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '$petTitle Pet',
                    style: const TextStyle(
                      color: kTextColor,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '$steps steps',
                    style: const TextStyle(
                      color: kTextSecondaryColor,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 10,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      color: kProgressTrackColor,
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: FractionallySizedBox(
                        widthFactor: progress,
                        alignment: Alignment.centerLeft,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [kAccentColor, kProgressBarColor],
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '$nextThreshold steps to level ${level + 1}',
                        style: const TextStyle(
                          color: kTextSecondaryColor,
                          fontSize: 11,
                          height: 1.0,
                        ),
                      ),
                      Text(
                        '${(progress * 100).toInt()}%',
                        style: const TextStyle(
                          color: kAccentColor,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          height: 1.0,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAddStepsModal(BuildContext context) {
    return Container(
      color: Colors.black.withOpacity(0.7),
      child: Center(
        child: Container(
          width: MediaQuery.of(context).size.width * 0.8,
          height: MediaQuery.of(context).size.height * 0.5,
          decoration: BoxDecoration(
            color: kCardColor,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 10,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Add Steps',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: kTextColor,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: kTextColor),
                      onPressed: () {
                        setState(() {
                          _showAddStepsModal = false;
                        });
                      },
                    ),
                  ],
                ),
              ),
              const Divider(color: Color(0xFF3A3A3A)),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: EnhancedStepInput(
                    onStepsAdded: (steps) {
                      _addSteps(steps);
                      setState(() {
                        _showAddStepsModal = false;
                      });
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavButton(String label, IconData icon, int index) {
    final isSelected = index == _selectedTab;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedTab = index;
          
          // Show input panel automatically when Manual tab is selected
          if (index == 1) { // Manual tab
            _showInput = true;
          } else {
            _showInput = false;
          }
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? kAccentColor.withOpacity(0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? kAccentColor : Colors.grey,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? kAccentColor : Colors.grey,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  void _addSteps(int steps) {
    final currentPet = widget.gameRef.currentPet;
    if (currentPet == null) return;
    
    // Handle special codes for resetting
    if (steps == -99999) {
      // Reset daily steps
      widget.gameRef.resetDailySteps();
      return;
    } else if (steps == -999999) {
      // Reset pet completely
      widget.gameRef.resetPet();
      return;
    }
    
    // Store current level for level up detection
    final previousLevel = currentPet.currentLevel;
    
    if (steps < 0) {
      // Remove steps
      widget.gameRef.removeSteps(steps.abs());
    } else {
      // For manual step input, use addManualSteps which only adds 1/7th to weekly average
      // instead of full amount like health data does
      final newState = _selectedTab == 0 
        ? currentPet.addSteps(steps)          // Health data (full affect)
        : currentPet.addManualSteps(steps);   // Manual steps (1/7th to average)
      
      widget.gameRef.updatePetState(newState);
      
      // Check for level up
      if (newState.currentLevel > previousLevel) {
        setState(() {
          _showLevelUp = true;
        });
      }
      
      // Check for achievements
      _checkProfileAchievements();
    }
  }

  Widget _buildStatRow(String label, String value, IconData icon, Color color) {
    // Keep this function for backward compatibility, but we've replaced its usage
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              icon,
              color: color,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  color: kTextSecondaryColor,
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: kTextColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHealthData() {
    // Empty because we've replaced this with inline UI in the Today's Stats card
    return Container();
  }
  
  // Get health data safely
  dynamic _getHealthData(String type) {
    try {
      // This would be populated from the health service
      // For now, return placeholders
      if (type == 'floors') {
        return _healthData['flightsClimbed'] ?? 0;
      } else if (type == 'distance') {
        final distance = (_healthData['distanceWalkingRunning'] as double? ?? 0) / 1000;
        return distance.toStringAsFixed(1);
      }
      return 0;
    } catch (e) {
      return 0;
    }
  }

  /// Changes the active pet
  void _changePet(Pet pet) async {
    debugPrint("Changing pet to: ${pet.id}");
    
    if (_userProfile != null) {
      // Check if the pet already has a state
      if (!_userProfile!.petStates.containsKey(pet.id)) {
        // Create a new state for this pet if it doesn't exist
        _userProfile!.petStates[pet.id] = PetState.initial();
        debugPrint("Created new state for pet: ${pet.id}");
      }
      
      // Set as active pet in user profile
      _userProfile!.setActivePet(pet.id);
      await _userProfile!.save();
      debugPrint("Set active pet in profile to: ${pet.id}");
      
      // Get the updated pet state
      final petState = _userProfile!.petStates[pet.id];
      if (petState != null) {
        // Use the new method to update both pet type and state in the game
        widget.gameRef.updateCurrentPet(pet.id, petState);
        debugPrint("Updated game reference with pet: ${pet.id} and its state");
        
        // Force rebuild UI
        setState(() {
          debugPrint("UI rebuild triggered");
        });
      }
    }
  }
}