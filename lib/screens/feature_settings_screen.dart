import 'package:exptrackerforhybridos/providers/feature_provider.dart';
import 'package:exptrackerforhybridos/theme/app_theme.dart';
import 'package:exptrackerforhybridos/screens/accounts_screen.dart';
import 'package:exptrackerforhybridos/screens/backup_screen.dart';
import 'package:exptrackerforhybridos/screens/help_screen.dart';
import 'package:exptrackerforhybridos/widgets/feature_tour_overlay.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:package_info_plus/package_info_plus.dart';

class FeatureSettingsScreen extends StatefulWidget {
  const FeatureSettingsScreen({super.key});

  @override
  State<FeatureSettingsScreen> createState() => _FeatureSettingsScreenState();
}

class _FeatureSettingsScreenState extends State<FeatureSettingsScreen> {
  String _version = '1.0.0';
  String _buildNumber = '1';

  @override
  void initState() {
    super.initState();
    _loadPackageInfo();
  }

  Future<void> _loadPackageInfo() async {
    try {
      final info = await PackageInfo.fromPlatform();
      if (mounted) {
        setState(() {
          _version = info.version;
          _buildNumber = info.buildNumber;
        });
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final featureProvider = Provider.of<FeatureProvider>(context);
    final features = featureProvider.features;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.backgroundDark : AppTheme.backgroundLight,
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // Custom Hero Header
            SliverToBoxAdapter(
              child: Container(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: AppTheme.primaryGradient,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: const BorderRadius.vertical(bottom: Radius.circular(32)),
                  boxShadow: AppTheme.shadowLarge,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.of(context).pop(),
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.white.withAlpha(25),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 22),
                          ),
                        ),
                        const SizedBox(width: 16),
                        const Text(
                          'App Settings',
                          style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            color: Colors.white.withAlpha(35),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white30, width: 2),
                          ),
                          child: const Icon(Icons.tune_rounded, color: Colors.white, size: 28),
                        ),
                        const SizedBox(width: 16),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'NanoZone Preferences',
                                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Customize modules, accounts, and local storage',
                                style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Shortcuts & Quick Tools
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionHeader(context, 'Quick Management'),
                    const SizedBox(height: 12),
                    _buildNavigationCard(
                      context,
                      title: 'My Accounts & Cards',
                      subtitle: 'Bank accounts and credit cards',
                      icon: Icons.account_balance_wallet_rounded,
                      color: const Color(0xFF6366F1),
                      screen: const AccountsScreen(),
                    ),
                    const SizedBox(height: 12),
                    _buildNavigationCard(
                      context,
                      title: 'Local Storage & Backup',
                      subtitle: 'Export & restore JSON files',
                      icon: Icons.sd_storage_rounded,
                      color: const Color(0xFF10B981),
                      screen: const BackupScreen(),
                    ),
                    const SizedBox(height: 12),
                    GestureDetector(
                      onTap: () => FeatureTourOverlay.forceShow(context),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: AppTheme.cardDecoration(context),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEC4899).withAlpha(20),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: const Icon(Icons.tips_and_updates_rounded, color: Color(0xFFEC4899), size: 24),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Replay Feature Popups',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w800,
                                      color: isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Step-by-step popup guide for budget & features',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              Icons.chevron_right_rounded,
                              color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildNavigationCard(
                      context,
                      title: 'Help & User Guide',
                      subtitle: 'Budget tracking tips and answers',
                      icon: Icons.help_center_rounded,
                      color: const Color(0xFFF59E0B),
                      screen: const HelpScreen(),
                    ),
                  ],
                ),
              ),
            ),

            // Feature Customization Section
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 28, 20, 40),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionHeader(context, 'Feature Modules'),
                    const SizedBox(height: 12),
                    Container(
                      decoration: AppTheme.cardDecoration(context),
                      child: Column(
                        children: features.keys.map((key) {
                          return _buildFeatureSwitchTile(
                            context,
                            provider: featureProvider,
                            featureKey: key,
                            isDark: isDark,
                          );
                        }).toList(),
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Version Card
                    Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white.withAlpha(5) : Colors.black.withAlpha(5),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.verified_rounded, size: 16, color: AppTheme.primaryColor),
                            const SizedBox(width: 8),
                            Text(
                              'NanoZone Tracker v$_version ($_buildNumber)',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Text(
      title.toUpperCase(),
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w800,
        letterSpacing: 1.2,
        color: AppTheme.primaryColor,
      ),
    );
  }

  Widget _buildNavigationCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required Widget screen,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => screen)),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: AppTheme.cardDecoration(context),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withAlpha(20),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureSwitchTile(
    BuildContext context, {
    required FeatureProvider provider,
    required String featureKey,
    required bool isDark,
  }) {
    final isEnabled = provider.isFeatureEnabled(featureKey);

    return SwitchListTile(
      value: isEnabled,
      onChanged: (val) => provider.toggleFeature(featureKey, val),
      title: Text(
        provider.getFeatureName(featureKey),
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w700,
          color: isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight,
        ),
      ),
      subtitle: Text(
        isEnabled ? 'Active on dashboard' : 'Hidden from view',
        style: TextStyle(
          fontSize: 12,
          color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
        ),
      ),
      activeThumbColor: AppTheme.primaryColor,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
    );
  }
}
