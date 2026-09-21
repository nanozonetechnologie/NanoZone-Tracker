import 'package:flutter/material.dart';
import 'package:exptrackerforhybridos/theme/app_theme.dart';

class HelpScreen extends StatefulWidget {
  const HelpScreen({super.key});

  @override
  State<HelpScreen> createState() => _HelpScreenState();
}

class _HelpScreenState extends State<HelpScreen> {
  String _searchQuery = '';
  int? _expandedIndex = 0; // Default first item open

  final List<Map<String, dynamic>> _guideTopics = [
    {
      'title': '1. Setting & Monitoring Monthly Budget',
      'category': 'Budgeting',
      'icon': Icons.account_balance_wallet_rounded,
      'color': const Color(0xFF6366F1),
      'content': '''
• How to Set Your Monthly Budget:
  1. On the Home Screen or Dashboard, tap the Budget card or "Set Budget".
  2. Enter your total target budget for the current month (e.g. ₹20,000) and tap Save.

• Live Budget Balance Tracking:
  - Your remaining balance is calculated live as: (Monthly Budget - Spent Expenses).
  - The color progress bar indicates your percentage spent.
  - If spending exceeds your set budget, the card shifts into a prominent "OVER BUDGET" alert mode.

💡 Pro Tip: Your set budget carries forward every month automatically unless you choose to update it!
''',
    },
    {
      'title': '2. 1-Tap Daily Favorites & Custom Prices',
      'category': 'Quick Add',
      'icon': Icons.bolt_rounded,
      'color': const Color(0xFF10B981),
      'content': '''
• Instant 1-Tap Expense Logging:
  - Tap any preset card on the Home Screen (Coffee, Meal, Fuel, Grocery) to log an expense in under 1 second!
  - You will receive haptic feedback and a floating toast confirmation.

• Customizing Preset Prices & Names:
  1. Long-press any 1-Tap Preset card on the Home Screen.
  2. A "Customize Preset" sheet opens.
  3. Enter your custom Preset Name and Default Price (e.g. Coffee ₹80 or Fuel ₹300).
  4. Tap "Save Preset". Your custom prices are stored permanently on your phone!

💡 Pro Tip: Customize presets for your exact daily habits to track daily spending without typing amounts!
''',
    },
    {
      'title': '3. Local Offline Backups (Export & Restore)',
      'category': 'Backup & Data',
      'icon': Icons.sd_storage_rounded,
      'color': const Color(0xFFF59E0B),
      'content': '''
• Exporting a Local JSON Backup:
  1. Go to Settings ⚙️ > "Local Storage & Backup".
  2. Tap "Export JSON Backup".
  3. Choose where to save your backup file (Files app, Google Drive, Email, or WhatsApp).

• Restoring Backup Data:
  1. Go to Settings ⚙️ > "Local Storage & Backup".
  2. Tap "Import JSON Backup".
  3. Pick your saved `.json` file from device files.
  4. Confirm restore. All expenses, budgets, savings goals, and accounts will be restored instantly!

⚠️ Note: NanoZon Tracker is 100% local and offline. All backups stay securely in your control!
''',
    },
    {
      'title': '4. App Lock & Biometric Security',
      'category': 'Security',
      'icon': Icons.security_rounded,
      'color': const Color(0xFFEC4899),
      'content': '''
• Toggling Biometric / Screen Lock:
  1. Go to Settings ⚙️ > "Security & App Lock".
  2. Toggle "Biometric / Screen Lock" ON or OFF.
  - Enabled: Requires fingerprint, Face ID, or device PIN every time the app launches.
  - Disabled: Opens directly to the Home screen for rapid access.

💡 Security Note: Authentication uses native Android/iOS biometric hardware. No passwords are sent to external servers.
''',
    },
    {
      'title': '5. Bank Accounts & Credit Cards',
      'category': 'Accounts',
      'icon': Icons.account_balance_rounded,
      'color': const Color(0xFF3B82F6),
      'content': '''
• Managing Accounts & Wallet:
  1. Open Settings ⚙️ > "My Accounts & Cards".
  2. Tap "+ Add Account" to link a Bank Account or Credit Card.
  3. Set an opening balance or credit limit.
  4. Tap the star ⭐ icon to mark your primary default account.

• Logging Expenses by Account:
  - When manually adding an expense, select which account was used to keep individual bank balances accurate.
''',
    },
    {
      'title': '6. Savings Goals & Milestone Celebrations',
      'category': 'Savings',
      'icon': Icons.flag_rounded,
      'color': const Color(0xFF8B5CF6),
      'content': '''
• Creating a Savings Target:
  1. On the Home Screen, tap "Goals" in the Quick Access grid.
  2. Tap "+ Create Goal", give it a name (e.g. New Laptop), target amount (₹50,000), target date, icon, and color.
  3. Tap "+ Add Money" whenever you allocate money towards the goal.
  4. Reach 100% completion to unlock a celebration milestone!
''',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final filteredTopics = _guideTopics.where((topic) {
      final title = (topic['title'] as String).toLowerCase();
      final category = (topic['category'] as String).toLowerCase();
      final content = (topic['content'] as String).toLowerCase();
      final query = _searchQuery.toLowerCase().trim();
      return title.contains(query) || category.contains(query) || content.contains(query);
    }).toList();

    return Scaffold(
      backgroundColor: isDark ? AppTheme.backgroundDark : AppTheme.backgroundLight,
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // Custom Header
            SliverToBoxAdapter(
              child: Container(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
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
                          'Help & User Guide',
                          style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Search Bar
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: AppTheme.shadowSmall,
                      ),
                      child: TextField(
                        onChanged: (val) {
                          setState(() {
                            _searchQuery = val;
                          });
                        },
                        style: const TextStyle(color: Colors.black87, fontSize: 14),
                        decoration: const InputDecoration(
                          hintText: 'Search guide topics (e.g. presets, budget, backup)...',
                          hintStyle: TextStyle(color: Colors.grey, fontSize: 13),
                          prefixIcon: Icon(Icons.search_rounded, color: AppTheme.primaryColor),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Guide Topics List
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
              sliver: filteredTopics.isEmpty
                  ? SliverToBoxAdapter(
                      child: Container(
                        padding: const EdgeInsets.all(32),
                        decoration: AppTheme.cardDecoration(context),
                        child: const Column(
                          children: [
                            Icon(Icons.help_outline_rounded, size: 48, color: Colors.grey),
                            SizedBox(height: 12),
                            Text('No matching guide topics found', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                            SizedBox(height: 4),
                            Text('Try searching for keywords like "preset" or "budget"', style: TextStyle(color: Colors.grey, fontSize: 12)),
                          ],
                        ),
                      ),
                    )
                  : SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final topic = filteredTopics[index];
                          final isExpanded = _expandedIndex == index;
                          final color = topic['color'] as Color;

                          return Container(
                            margin: const EdgeInsets.only(bottom: 14),
                            decoration: AppTheme.cardDecoration(context),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(24),
                              child: ExpansionTile(
                                key: Key('guide_tile_$index'),
                                initiallyExpanded: isExpanded,
                                onExpansionChanged: (expanded) {
                                  setState(() {
                                    _expandedIndex = expanded ? index : null;
                                  });
                                },
                                leading: Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: color.withAlpha(20),
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: Icon(topic['icon'] as IconData, color: color, size: 22),
                                ),
                                title: Text(
                                  topic['title'] as String,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                    color: isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight,
                                  ),
                                ),
                                subtitle: Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text(
                                    topic['category'] as String,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: color,
                                    ),
                                  ),
                                ),
                                children: [
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                                    child: Text(
                                      topic['content'] as String,
                                      style: TextStyle(
                                        fontSize: 13,
                                        height: 1.6,
                                        fontWeight: FontWeight.w500,
                                        color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                        childCount: filteredTopics.length,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
