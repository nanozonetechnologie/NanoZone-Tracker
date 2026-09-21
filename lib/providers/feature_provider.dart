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

  Map<String, bool> get features => {..._features};

  bool isFeatureEnabled(String featureKey) {
    return _features[featureKey] ?? false;
  }

  Future<void> init() async {
    if (_isInitialized) return;
    
    final prefs = await SharedPreferences.getInstance();
    for (String key in _features.keys) {
      _features[key] = prefs.getBool(prefKeyPrefix + key) ?? _features[key]!;
    }
    
    _isInitialized = true;
    notifyListeners();
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
