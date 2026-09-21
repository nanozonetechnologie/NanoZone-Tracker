import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/savings_goal_provider.dart';
import '../models/savings_goal_model.dart';
import '../theme/app_theme.dart';

class SavingsGoalsScreen extends StatefulWidget {
  const SavingsGoalsScreen({super.key});

  @override
  State<SavingsGoalsScreen> createState() => _SavingsGoalsScreenState();
}

class _SavingsGoalsScreenState extends State<SavingsGoalsScreen> with SingleTickerProviderStateMixin {
  bool _showCompleted = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  // Predefined goal icons
  static const Map<String, IconData> goalIcons = {
    'car': Icons.directions_car_rounded,
    'home': Icons.home_rounded,
    'vacation': Icons.flight_rounded,
    'education': Icons.school_rounded,
    'emergency': Icons.health_and_safety_rounded,
    'wedding': Icons.favorite_rounded,
    'electronics': Icons.devices_rounded,
    'business': Icons.business_rounded,
    'retirement': Icons.elderly_rounded,
    'other': Icons.savings_rounded,
  };

  // Predefined goal colors
  static const List<Color> goalColors = [
    Color(0xFF1A237E), // Deep Indigo
    Color(0xFF00C853), // Green
    Color(0xFFFF6B6B), // Coral
    Color(0xFF7C4DFF), // Purple
    Color(0xFFFFAB00), // Amber
    Color(0xFF00BFA5), // Teal
    Color(0xFFE91E63), // Pink
    Color(0xFF00B0FF), // Sky Blue
    Color(0xFFFF5722), // Deep Orange
    Color(0xFF607D8B), // Blue Grey
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    Future.delayed(Duration.zero, () {
      if (!mounted) return;
      Provider.of<SavingsGoalProvider>(context, listen: false).fetchAllGoals();
    });
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  IconData _getIconForGoal(String? iconName) {
    return goalIcons[iconName] ?? Icons.savings_rounded;
  }

  Color _getColorForGoal(String? colorHex) {
    if (colorHex == null) return AppTheme.primaryColor;
    try {
      return Color(int.parse(colorHex, radix: 16) + 0xFF000000);
    } catch (e) {
      return AppTheme.primaryColor;
    }
  }

  void _showAddGoalDialog() {
    _showGoalDialog(null);
  }

  void _showEditGoalDialog(SavingsGoal goal) {
    _showGoalDialog(goal);
  }

  void _showGoalDialog(SavingsGoal? existingGoal) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isEditing = existingGoal != null;
    final nameController = TextEditingController(text: existingGoal?.name ?? '');
    final descController = TextEditingController(text: existingGoal?.description ?? '');
    final amountController = TextEditingController(
      text: existingGoal?.targetAmount.toStringAsFixed(0) ?? '',
    );
    DateTime targetDate = existingGoal?.targetDate ?? DateTime.now().add(const Duration(days: 365));
    String selectedIcon = existingGoal?.iconName ?? 'other';
    Color selectedColor = _getColorForGoal(existingGoal?.colorHex);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => Container(
          height: MediaQuery.of(context).size.height * 0.85,
          decoration: BoxDecoration(
            color: isDark ? AppTheme.surfaceDark : AppTheme.surfaceLight,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(colors: AppTheme.goldGradient),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                ),
                child: Column(
                  children: [
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(80),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withAlpha(30),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(
                            isEditing ? Icons.edit_rounded : Icons.flag_rounded,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isEditing ? 'Edit Goal' : 'Create New Goal',
                                style: AppTheme.heading3.copyWith(color: Colors.white),
                              ),
                              Text(
                                'Set your savings target',
                                style: AppTheme.caption.copyWith(color: Colors.white.withAlpha(200)),
                              ),
                            ],
                          ),
                        ),
                        GestureDetector(
                          onTap: () => Navigator.of(ctx).pop(),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white.withAlpha(25),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.close_rounded, color: Colors.white, size: 20),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Form Content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Goal Name
                      Text('Goal Name', style: AppTheme.labelLarge.copyWith(
                        color: isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight,
                      )),
                      const SizedBox(height: 8),
                      TextField(
                        controller: nameController,
                        decoration: const InputDecoration(
                          hintText: 'e.g., New Car, Vacation, Emergency Fund',
                          prefixIcon: Icon(Icons.flag_rounded),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Description
                      Text('Description (Optional)', style: AppTheme.labelLarge.copyWith(
                        color: isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight,
                      )),
                      const SizedBox(height: 8),
                      TextField(
                        controller: descController,
                        maxLines: 2,
                        decoration: const InputDecoration(
                          hintText: 'Add some details about your goal',
                          prefixIcon: Icon(Icons.notes_rounded),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Target Amount
                      Text('Target Amount', style: AppTheme.labelLarge.copyWith(
                        color: isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight,
                      )),
                      const SizedBox(height: 8),
                      TextField(
                        controller: amountController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          prefixText: '₹ ',
                          hintText: 'Enter target amount',
                          prefixIcon: Icon(Icons.account_balance_wallet_rounded),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Target Date
                      Text('Target Date', style: AppTheme.labelLarge.copyWith(
                        color: isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight,
                      )),
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: targetDate,
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now().add(const Duration(days: 365 * 20)),
                          );
                          if (picked != null) {
                            setDialogState(() => targetDate = picked);
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isDark ? AppTheme.cardDark : Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isDark ? Colors.white.withAlpha(10) : Colors.grey.shade200,
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.calendar_today_rounded, color: AppTheme.primaryColor),
                              const SizedBox(width: 12),
                              Text(
                                DateFormat('MMMM dd, yyyy').format(targetDate),
                                style: AppTheme.bodyLarge.copyWith(
                                  color: isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight,
                                ),
                              ),
                              const Spacer(),
                              const Icon(Icons.edit_rounded, size: 18, color: AppTheme.textSecondaryLight),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Icon Selection
                      Text('Choose Icon', style: AppTheme.labelLarge.copyWith(
                        color: isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight,
                      )),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: goalIcons.entries.map((entry) {
                          final isSelected = selectedIcon == entry.key;
                          return GestureDetector(
                            onTap: () => setDialogState(() => selectedIcon = entry.key),
                            child: AnimatedContainer(
                              duration: AppTheme.animationFast,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                gradient: isSelected ? LinearGradient(colors: [selectedColor, selectedColor.withAlpha(180)]) : null,
                                color: isSelected ? null : (isDark ? AppTheme.cardDark : Colors.grey.shade100),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: isSelected ? selectedColor : (isDark ? Colors.white.withAlpha(10) : Colors.grey.shade200),
                                  width: isSelected ? 2 : 1,
                                ),
                                boxShadow: isSelected ? [
                                  BoxShadow(color: selectedColor.withAlpha(40), blurRadius: 8, offset: const Offset(0, 2))
                                ] : null,
                              ),
                              child: Icon(
                                entry.value,
                                color: isSelected ? Colors.white : (isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight),
                                size: 24,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 24),

                      // Color Selection
                      Text('Choose Color', style: AppTheme.labelLarge.copyWith(
                        color: isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight,
                      )),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: goalColors.map((color) {
                          final isSelected = selectedColor.toARGB32() == color.toARGB32();
                          return GestureDetector(
                            onTap: () => setDialogState(() => selectedColor = color),
                            child: AnimatedContainer(
                              duration: AppTheme.animationFast,
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: color,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isSelected ? Colors.white : Colors.transparent,
                                  width: 3,
                                ),
                                boxShadow: isSelected ? [
                                  BoxShadow(color: color.withAlpha(100), blurRadius: 12, spreadRadius: 2)
                                ] : [
                                  BoxShadow(color: color.withAlpha(40), blurRadius: 8)
                                ],
                              ),
                              child: isSelected
                                  ? const Icon(Icons.check_rounded, color: Colors.white, size: 22)
                                  : null,
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),

              // Action Buttons
              Container(
                padding: EdgeInsets.fromLTRB(24, 16, 24, MediaQuery.of(context).padding.bottom + 16),
                decoration: BoxDecoration(
                  color: isDark ? AppTheme.cardDark : AppTheme.cardLight,
                  border: Border(top: BorderSide(color: isDark ? Colors.white.withAlpha(10) : Colors.grey.shade200)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(ctx).pop(),
                        style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: AppTheme.goldGradient),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [BoxShadow(color: AppTheme.secondaryColor.withAlpha(80), blurRadius: 12, offset: const Offset(0, 4))],
                        ),
                        child: ElevatedButton(
                          onPressed: () async {
                            if (nameController.text.trim().isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Please enter a goal name')),
                              );
                              return;
                            }

                            final amount = double.tryParse(amountController.text);
                            if (amount == null || amount <= 0) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Please enter a valid target amount')),
                              );
                              return;
                            }

                            final colorHex = (selectedColor.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0');

                            if (isEditing) {
                              await Provider.of<SavingsGoalProvider>(context, listen: false).updateGoal(
                                id: existingGoal.id!,
                                name: nameController.text.trim(),
                                description: descController.text.trim().isEmpty ? null : descController.text.trim(),
                                targetAmount: amount,
                                targetDate: targetDate,
                                iconName: selectedIcon,
                                colorHex: colorHex,
                              );
                            } else {
                              await Provider.of<SavingsGoalProvider>(context, listen: false).addGoal(
                                name: nameController.text.trim(),
                                description: descController.text.trim().isEmpty ? null : descController.text.trim(),
                                targetAmount: amount,
                                targetDate: targetDate,
                                iconName: selectedIcon,
                                colorHex: colorHex,
                              );
                            }

                            if (!ctx.mounted) return;
                            Navigator.of(ctx).pop();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: Text(
                            isEditing ? 'Update Goal' : 'Create Goal',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddMoneyDialog(SavingsGoal goal) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final amountController = TextEditingController();
    final color = _getColorForGoal(goal.colorHex);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: isDark ? AppTheme.surfaceDark : AppTheme.surfaceLight,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.withAlpha(80),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [color, color.withAlpha(180)]),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(_getIconForGoal(goal.iconName), color: Colors.white, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Add Money', style: AppTheme.heading3.copyWith(
                        color: isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight,
                      )),
                      Text(goal.name, style: AppTheme.caption.copyWith(color: color)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Progress Preview
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color.withAlpha(15),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: color.withAlpha(30)),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Current', style: AppTheme.caption.copyWith(
                        color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
                      )),
                      Text('Target', style: AppTheme.caption.copyWith(
                        color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
                      )),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('₹${goal.currentAmount.toStringAsFixed(0)}', style: AppTheme.heading4.copyWith(color: color)),
                      Text('₹${goal.targetAmount.toStringAsFixed(0)}', style: AppTheme.heading4.copyWith(
                        color: isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight,
                      )),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: goal.progressPercentage,
                      minHeight: 8,
                      backgroundColor: color.withAlpha(30),
                      valueColor: AlwaysStoppedAnimation<Color>(color),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              autofocus: true,
              decoration: InputDecoration(
                labelText: 'Amount to Add',
                prefixText: '₹ ',
                prefixIcon: Icon(Icons.add_rounded, color: color),
              ),
            ),
            const SizedBox(height: 24),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [color, color.withAlpha(180)]),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [BoxShadow(color: color.withAlpha(80), blurRadius: 12, offset: const Offset(0, 4))],
                    ),
                    child: ElevatedButton(
                      onPressed: () async {
                        final amount = double.tryParse(amountController.text);
                        if (amount == null || amount <= 0) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Please enter a valid amount')),
                          );
                          return;
                        }

                        await Provider.of<SavingsGoalProvider>(context, listen: false)
                            .addToGoal(goal.id!, amount);

                        if (!ctx.mounted) return;
                        Navigator.of(ctx).pop();

                        if (!ctx.mounted) return;
                        final updatedGoal = Provider.of<SavingsGoalProvider>(ctx, listen: false)
                            .getGoalById(goal.id!);

                        if (updatedGoal != null && updatedGoal.isCompleted) {
                          _showGoalCompletedDialog(updatedGoal);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text('Add Money', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showGoalCompletedDialog(SavingsGoal goal) {
    final color = _getColorForGoal(goal.colorHex);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                gradient: LinearGradient(colors: AppTheme.goldGradient),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.celebration_rounded, color: Colors.white, size: 48),
            ),
            const SizedBox(height: 24),
            const Text('Congratulations! 🎉', style: AppTheme.heading2),
            const SizedBox(height: 12),
            Text(
              'You\'ve reached your goal',
              style: AppTheme.bodyMedium.copyWith(color: AppTheme.textSecondaryLight),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: color.withAlpha(15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(goal.name, style: AppTheme.heading4.copyWith(color: color)),
            ),
            const SizedBox(height: 16),
            Text(
              '₹${goal.currentAmount.toStringAsFixed(0)}',
              style: AppTheme.heading1.copyWith(color: AppTheme.successColor),
            ),
            const SizedBox(height: 8),
          ],
        ),
        actions: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: ElevatedButton(
              onPressed: () => Navigator.of(ctx).pop(),
              style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
              child: const Text('Awesome!'),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.backgroundDark : AppTheme.backgroundLight,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Consumer<SavingsGoalProvider>(
            builder: (ctx, provider, _) {
              final activeGoals = provider.activeGoals;
              final completedGoals = provider.completedGoals;

              return RefreshIndicator(
                onRefresh: () async {
                  await provider.fetchAllGoals();
                },
                color: AppTheme.primaryColor,
                child: CustomScrollView(
                  slivers: [
                    // Premium Header
                    SliverToBoxAdapter(
                      child: _buildPremiumHeader(context, isDark, provider),
                    ),

                    // Content
                    SliverPadding(
                      padding: const EdgeInsets.all(20),
                      sliver: SliverList(
                        delegate: SliverChildListDelegate([
                          // Summary Cards
                          _buildSummaryRow(context, isDark, provider),

                          const SizedBox(height: 24),

                          // Active Goals Section
                          if (activeGoals.isNotEmpty) ...[
                            _buildSectionHeader(isDark, '🎯 Active Goals', activeGoals.length, AppTheme.primaryColor),
                            const SizedBox(height: 16),
                            ...activeGoals.map((goal) => _buildGoalCard(context, goal, isDark)),
                          ] else
                            _buildEmptyState(isDark),

                          // Completed Goals Section
                          if (completedGoals.isNotEmpty) ...[
                            const SizedBox(height: 24),
                            GestureDetector(
                              onTap: () => setState(() => _showCompleted = !_showCompleted),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                decoration: BoxDecoration(
                                  color: AppTheme.successColor.withAlpha(15),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(color: AppTheme.successColor.withAlpha(30)),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.check_circle_rounded, color: AppTheme.successColor, size: 22),
                                    const SizedBox(width: 10),
                                    Text(
                                      'Completed Goals',
                                      style: AppTheme.bodyLarge.copyWith(
                                        color: AppTheme.successColor,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const Spacer(),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: AppTheme.successColor.withAlpha(20),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        '${completedGoals.length}',
                                        style: AppTheme.labelLarge.copyWith(color: AppTheme.successColor),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Icon(
                                      _showCompleted ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                                      color: AppTheme.successColor,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            if (_showCompleted) ...[
                              const SizedBox(height: 16),
                              ...completedGoals.map((goal) => _buildGoalCard(context, goal, isDark, isCompleted: true)),
                            ],
                          ],

                          const SizedBox(height: 100),
                        ]),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: AppTheme.goldGradient),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF000000).withAlpha(80),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: FloatingActionButton.extended(
          onPressed: _showAddGoalDialog,
          backgroundColor: Colors.transparent,
          elevation: 0,
          icon: const Icon(Icons.add_rounded, color: Colors.white),
          label: const Text('New Goal', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
        ),
      ),
    );
  }

  Widget _buildPremiumHeader(BuildContext context, bool isDark, SavingsGoalProvider provider) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: AppTheme.goldGradient,
        ),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(32)),
        boxShadow: [
          BoxShadow(
            color: AppTheme.secondaryColor.withAlpha(50),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
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
              Expanded(
                child: Text('Savings Goals', style: AppTheme.heading3.copyWith(color: Colors.white)),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total Saved',
                      style: AppTheme.caption.copyWith(color: Colors.white.withAlpha(200)),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '₹${provider.totalCurrentAmount.toStringAsFixed(0)}',
                      style: AppTheme.heading1.copyWith(color: Colors.white),
                    ),
                    Text(
                      'of ₹${provider.totalTargetAmount.toStringAsFixed(0)}',
                      style: AppTheme.bodyMedium.copyWith(color: Colors.white.withAlpha(180)),
                    ),
                  ],
                ),
              ),
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 80,
                    height: 80,
                    child: CircularProgressIndicator(
                      value: provider.overallProgress,
                      strokeWidth: 8,
                      backgroundColor: Colors.white.withAlpha(40),
                      valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                  Text(
                    '${(provider.overallProgress * 100).toStringAsFixed(0)}%',
                    style: AppTheme.heading4.copyWith(color: Colors.white),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(BuildContext context, bool isDark, SavingsGoalProvider provider) {
    return Row(
      children: [
        Expanded(
          child: _buildMiniStatCard(
            isDark,
            'Active',
            '${provider.activeGoals.length}',
            Icons.flag_rounded,
            AppTheme.primaryColor,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildMiniStatCard(
            isDark,
            'Completed',
            '${provider.completedGoals.length}',
            Icons.check_circle_rounded,
            AppTheme.successColor,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildMiniStatCard(
            isDark,
            'Total',
            '${provider.goals.length}',
            Icons.stacked_bar_chart_rounded,
            AppTheme.accentSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildMiniStatCard(bool isDark, String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.cardDark : AppTheme.cardLight,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: isDark ? Colors.white.withAlpha(10) : color.withAlpha(30)),
        boxShadow: AppTheme.shadowSmall,
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withAlpha(20),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: AppTheme.heading3.copyWith(
              color: isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: AppTheme.caption.copyWith(
              color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(bool isDark, String title, int count, Color color) {
    return Row(
      children: [
        Text(
          title,
          style: AppTheme.heading4.copyWith(
            color: isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight,
          ),
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: color.withAlpha(15),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            '$count ${count == 1 ? 'goal' : 'goals'}',
            style: AppTheme.caption.copyWith(color: color, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.cardDark : AppTheme.cardLight,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: isDark ? Colors.white.withAlpha(10) : Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: AppTheme.goldGradient.map((c) => c.withAlpha(30)).toList()),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.flag_outlined, size: 48, color: AppTheme.secondaryColor),
          ),
          const SizedBox(height: 20),
          Text(
            'No savings goals yet',
            style: AppTheme.heading4.copyWith(
              color: isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Create your first goal and start\nsaving towards your dreams!',
            textAlign: TextAlign.center,
            style: AppTheme.bodyMedium.copyWith(
              color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGoalCard(BuildContext context, SavingsGoal goal, bool isDark, {bool isCompleted = false}) {
    final color = _getColorForGoal(goal.colorHex);
    final icon = _getIconForGoal(goal.iconName);

    return GestureDetector(
      onTap: () => _showGoalDetailsDialog(goal),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.cardDark : AppTheme.cardLight,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: isDark ? Colors.white.withAlpha(10) : Colors.grey.shade200),
          boxShadow: AppTheme.shadowSmall,
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [color, color.withAlpha(180)]),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [BoxShadow(color: color.withAlpha(40), blurRadius: 8, offset: const Offset(0, 2))],
                    ),
                    child: Icon(icon, color: Colors.white, size: 26),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          goal.name,
                          style: AppTheme.heading4.copyWith(
                            color: isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight,
                          ),
                        ),
                        if (goal.description != null && goal.description!.isNotEmpty)
                          Text(
                            goal.description!,
                            style: AppTheme.caption.copyWith(
                              color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                  if (!isCompleted)
                    GestureDetector(
                      onTap: () => _showAddMoneyDialog(goal),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: color.withAlpha(20),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(Icons.add_rounded, color: color, size: 22),
                      ),
                    ),
                  if (isCompleted)
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppTheme.successColor.withAlpha(20),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.check_rounded, color: AppTheme.successColor, size: 22),
                    ),
                ],
              ),

              const SizedBox(height: 20),

              // Progress
              Row(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: goal.progressPercentage,
                        minHeight: 10,
                        backgroundColor: color.withAlpha(30),
                        valueColor: AlwaysStoppedAnimation<Color>(color),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: color.withAlpha(20),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${(goal.progressPercentage * 100).toStringAsFixed(0)}%',
                      style: AppTheme.labelLarge.copyWith(color: color),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              // Amount Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '₹${goal.currentAmount.toStringAsFixed(0)} / ₹${goal.targetAmount.toStringAsFixed(0)}',
                    style: AppTheme.bodyLarge.copyWith(
                      color: isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (!isCompleted && !goal.isOverdue)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white.withAlpha(5) : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.timer_outlined, size: 14, color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight),
                          const SizedBox(width: 4),
                          Text(
                            goal.daysRemaining > 30 ? '${goal.monthsRemaining}mo left' : '${goal.daysRemaining}d left',
                            style: AppTheme.caption.copyWith(
                              color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (goal.isOverdue)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.errorColor.withAlpha(15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text('Overdue', style: AppTheme.caption.copyWith(color: AppTheme.errorColor)),
                    ),
                ],
              ),

              // Monthly Savings Suggestion
              if (!isCompleted && goal.remainingAmount > 0 && goal.monthsRemaining > 0) ...[
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: goal.isOnTrack ? AppTheme.successColor.withAlpha(10) : AppTheme.warningColor.withAlpha(10),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: goal.isOnTrack ? AppTheme.successColor.withAlpha(30) : AppTheme.warningColor.withAlpha(30),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        goal.isOnTrack ? Icons.trending_up_rounded : Icons.info_outline_rounded,
                        size: 18,
                        color: goal.isOnTrack ? AppTheme.successColor : AppTheme.warningColor,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Save ₹${goal.requiredMonthlySavings.toStringAsFixed(0)}/month to reach goal',
                          style: AppTheme.caption.copyWith(
                            color: goal.isOnTrack ? AppTheme.successColor : AppTheme.warningColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showGoalDetailsDialog(SavingsGoal goal) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = _getColorForGoal(goal.colorHex);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: isDark ? AppTheme.surfaceDark : AppTheme.surfaceLight,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.withAlpha(80),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),

            // Goal Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [color, color.withAlpha(180)]),
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [BoxShadow(color: color.withAlpha(40), blurRadius: 12, offset: const Offset(0, 4))],
                  ),
                  child: Icon(_getIconForGoal(goal.iconName), color: Colors.white, size: 32),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(goal.name, style: AppTheme.heading3.copyWith(
                        color: isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight,
                      )),
                      if (goal.description != null && goal.description!.isNotEmpty)
                        Text(goal.description!, style: AppTheme.caption.copyWith(
                          color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
                        )),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Progress Section
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark ? AppTheme.cardDark : Colors.grey.shade50,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: isDark ? Colors.white.withAlpha(10) : Colors.grey.shade200),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Progress', style: AppTheme.labelLarge.copyWith(
                        color: isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight,
                      )),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: color.withAlpha(20),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${(goal.progressPercentage * 100).toStringAsFixed(1)}%',
                          style: AppTheme.labelLarge.copyWith(color: color),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      value: goal.progressPercentage,
                      minHeight: 14,
                      backgroundColor: color.withAlpha(30),
                      valueColor: AlwaysStoppedAnimation<Color>(color),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildDetailColumn('Saved', '₹${goal.currentAmount.toStringAsFixed(0)}', isDark),
                      _buildDetailColumn('Remaining', '₹${goal.remainingAmount.toStringAsFixed(0)}', isDark),
                      _buildDetailColumn('Target', '₹${goal.targetAmount.toStringAsFixed(0)}', isDark),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Date Info
            Row(
              children: [
                Expanded(child: _buildInfoTile(isDark, 'Target Date', DateFormat('MMM dd, yyyy').format(goal.targetDate), Icons.calendar_today_rounded)),
                const SizedBox(width: 12),
                Expanded(child: _buildInfoTile(isDark, 'Time Left', goal.isOverdue ? 'Overdue' : (goal.daysRemaining > 30 ? '${goal.monthsRemaining} months' : '${goal.daysRemaining} days'), Icons.timer_rounded)),
              ],
            ),

            const SizedBox(height: 24),

            // Action Buttons
            Row(
              children: [
                if (!goal.isCompleted) ...[
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [color, color.withAlpha(180)]),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [BoxShadow(color: color.withAlpha(60), blurRadius: 10, offset: const Offset(0, 3))],
                      ),
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.of(ctx).pop();
                          _showAddMoneyDialog(goal);
                        },
                        icon: const Icon(Icons.add_rounded, color: Colors.white),
                        label: const Text('Add Money', style: TextStyle(color: Colors.white)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.of(ctx).pop();
                      _showEditGoalDialog(goal);
                    },
                    icon: const Icon(Icons.edit_rounded),
                    label: const Text('Edit'),
                    style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
                  ),
                ),
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: () async {
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (c) => AlertDialog(
                        title: const Text('Delete Goal'),
                        content: Text('Are you sure you want to delete "${goal.name}"?'),
                        actions: [
                          TextButton(onPressed: () => Navigator.of(c).pop(false), child: const Text('Cancel')),
                          TextButton(onPressed: () => Navigator.of(c).pop(true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
                        ],
                      ),
                    );
                    if (confirmed == true) {
                      if (!ctx.mounted) return;
                      await Provider.of<SavingsGoalProvider>(ctx, listen: false).deleteGoal(goal.id!);
                      if (!ctx.mounted) return;
                      Navigator.of(ctx).pop();
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppTheme.errorColor.withAlpha(15),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.delete_outline_rounded, color: AppTheme.errorColor),
                  ),
                ),
              ],
            ),

            SizedBox(height: MediaQuery.of(context).padding.bottom + 8),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailColumn(String label, String value, bool isDark) {
    return Column(
      children: [
        Text(label, style: AppTheme.caption.copyWith(
          color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
        )),
        const SizedBox(height: 4),
        Text(value, style: AppTheme.bodyLarge.copyWith(
          color: isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight,
          fontWeight: FontWeight.w600,
        )),
      ],
    );
  }

  Widget _buildInfoTile(bool isDark, String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.cardDark : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isDark ? Colors.white.withAlpha(10) : Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: AppTheme.caption.copyWith(
                  color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
                )),
                Text(value, style: AppTheme.bodyMedium.copyWith(
                  color: isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight,
                  fontWeight: FontWeight.w600,
                )),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

