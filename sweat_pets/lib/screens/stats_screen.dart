import 'package:flutter/material.dart';
import '../game/game_reference.dart';
import '../models/pet_state.dart';
import '../widgets/enhanced_step_input.dart';
import '../screens/interface_screen.dart';

class StatsScreen extends StatefulWidget {
  final GameReference gameRef;
  final VoidCallback onBackPressed;

  const StatsScreen({
    Key? key, 
    required this.gameRef,
    required this.onBackPressed,
  }) : super(key: key);

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  bool _showAddStepsModal = false;
  
  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final petState = widget.gameRef.currentPet;
    final safeArea = MediaQuery.of(context).padding;
    
    // Calculate daily steps (simplified for demo)
    final dailySteps = petState?.dailySteps ?? 0;
    final totalSteps = petState?.totalSteps ?? 0;
    final level = petState?.currentLevel ?? 0;
    
    return Scaffold(
      backgroundColor: kBackgroundColor,
      body: SafeArea(
        child: Stack(
          children: [
            // Back button
            Positioned(
              top: 16,
              left: 16,
              child: GestureDetector(
                onTap: widget.onBackPressed,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: kCardColor,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.arrow_back,
                    color: kTextColor,
                    size: 24,
                  ),
                ),
              ),
            ),
            
            // Screen title
            Positioned(
              top: 25,
              left: 0,
              right: 0,
              child: Center(
                child: Text(
                  'Statistics',
                  style: TextStyle(
                    color: kTextColor,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            
            // Main content
            Padding(
              padding: const EdgeInsets.only(top: 70, left: 16, right: 16, bottom: 80),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Pet display card
                    Container(
                      width: double.infinity,
                      height: size.height * 0.25,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: kCardColor,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 6,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Center(
                        child: petState != null
                          ? Hero(
                              tag: 'pet_avatar',
                              child: Image.asset(
                                'assets/sweatpet${petState.currentLevel}.png',
                                height: size.height * 0.2,
                              ),
                            )
                          : Container(),
                      ),
                    ),
                    
                    // Stats section title
                    const Padding(
                      padding: EdgeInsets.only(left: 8, bottom: 8, top: 8),
                      child: Text(
                        'Activity Stats',
                        style: TextStyle(
                          fontSize: 18, 
                          fontWeight: FontWeight.bold,
                          color: kTextColor,
                        ),
                      ),
                    ),
                    
                    // Stats cards
                    Row(
                      children: [
                        // Steps Today Box
                        Expanded(
                          child: _buildStatsCard(
                            context,
                            'TODAY',
                            dailySteps.toString(),
                            Icons.directions_walk,
                            Colors.blue,
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Total Steps Box
                        Expanded(
                          child: _buildStatsCard(
                            context,
                            'TOTAL',
                            totalSteps.toString(),
                            Icons.bar_chart,
                            Colors.purple,
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 12),
                    
                    Row(
                      children: [
                        // Level Box
                        Expanded(
                          child: _buildStatsCard(
                            context,
                            'LEVEL',
                            level.toString(),
                            Icons.star,
                            Colors.amber,
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Next Level Progress
                        Expanded(
                          child: _buildProgressCard(
                            context,
                            'NEXT LEVEL',
                            petState != null 
                              ? '${(petState.getProgressToNextLevel() * 100).toInt()}%'
                              : '0%',
                            petState?.getProgressToNextLevel() ?? 0.0,
                          ),
                        ),
                      ],
                    ),
                    
                    // Achievements section
                    const Padding(
                      padding: EdgeInsets.only(left: 8, bottom: 8, top: 24),
                      child: Text(
                        'Achievements',
                        style: TextStyle(
                          fontSize: 18, 
                          fontWeight: FontWeight.bold,
                          color: kTextColor,
                        ),
                      ),
                    ),
                    
                    // Achievements list
                    Container(
                      decoration: BoxDecoration(
                        color: kCardColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          _buildAchievementItem(
                            'First Steps',
                            'Walk 1,000 steps in a day',
                            dailySteps >= 1000,
                            Icons.directions_walk,
                          ),
                          const Divider(height: 1, color: Color(0xFF3A3A3A)),
                          _buildAchievementItem(
                            'Level Up',
                            'Reach level 3 with your pet',
                            level >= 3,
                            Icons.trending_up,
                          ),
                          const Divider(height: 1, color: Color(0xFF3A3A3A)),
                          _buildAchievementItem(
                            'Marathon',
                            'Walk 10,000 steps in a day',
                            dailySteps >= 10000,
                            Icons.directions_run,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            // Bottom navigation buttons
            Positioned(
              bottom: 16 + safeArea.bottom,
              left: 0,
              right: 0,
              child: _buildBottomButtons(context, size),
            ),
            
            // Add Steps modal
            if (_showAddStepsModal)
              _buildAddStepsModal(context),
          ],
        ),
      ),
    );
  }
  
  Widget _buildStatsCard(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color iconColor,
  ) {
    return Container(
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
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: iconColor,
                  size: 16,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: kTextSecondaryColor,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: kTextColor,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildProgressCard(
    BuildContext context,
    String label,
    String value,
    double progress,
  ) {
    return Container(
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
          Text(
            label,
            style: TextStyle(
              color: kTextSecondaryColor,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: kTextColor,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            height: 6,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: kProgressTrackColor,
            ),
            child: FractionallySizedBox(
              widthFactor: progress,
              alignment: Alignment.centerLeft,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  gradient: LinearGradient(
                    colors: [kAccentColor, kProgressBarColor],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildAchievementItem(
    String title,
    String description,
    bool achieved,
    IconData icon,
  ) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: achieved 
              ? Colors.green.withOpacity(0.1) 
              : Colors.grey.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          color: achieved ? Colors.green : Colors.grey,
          size: 20,
        ),
      ),
      title: Text(
        title,
        style: TextStyle(
          color: kTextColor,
          fontWeight: FontWeight.bold,
        ),
      ),
      subtitle: Text(
        description,
        style: TextStyle(
          color: kTextSecondaryColor,
          fontSize: 12,
        ),
      ),
      trailing: achieved
          ? const Icon(Icons.check_circle, color: Colors.green)
          : const Icon(Icons.circle_outlined, color: Colors.grey),
    );
  }
  
  Widget _buildAddStepsModal(BuildContext context) {
    return Container(
      color: Colors.black.withOpacity(0.7),
      child: Center(
        child: Container(
          width: MediaQuery.of(context).size.width * 0.85,
          height: MediaQuery.of(context).size.height * 0.6,
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

  Widget _buildBottomButtons(BuildContext context, Size size) {
    return Center(
      child: Container(
        width: size.width * 0.85,
        height: 56,
        decoration: BoxDecoration(
          color: kCardColor,
          borderRadius: BorderRadius.circular(40),
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
            // Home button
            _buildNavButton(
              'HOME',
              Icons.home,
              widget.onBackPressed,
            ),
            
            // Add Steps button
            _buildNavButton(
              'ADD STEPS',
              Icons.add_circle_outline,
              () {
                setState(() {
                  _showAddStepsModal = true;
                });
              },
              isPrimary: true,
            ),
            
            // Share button
            _buildNavButton(
              'SHARE',
              Icons.share,
              () {
                // Handle share - simulated with a SnackBar
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Sharing your progress...'),
                    duration: Duration(seconds: 2),
                    backgroundColor: kCardColor,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildNavButton(
    String label,
    IconData icon,
    VoidCallback onTap, {
    bool isPrimary = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isPrimary ? kAccentColor : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isPrimary ? Colors.white : kTextSecondaryColor,
              size: 18,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: isPrimary ? Colors.white : kTextSecondaryColor,
                fontSize: 12,
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
    
    // Add steps and update pet state
    final newState = currentPet.addSteps(steps);
    widget.gameRef.updatePetState(newState);
    
    // Refresh screen
    setState(() {});
  }
} 