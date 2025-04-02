import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

/// Manages app-wide settings
class AppSettings {
  static const String _offlineModeKey = 'offline_mode';
  static bool _offlineMode = true; // Default to true to ensure app works without connection
  static bool _isInitialized = false;
  
  /// Get current offline mode status
  static bool get offlineMode => _offlineMode;
  
  /// Check if settings are initialized
  static bool get isInitialized => _isInitialized;
  
  /// Initialize settings
  static Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // Load offline mode from preferences, defaulting to true if not found
      _offlineMode = prefs.getBool(_offlineModeKey) ?? true;
      _isInitialized = true;
      debugPrint('📱 App settings initialized. Offline mode: $_offlineMode');
    } catch (e) {
      // If initialization fails, default to offline mode
      debugPrint('📱 Error initializing app settings: $e');
      _offlineMode = true;
      _isInitialized = false;
    }
  }
  
  /// Toggle offline mode
  static Future<bool> toggleOfflineMode() async {
    try {
      _offlineMode = !_offlineMode;
      
      // Try to save the setting
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool(_offlineModeKey, _offlineMode);
        debugPrint('📱 Offline mode toggled to: $_offlineMode');
      } catch (e) {
        debugPrint('📱 Error saving offline mode setting: $e');
        // Continue anyway, as the in-memory setting is updated
      }
      
      return _offlineMode;
    } catch (e) {
      debugPrint('📱 Error toggling offline mode: $e');
      return _offlineMode;
    }
  }
  
  /// Set offline mode
  static Future<void> setOfflineMode(bool value) async {
    try {
      // Always update the in-memory setting
      _offlineMode = value;
      
      // Try to save the setting
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool(_offlineModeKey, _offlineMode);
        debugPrint('📱 Offline mode set to: $_offlineMode');
      } catch (e) {
        debugPrint('📱 Error saving offline mode setting: $e');
        // Continue anyway, as the in-memory setting is updated
      }
    } catch (e) {
      debugPrint('📱 Error setting offline mode: $e');
      // Ensure we default to offline mode in case of error
      _offlineMode = true;
    }
  }
} 