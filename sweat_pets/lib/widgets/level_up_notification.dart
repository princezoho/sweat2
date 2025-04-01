import 'package:flutter/material.dart';
import 'dart:async';

/// A notification widget shown when the pet levels up
class LevelUpNotification extends StatefulWidget {
  /// The new level that was achieved
  final int newLevel;
  
  /// Callback when the notification is dismissed
  final VoidCallback? onDismissed;
  
  /// Creates a new level up notification
  const LevelUpNotification({
    super.key,
    required this.newLevel,
    this.onDismissed,
  });

  @override
  State<LevelUpNotification> createState() => _LevelUpNotificationState();
}

class _LevelUpNotificationState extends State<LevelUpNotification> with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;
  late Animation<double> _starAnimation;
  
  Timer? _autoDismissTimer;
  bool _isDismissing = false;
  
  @override
  void initState() {
    super.initState();
    
    // Setup animations with a single controller
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _scaleAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut,
    );
    
    _opacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
    ));
    
    // Star animation uses the same controller
    _starAnimation = Tween<double>(
      begin: 0.8,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
    
    // Start animation once
    _controller.forward();
    
    // Auto-dismiss after 5 seconds
    _autoDismissTimer = Timer(const Duration(seconds: 5), () {
      if (!_isDismissing && mounted) {
        _dismiss();
      }
    });
  }
  
  @override
  void dispose() {
    _controller.dispose();
    _autoDismissTimer?.cancel();
    super.dispose();
  }
  
  void _dismiss() {
    if (_isDismissing) return;
    
    setState(() {
      _isDismissing = true;
    });
    
    _controller.stop();
    _controller.reverse().then((_) {
      if (widget.onDismissed != null) {
        widget.onDismissed!();
      }
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        _dismiss();
        return false; // Let the animation finish before popping
      },
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Opacity(
            opacity: _opacityAnimation.value,
            child: Transform.scale(
              scale: _scaleAnimation.value,
              child: child,
            ),
          );
        },
        child: Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: GestureDetector(
            onTap: _dismiss,
            child: Container(
              width: 300,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF2A2A2A), Color(0xFF1A1A1A)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: const Color(0xFF38B6FF),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF38B6FF).withOpacity(0.5),
                    blurRadius: 15,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Animated stars
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildAnimatedStar(0.0),
                      _buildAnimatedStar(0.2),
                      const Icon(
                        Icons.celebration,
                        color: Colors.amber,
                        size: 50,
                      ),
                      _buildAnimatedStar(0.2),
                      _buildAnimatedStar(0.0),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Level up text
                  ShaderMask(
                    shaderCallback: (bounds) => const LinearGradient(
                      colors: [Color(0xFF38B6FF), Color(0xFF4CAF50)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ).createShader(bounds),
                    child: const Text(
                      'LEVEL UP!',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 2,
                        shadows: [
                          Shadow(
                            color: Colors.black,
                            blurRadius: 5,
                            offset: Offset(0, 3),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  // New level badge
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF2A2A2A),
                      border: Border.all(
                        color: const Color(0xFF38B6FF),
                        width: 3,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF38B6FF).withOpacity(0.5),
                          blurRadius: 8,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        '${widget.newLevel}',
                        style: const TextStyle(
                          fontSize: 50,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF38B6FF),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Congratulations text
                  const Text(
                    'Your pet has evolved!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Keep going to unlock new forms',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFFAAAAAA),
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Continue button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _dismiss,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF38B6FF),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        elevation: 5,
                      ),
                      child: const Text(
                        'AWESOME!',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedStar(double offset) {
    return AnimatedBuilder(
      animation: _starAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(offset * 40, 0),
          child: Transform.scale(
            scale: _starAnimation.value,
            child: const Icon(
              Icons.star,
              color: Colors.amber,
              size: 28,
            ),
          ),
        );
      },
    );
  }
} 