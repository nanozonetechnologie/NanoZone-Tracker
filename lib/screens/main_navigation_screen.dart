import 'dart:ui';
import 'package:exptrackerforhybridos/screens/home_screen.dart';
import 'package:exptrackerforhybridos/screens/dashboard_screen.dart';
import 'package:exptrackerforhybridos/screens/view_all_expenses_screen.dart';
import 'package:exptrackerforhybridos/screens/add_expense_screen.dart';
import 'package:exptrackerforhybridos/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _selectedIndex = 0;
  
  final List<Widget> _pages = [
    const HomeScreen(),
    const DashboardScreen(),
    const ViewAllExpensesScreen(),
  ];

  void _onItemTapped(int index) {
    if (_selectedIndex == index) return;
    HapticFeedback.selectionClick();
    setState(() {
      _selectedIndex = index;
    });
  }

  void _showAddExpense() {
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const AddExpenseScreen(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      extendBody: true,
      body: _PageSwitcher(
        index: _selectedIndex,
        children: _pages,
      ),
      bottomNavigationBar: _ModernBottomNav(
        selectedIndex: _selectedIndex,
        onTap: _onItemTapped,
        onAddTap: _showAddExpense,
        isDark: isDark,
      ),
    );
  }
}

class _ModernBottomNav extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onTap;
  final VoidCallback onAddTap;
  final bool isDark;

  const _ModernBottomNav({
    required this.selectedIndex,
    required this.onTap,
    required this.onAddTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 76,
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 28),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF131B2E).withAlpha(200) : Colors.white.withAlpha(230),
        borderRadius: BorderRadius.circular(36),
        border: Border.all(
          color: isDark ? Colors.white.withAlpha(20) : Colors.black.withAlpha(8),
        ),
        boxShadow: AppTheme.shadowLarge,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(36),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _NavItem(
                  icon: Icons.home_rounded,
                  label: 'Home',
                  isSelected: selectedIndex == 0,
                  onTap: () => onTap(0),
                ),
                _NavItem(
                  icon: Icons.analytics_rounded,
                  label: 'Analytics',
                  isSelected: selectedIndex == 1,
                  onTap: () => onTap(1),
                ),
                
                // Centered Elevated Add Button
                GestureDetector(
                  onTap: onAddTap,
                  child: Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: AppTheme.primaryGradient,
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primaryColor.withAlpha(120),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.add_rounded, color: Colors.white, size: 30),
                  ),
                ),

                _NavItem(
                  icon: Icons.receipt_long_rounded,
                  label: 'History',
                  isSelected: selectedIndex == 2,
                  onTap: () => onTap(2),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = isSelected ? AppTheme.primaryColor : Colors.grey;
    
    return InkWell(
      onTap: onTap,
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryColor.withAlpha(20) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 24),
            if (isSelected) ...[
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  color: AppTheme.primaryColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _PageSwitcher extends StatelessWidget {
  final int index;
  final List<Widget> children;

  const _PageSwitcher({required this.index, required this.children});

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 350),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (Widget child, Animation<double> animation) {
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.03),
              end: Offset.zero,
            ).animate(animation),
            child: child,
          ),
        );
      },
      child: children[index],
    );
  }
}
