import 'package:exptrackerforhybridos/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FeatureTourStep {
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final String targetHint;

  const FeatureTourStep({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.targetHint,
  });
}

class FeatureTourOverlay extends StatefulWidget {
  final VoidCallback onComplete;

  const FeatureTourOverlay({
    super.key,
    required this.onComplete,
  });

  static const List<FeatureTourStep> steps = [
    FeatureTourStep(
      title: 'Set Monthly Budget',
      description: 'Tap the Budget card to set your target limit for this month. Your live remaining balance and spent percentage update automatically as you log expenses.',
      icon: Icons.account_balance_wallet_rounded,
      color: Color(0xFF6366F1),
      targetHint: '📊 STEP 1 OF 4 • BUDGET CARD',
    ),
    FeatureTourStep(
      title: '1-Tap Quick Expenses',
      description: 'Tap Coffee, Meal, Fuel, or Grocery for instant 1-second expense logging. Long-press any preset card to customize its name and default price!',
      icon: Icons.bolt_rounded,
      color: Color(0xFF10B981),
      targetHint: '⚡ STEP 2 OF 4 • DAILY FAVORITES',
    ),
    FeatureTourStep(
      title: 'Quick Access & Analytics',
      description: 'Use the Quick Access grid to jump into Analytics, Savings Tracker, and Savings Goals. Switch pages smoothly using the floating bottom navigation bar.',
      icon: Icons.insights_rounded,
      color: Color(0xFFEC4899),
      targetHint: '🎯 STEP 3 OF 4 • QUICK MODULES',
    ),
    FeatureTourStep(
      title: 'App Lock & Local Backups',
      description: 'Tap the Settings icon at the top right to customize themes, toggle biometric security lock, or export 100% offline JSON backups of your financial data.',
      icon: Icons.settings_rounded,
      color: Color(0xFFF59E0B),
      targetHint: '🔒 STEP 4 OF 4 • SETTINGS & BACKUP',
    ),
  ];

  static Future<void> showIfFirstTime(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    final hasCompleted = prefs.getBool('has_completed_interactive_tour') ?? false;

    if (!hasCompleted && context.mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        barrierColor: Colors.black.withAlpha(180),
        builder: (ctx) => FeatureTourOverlay(
          onComplete: () async {
            await prefs.setBool('has_completed_interactive_tour', true);
            if (ctx.mounted) {
              Navigator.of(ctx).pop();
            }
          },
        ),
      );
    }
  }

  static Future<void> forceShow(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    if (context.mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        barrierColor: Colors.black.withAlpha(180),
        builder: (ctx) => FeatureTourOverlay(
          onComplete: () async {
            await prefs.setBool('has_completed_interactive_tour', true);
            if (ctx.mounted) {
              Navigator.of(ctx).pop();
            }
          },
        ),
      );
    }
  }

  @override
  State<FeatureTourOverlay> createState() => _FeatureTourOverlayState();
}

class _FeatureTourOverlayState extends State<FeatureTourOverlay>
    with SingleTickerProviderStateMixin {
  int _currentStepIndex = 0;
  late AnimationController _animController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _scaleAnimation = Tween<double>(begin: 0.9, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutBack),
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _nextStep() {
    HapticFeedback.selectionClick();
    if (_currentStepIndex < FeatureTourOverlay.steps.length - 1) {
      _animController.reset();
      setState(() {
        _currentStepIndex++;
      });
      _animController.forward();
    } else {
      widget.onComplete();
    }
  }

  void _previousStep() {
    HapticFeedback.selectionClick();
    if (_currentStepIndex > 0) {
      _animController.reset();
      setState(() {
        _currentStepIndex--;
      });
      _animController.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentStep = FeatureTourOverlay.steps[_currentStepIndex];
    final isLastStep = _currentStepIndex == FeatureTourOverlay.steps.length - 1;

    return Center(
      child: Material(
        color: Colors.transparent,
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 24),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: isDark ? AppTheme.surfaceDark : AppTheme.surfaceLight,
              borderRadius: BorderRadius.circular(32),
              border: Border.all(
                color: currentStep.color.withAlpha(100),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: currentStep.color.withAlpha(80),
                  blurRadius: 36,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Tag
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: currentStep.color.withAlpha(20),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        currentStep.targetHint,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          color: currentStep.color,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: widget.onComplete,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.grey.withAlpha(30),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.close_rounded, size: 18, color: Colors.grey),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Icon Badge & Title
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [currentStep.color, currentStep.color.withAlpha(180)],
                        ),
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                            color: currentStep.color.withAlpha(60),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Icon(currentStep.icon, color: Colors.white, size: 28),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        currentStep.title,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Description
                Text(
                  currentStep.description,
                  style: TextStyle(
                    fontSize: 13.5,
                    height: 1.6,
                    fontWeight: FontWeight.w500,
                    color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
                  ),
                ),
                const SizedBox(height: 28),

                // Indicator Dots & Navigation Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Step Dots
                    Row(
                      children: List.generate(FeatureTourOverlay.steps.length, (idx) {
                        final isSelected = idx == _currentStepIndex;
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          margin: const EdgeInsets.only(right: 6),
                          width: isSelected ? 20 : 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: isSelected ? currentStep.color : Colors.grey.withAlpha(80),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        );
                      }),
                    ),

                    // Actions
                    Row(
                      children: [
                        if (_currentStepIndex > 0)
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: OutlinedButton(
                              onPressed: _previousStep,
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              ),
                              child: const Text('Back'),
                            ),
                          ),
                        ElevatedButton(
                          onPressed: _nextStep,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: currentStep.color,
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          child: Text(
                            isLastStep ? 'Got It!' : 'Next',
                            style: const TextStyle(fontWeight: FontWeight.w800, color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
