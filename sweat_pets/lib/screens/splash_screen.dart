import 'package:flutter/material.dart';
import 'dart:async';
import '../screens/interface_screen.dart';
import '../models/pet_state.dart';
import '../game/sweat_pet_game.dart';
import '../game/game_reference.dart';

// Define UI constants
const kBackgroundColor = Color(0xFF1E1E1E);
const kCardColor = Color(0xFF2A2A2A);
const kAccentColor = Color(0xFF8A64FF);
const kTextSecondaryColor = Colors.white70;

/// A splash screen shown when the app starts
class SplashScreen extends StatefulWidget {
  /// The callback to navigate to the main interface
  final VoidCallback? onComplete;

  /// Creates a new splash screen
  const SplashScreen({
    Key? key,
    this.onComplete,
  }) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _logoScaleAnimation;
  late Animation<double> _logoOpacityAnimation;
  
  // Current pet level to show (animated)
  int _currentPetIndex = 0;
  Timer? _petAnimationTimer;
  Timer? _navigationTimer;
  Timer? _forceNavigationTimer;
  
  // Available pet images (0-7)
  final int _maxPetIndex = 7;
  
  @override
  void initState() {
    super.initState();
    
    // Initialize animation controller
    _controller = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    
    // Logo animations
    _logoScaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut,
    ));
    
    _logoOpacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
    ));
    
    // Start animation and pet character rotation
    _controller.forward();
    _startPetAnimation();
    
    // Navigate to main interface after delay
    if (widget.onComplete != null) {
      _navigationTimer = Timer(const Duration(seconds: 3), widget.onComplete!);
    }
    
    // Force navigation after max wait time (in case onComplete callback fails)
    _forceNavigationTimer = Timer(const Duration(seconds: 6), () {
      if (mounted && Navigator.canPop(context)) {
        debugPrint('⏱️ Force navigating away from splash screen after timeout');
        _forceNavigateToMainScreen();
      }
    });
  }
  
  @override
  void dispose() {
    _controller.dispose();
    _petAnimationTimer?.cancel();
    _navigationTimer?.cancel();
    _forceNavigationTimer?.cancel();
    super.dispose();
  }
  
  void _startPetAnimation() {
    // Switch pet every 300ms
    _petAnimationTimer = Timer.periodic(const Duration(milliseconds: 300), (timer) {
      setState(() {
        _currentPetIndex = (_currentPetIndex + 1) % (_maxPetIndex + 1);
      });
    });
  }
  
  void _forceNavigateToMainScreen() {
    try {
      // Create a default state and force navigate
      final defaultState = PetState.initial();
      final game = SweatPetGame(initialState: defaultState);
      final gameRef = GameReference(game);
      
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => InterfaceScreen(gameRef: gameRef),
        ),
      );
    } catch (e) {
      debugPrint('Error during force navigation: $e');
      // Even if this fails, the app won't be stuck on the splash screen
      // as the user can restart the app
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    
    return Scaffold(
      backgroundColor: kBackgroundColor,
      // Add a button to manually navigate if all else fails
      floatingActionButton: FloatingActionButton(
        onPressed: _forceNavigateToMainScreen,
        mini: true,
        backgroundColor: Colors.black.withOpacity(0.5),
        child: Icon(Icons.arrow_forward, color: kAccentColor),
      ),
      body: Stack(
        children: [
          // Background with gradient
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  kBackgroundColor,
                  kBackgroundColor.withOpacity(0.8),
                  kCardColor,
                ],
              ),
            ),
          ),
          
          // Animated particles/stars effect
          ...List.generate(20, (index) {
            final random = DateTime.now().millisecondsSinceEpoch + index;
            final top = (random % screenSize.height) / 1.2;
            final left = (random % screenSize.width) / 1.2;
            final particleSize = (random % 5) + 2.0;
            final opacity = ((random % 10) + 5) / 15.0;
            
            return Positioned(
              top: top,
              left: left,
              child: Container(
                width: particleSize,
                height: particleSize,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(opacity),
                  shape: BoxShape.circle,
                ),
              ),
            );
          }),
          
          // Main content
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo and title with animation
                AnimatedBuilder(
                  animation: _controller,
                  builder: (context, child) {
                    return Opacity(
                      opacity: _logoOpacityAnimation.value,
                      child: Transform.scale(
                        scale: _logoScaleAnimation.value,
                        child: child,
                      ),
                    );
                  },
                  child: Column(
                    children: [
                      // App title
                      ShaderMask(
                        shaderCallback: (bounds) => const LinearGradient(
                          colors: [kAccentColor, Color(0xFF4CAF50)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ).createShader(bounds),
                        child: const Text(
                          'SWEAT PETS',
                          style: TextStyle(
                            fontSize: 40,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 2,
                            shadows: [
                              Shadow(
                                color: Colors.black,
                                blurRadius: 15,
                                offset: Offset(0, 5),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // Tagline
                      const Text(
                        'Walk. Grow. Evolve.',
                        style: TextStyle(
                          fontSize: 18,
                          color: kTextSecondaryColor,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
                
                // Animated pet - using Image instead of Hero to avoid attachment errors
                SizedBox(
                  height: 200,
                  child: Image.asset(
                    'assets/sweatpet$_currentPetIndex.png',
                    height: 180,
                  ),
                ),
                const SizedBox(height: 40),
                
                // Loading indicator
                SizedBox(
                  width: 40,
                  height: 40,
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(kAccentColor),
                    strokeWidth: 3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
} 