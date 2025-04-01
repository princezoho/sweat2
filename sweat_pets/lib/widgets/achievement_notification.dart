import 'package:flutter/material.dart';
import 'dart:async';
import 'package:sweat_pets/models/achievements.dart';

/// A widget that displays a notification when an achievement is unlocked
class AchievementNotification extends StatefulWidget {
  /// The achievement that was unlocked
  final Achievement achievement;
  
  /// Callback when the notification is dismissed
  final VoidCallback? onDismissed;
  
  /// Auto-dismiss duration (null to require manual dismissal)
  final Duration? autoDismissDuration;

  /// Creates a new achievement notification
  const AchievementNotification({
    Key? key,
    required this.achievement,
    this.onDismissed,
    this.autoDismissDuration = const Duration(seconds: 4),
  }) : super(key: key);

  @override
  State<AchievementNotification> createState() => _AchievementNotificationState();
}

class _AchievementNotificationState extends State<AchievementNotification> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  Timer? _dismissTimer;
  
  @override
  void initState() {
    super.initState();
    
    // Animation controller
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    // Scale animation
    _scaleAnimation = Tween<double>(
      begin: 0.5,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut,
    ));
    
    // Fade animation
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
    ));
    
    // Start animation
    _controller.forward();
    
    // Auto-dismiss timer
    if (widget.autoDismissDuration != null) {
      _dismissTimer = Timer(widget.autoDismissDuration!, () {
        if (mounted) {
          _dismiss();
        }
      });
    }
  }
  
  @override
  void dispose() {
    _dismissTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }
  
  void _dismiss() {
    // Reverse animation and then call onDismissed
    _controller.reverse().then((_) {
      if (widget.onDismissed != null) {
        widget.onDismissed!();
      }
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (!didPop) {
          _dismiss();
        }
      },
      child: GestureDetector(
        onTap: _dismiss,
        child: Container(
          width: double.infinity,
          height: double.infinity,
          color: Colors.black.withOpacity(0.6),
          child: Center(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return Opacity(
                  opacity: _fadeAnimation.value,
                  child: Transform.scale(
                    scale: _scaleAnimation.value,
                    child: child,
                  ),
                );
              },
              child: Container(
                width: 300,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF333333),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                  border: Border.all(
                    color: const Color(0xFF8A64FF),
                    width: 2,
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Trophy icon
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: const Color(0xFF8A64FF).withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        widget.achievement.icon,
                        color: const Color(0xFF8A64FF),
                        size: 32,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Achievement unlocked text
                    const Text(
                      'Achievement Unlocked!',
                      style: TextStyle(
                        color: Color(0xFF8A64FF),
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    
                    // Achievement title
                    Text(
                      widget.achievement.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    
                    // Achievement description
                    Text(
                      widget.achievement.description,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    
                    // Tap to continue
                    const Text(
                      'Tap to continue',
                      style: TextStyle(
                        color: Colors.white54,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
} 