import 'package:shared_preferences/shared_preferences.dart';

/// Manages app-wide settings
class AppSettings {
  static const String _offlineModeKey = 'offline_mode';
  static bool _offlineMode = false;
  
  /// Get current offline mode status
  static bool get offlineMode => _offlineMode;
  
  /// Initialize settings
  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _offlineMode = prefs.getBool(_offlineModeKey) ?? false;
  }
  
  /// Toggle offline mode
  static Future<bool> toggleOfflineMode() async {
    final prefs = await SharedPreferences.getInstance();
    _offlineMode = !_offlineMode;
    await prefs.setBool(_offlineModeKey, _offlineMode);
    return _offlineMode;
  }
  
  /// Set offline mode
  static Future<void> setOfflineMode(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    _offlineMode = value;
    await prefs.setBool(_offlineModeKey, _offlineMode);
  }
} 