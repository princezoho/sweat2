import 'package:flutter/material.dart';
import '../game/game_reference.dart';
import '../models/pet_state.dart';
import '../screens/stats_screen.dart';
import '../widgets/enhanced_step_input.dart';
import '../widgets/health_step_input.dart';
import '../widgets/level_up_notification.dart';

// Dark theme colors
const Color kBackgroundColor = Color(0xFF1E1E1E); // Charcoal gray
const Color kCardColor = Color(0xFF2C2C2C);
const Color kAccentColor = Color(0xFF38B6FF); // Blue accent
const Color kTextColor = Colors.white;
const Color kTextSecondaryColor = Color(0xFFAAAAAA);
const Color kProgressBarColor = Color(0xFF4CAF50); // Green
const Color kProgressTrackColor = Color(0xFF3A3A3A);

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
  bool _showInput = true;
  bool _showStatsScreen = false;
  bool _showAddStepsModal = false;

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
    
    final size = MediaQuery.of(context).size;
    final petState = widget.gameRef.currentPet;
    final safeArea = MediaQuery.of(context).padding;
    
    return Scaffold(
      backgroundColor: kBackgroundColor,
      body: SafeArea(
        bottom: false,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Heart button (stats)
            Positioned(
              top: 16,
              right: 16,
              child: GestureDetector(
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
                    size: 24,
                  ),
                ),
              ),
            ),
            
            // Level indicator
            Positioned(
              top: 16,
              left: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: kAccentColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.star_rate_rounded,
                      color: Colors.amber,
                      size: 24,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Level ${petState?.currentLevel ?? 0}',
                      style: const TextStyle(
                        color: kTextColor,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            // Main content area - scrollable to prevent overflow
            Positioned.fill(
              top: 70, // Leave space for level indicator and heart
              bottom: 100, // Leave space for bottom nav
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    // Pet display area
                    Container(
                      height: size.height * 0.4,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: kCardColor,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Center(
                        child: petState != null
                          ? Hero(
                              tag: 'pet_avatar',
                              child: Image.asset(
                                'assets/sweatpet${petState.currentLevel}.png',
                                height: size.height * 0.6,
                              ),
                            )
                          : Container(),
                      ),
                    ),
                    
                    // Steps display with progress bar (keeping only this one)
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: kCardColor,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: [
                          Text(
                            '${widget.gameRef.steps}',
                            style: const TextStyle(
                              color: kTextColor,
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Text(
                            'total steps',
                            style: TextStyle(
                              color: kTextSecondaryColor,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                height: 12,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(10),
                                  color: kProgressTrackColor,
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: FractionallySizedBox(
                                    widthFactor: petState != null
                                        ? petState.getProgressToNextLevel()
                                        : 0.0,
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
                              Text(
                                '${petState?.getNextLevelThreshold() ?? 0} steps to level ${(petState?.currentLevel ?? 0) + 1}',
                                style: const TextStyle(
                                  color: kTextSecondaryColor,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    
                    // Add Steps button (keeping this instead of multiple buttons)
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _showInput = !_showInput;
                        });
                      },
                      child: Container(
                        width: size.width * 0.8,
                        height: 50,
                        margin: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          color: kAccentColor,
                          borderRadius: BorderRadius.circular(25),
                          boxShadow: [
                            BoxShadow(
                              color: kAccentColor.withOpacity(0.2),
                              spreadRadius: 1,
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            'Add Steps',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            // Toggle button for input panel
            Positioned(
              bottom: 80,
              right: 16,
              child: FloatingActionButton.small(
                backgroundColor: kAccentColor,
                elevation: 4,
                onPressed: () {
                  setState(() {
                    _showInput = !_showInput;
                  });
                },
                child: Icon(
                  _showInput ? Icons.keyboard_arrow_down : Icons.keyboard_arrow_up,
                  color: Colors.white,
                ),
              ),
            ),
            
            // Input panel - conditionally shown
            if (_showInput)
              DraggableScrollableSheet(
                initialChildSize: 0.5,
                minChildSize: 0.2,
                maxChildSize: 0.8,
                builder: (context, scrollController) {
                  return Container(
                    decoration: BoxDecoration(
                      color: kCardColor,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(20),
                        topRight: Radius.circular(20),
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
                        
                        // Tab headers
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Row(
                            children: [
                              _buildTabButton('Health', Icons.favorite, 0),
                              const SizedBox(width: 16),
                              _buildTabButton('Manual', Icons.edit, 1),
                            ],
                          ),
                        ),
                        
                        const Divider(color: Color(0xFF3A3A3A)),
                        
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
            
            // Bottom navigation buttons - now fixed at bottom
            Positioned(
              bottom: 16 + safeArea.bottom,
              left: 0,
              right: 0,
              height: 56,
              child: Center(
                child: Container(
                  width: size.width * 0.8,
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
            ),
            
            // Add Steps modal
            if (_showAddStepsModal)
              _buildAddStepsModal(context),
            
            // Level up notification overlay
            if (_showLevelUp && petState != null)
              Center(
                child: LevelUpNotification(
                  newLevel: petState.currentLevel,
                  onDismissed: () {
                    setState(() {
                      _showLevelUp = false;
                    });
                  },
                ),
              ),
          ],
        ),
      ),
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

  Widget _buildTabButton(String label, IconData icon, int index) {
    final isSelected = index == _selectedTab;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedTab = index;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected ? kAccentColor.withOpacity(0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: isSelected 
              ? Border.all(color: kAccentColor) 
              : null,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? kAccentColor : Colors.grey,
              size: 16,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? kAccentColor : Colors.grey,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
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
    
    // Store current level for level up detection
    final previousLevel = currentPet.currentLevel;
    
    // Add steps and update pet state
    final newState = currentPet.addSteps(steps);
    widget.gameRef.updatePetState(newState);
    
    // Check for level up
    if (newState.currentLevel > previousLevel) {
      setState(() {
        _showLevelUp = true;
      });
    }
  }
} 