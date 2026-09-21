import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FeatureProvider with ChangeNotifier {
  static const String prefKeyPrefix = 'feature_';

  // Default features and their states for Free Tier
  final Map<String, bool> _features = {
    'dashboard': true,
    'savings_tracker': true,
    'savings_goals': true,
    'budget_planner': true,
  };

  bool _isInitialized = false;
  ThemeMode _themeMode = ThemeMode.system;

  Map<String, bool> get features => {..._features};
  ThemeMode get themeMode => _themeMode;

  bool isFeatureEnabled(String featureKey) {
    return _features[featureKey] ?? false;
  }

  Future<void> init() async {
    if (_isInitialized) return;
    
    final prefs = await SharedPreferences.getInstance();
    for (String key in _features.keys) {
      _features[key] = prefs.getBool(prefKeyPrefix + key) ?? _features[key]!;
    }

    final themeStr = prefs.getString('theme_mode') ?? 'system';
    if (themeStr == 'light') {
      _themeMode = ThemeMode.light;
    } else if (themeStr == 'dark') {
      _themeMode = ThemeMode.dark;
    } else {
      _themeMode = ThemeMode.system;
    }
    
    _isInitialized = true;
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    final str = mode == ThemeMode.light ? 'light' : (mode == ThemeMode.dark ? 'dark' : 'system');
    await prefs.setString('theme_mode', str);
  }

  Future<void> toggleFeature(String featureKey, bool value) async {
    if (!_features.containsKey(featureKey)) return;
    
    _features[featureKey] = value;
    notifyListeners();
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(prefKeyPrefix + featureKey, value);
  }

  String getFeatureName(String key) {
    switch (key) {
      case 'dashboard': return 'Dashboard';
      case 'savings_tracker': return 'Savings Tracker';
      case 'savings_goals': return 'Savings Goals';
      case 'budget_planner': return 'Budget Planner';
      default: return key;
    }
  }
}
