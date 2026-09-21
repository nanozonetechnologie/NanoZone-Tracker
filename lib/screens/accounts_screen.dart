import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/account_model.dart';
import '../providers/account_provider.dart';
import '../theme/app_theme.dart';

class AccountsScreen extends StatefulWidget {
  const AccountsScreen({super.key});

  @override
  State<AccountsScreen> createState() => _AccountsScreenState();
}

class _AccountsScreenState extends State<AccountsScreen> {
  static const _primaryColor = Color(0xFF6366F1);
  static const _bankColor = Color(0xFF10B981);
  static const _creditCardColor = Color(0xFFF59E0B);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Provider.of<AccountProvider>(context, listen: false).init();
    });
  }

  void _showAddAccountSheet(BuildContext context, {Account? editAccount}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accountProvider = Provider.of<AccountProvider>(context, listen: false);

    final nameController = TextEditingController(text: editAccount?.name ?? '');
    final balanceController = TextEditingController(
      text: editAccount?.balance != null ? editAccount!.balance.toStringAsFixed(0) : '',
    );

    AccountType selectedType = editAccount?.type ?? AccountType.bank;
    String selectedColor = editAccount?.colorHex ?? '6366F1';
    bool isDefault = editAccount?.isDefault ?? false;

    final colors = [
      '6366F1', '10B981', 'F59E0B', 'EF4444', '3B82F6', '8B5CF6',
      'EC4899', '06B6D4', '84CC16', '64748B',
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setSheetState) => Container(
          decoration: BoxDecoration(
            color: isDark ? AppTheme.surfaceDark : AppTheme.surfaceLight,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          ),
          padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 24),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40, height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.withAlpha(80),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [_primaryColor, _primaryColor.withAlpha(180)],
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        editAccount != null ? Icons.edit_rounded : Icons.add_card_rounded,
                        color: Colors.white, size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            editAccount != null ? 'Edit Account' : 'Add Account',
                            style: AppTheme.heading3.copyWith(
                              color: isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight,
                            ),
                          ),
                          Text(
                            'Bank account or credit card',
                            style: AppTheme.caption.copyWith(
                              color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                Text('Account Type', style: AppTheme.labelLarge.copyWith(
                  color: isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight,
                )),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setSheetState(() => selectedType = AccountType.bank),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            color: selectedType == AccountType.bank
                                ? _bankColor.withAlpha(20)
                                : (isDark ? Colors.white.withAlpha(5) : Colors.grey.shade50),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: selectedType == AccountType.bank
                                  ? _bankColor
                                  : (isDark ? Colors.white.withAlpha(10) : Colors.grey.shade300),
                              width: selectedType == AccountType.bank ? 2 : 1,
                            ),
                          ),
                          child: Column(
                            children: [
                              Icon(Icons.account_balance_rounded,
                                color: selectedType == AccountType.bank ? _bankColor : Colors.grey,
                                size: 28,
                              ),
                              const SizedBox(height: 6),
                              Text('Bank Account',
                                style: TextStyle(
                                  color: selectedType == AccountType.bank
                                      ? _bankColor
                                      : (isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight),
                                  fontWeight: selectedType == AccountType.bank ? FontWeight.w800 : FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setSheetState(() => selectedType = AccountType.creditCard),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            color: selectedType == AccountType.creditCard
                                ? _creditCardColor.withAlpha(20)
                                : (isDark ? Colors.white.withAlpha(5) : Colors.grey.shade50),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: selectedType == AccountType.creditCard
                                  ? _creditCardColor
                                  : (isDark ? Colors.white.withAlpha(10) : Colors.grey.shade300),
                              width: selectedType == AccountType.creditCard ? 2 : 1,
                            ),
                          ),
                          child: Column(
                            children: [
                              Icon(Icons.credit_card_rounded,
                                color: selectedType == AccountType.creditCard ? _creditCardColor : Colors.grey,
                                size: 28,
                              ),
                              const SizedBox(height: 6),
                              Text('Credit Card',
                                style: TextStyle(
                                  color: selectedType == AccountType.creditCard
                                      ? _creditCardColor
                                      : (isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight),
                                  fontWeight: selectedType == AccountType.creditCard ? FontWeight.w800 : FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                Text(
                  selectedType == AccountType.bank ? 'Bank Name' : 'Card Name',
                  style: AppTheme.labelLarge.copyWith(
                    color: isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight,
                  ),
                ),
                const SizedBox(height: 8),
                _buildTextField(
                  nameController,
                  '',
                  selectedType == AccountType.bank
                      ? 'e.g., HDFC, SBI, ICICI'
                      : 'e.g., HDFC Millennia, ICICI Amazon',
                  isDark,
                ),
                const SizedBox(height: 16),

                Text(
                  'Initial Balance',
                  style: AppTheme.labelLarge.copyWith(
                    color: isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight,
                  ),
                ),
                const SizedBox(height: 8),
                _buildTextField(
                  balanceController,
                  '₹ ',
                  '0.00',
                  isDark,
                  isNumber: true,
                ),
                const SizedBox(height: 20),

                Text('Card / Badge Color', style: AppTheme.labelLarge.copyWith(
                  color: isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight,
                )),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: colors.map((colorHex) {
                    final color = Color(int.parse('FF$colorHex', radix: 16));
                    final isSelected = selectedColor == colorHex;
                    return GestureDetector(
                      onTap: () => setSheetState(() => selectedColor = colorHex),
                      child: Container(
                        width: 38, height: 38,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected ? Colors.white : Colors.transparent,
                            width: 3,
                          ),
                          boxShadow: isSelected ? [
                            BoxShadow(color: color.withAlpha(100), blurRadius: 8, spreadRadius: 2),
                          ] : null,
                        ),
                        child: isSelected
                            ? const Icon(Icons.check, color: Colors.white, size: 18)
                            : null,
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),

                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: AppTheme.cardDecoration(context),
                  child: Row(
                    children: [
                      Icon(Icons.star_rounded, color: isDefault ? Colors.amber : Colors.grey, size: 24),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Set as Default Account', style: AppTheme.bodyLarge.copyWith(
                              fontWeight: FontWeight.w700,
                              color: isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight,
                            )),
                            Text('Default payment option for new expenses', style: AppTheme.caption.copyWith(
                              color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
                            )),
                          ],
                        ),
                      ),
                      Switch(
                        value: isDefault,
                        onChanged: (val) => setSheetState(() => isDefault = val),
                        activeThumbColor: _primaryColor,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(ctx).pop(),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          if (nameController.text.trim().isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Please enter an account name'), backgroundColor: Colors.red),
                            );
                            return;
                          }

                          final initialBal = double.tryParse(balanceController.text.trim()) ?? 0.0;

                          try {
                            if (editAccount != null) {
                              await accountProvider.updateAccount(
                                id: editAccount.id!,
                                name: nameController.text.trim(),
                                type: selectedType,
                                balance: initialBal,
                                colorHex: selectedColor,
                              );
                              if (isDefault) {
                                await accountProvider.setDefaultAccount(editAccount.id!);
                              }
                            } else {
                              await accountProvider.addAccount(
                                name: nameController.text.trim(),
                                type: selectedType,
                                balance: initialBal,
                                colorHex: selectedColor,
                                isDefault: isDefault,
                              );
                            }

                            if (!ctx.mounted) return;
                            Navigator.of(ctx).pop();
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(editAccount != null ? 'Account updated' : 'Account added'),
                                backgroundColor: AppTheme.successColor,
                              ),
                            );
                          } catch (e) {
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
                            );
                          }
                        },
                        child: Text(editAccount != null ? 'Update' : 'Add'),
                      ),
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

  Widget _buildTextField(TextEditingController controller, String prefix, String hint, bool isDark, {bool isNumber = false}) {
    return Container(
      decoration: AppTheme.cardDecoration(context),
      child: TextField(
        controller: controller,
        keyboardType: isNumber ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.text,
        decoration: InputDecoration(
          prefixText: prefix.isNotEmpty ? prefix : null,
          hintText: hint,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(16),
        ),
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, Account account) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Delete Account'),
        content: Text('Delete "${account.name}"? Expenses linked to this account will become unassigned.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              await Provider.of<AccountProvider>(context, listen: false).deleteAccount(account.id!);
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Account deleted'), backgroundColor: Colors.red),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accountProvider = Provider.of<AccountProvider>(context);
    final accounts = accountProvider.accounts;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.backgroundDark : AppTheme.backgroundLight,
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Container(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: AppTheme.primaryGradient,
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
                        Expanded(
                          child: Text('My Accounts & Cards', style: AppTheme.heading3.copyWith(color: Colors.white)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: _buildSummaryCard(
                            'Bank Accounts',
                            '${accountProvider.bankAccounts.length}',
                            Icons.account_balance_rounded,
                            _bankColor,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildSummaryCard(
                            'Credit Cards',
                            '${accountProvider.creditCards.length}',
                            Icons.credit_card_rounded,
                            _creditCardColor,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            SliverPadding(
              padding: const EdgeInsets.all(20),
              sliver: accounts.isEmpty
                  ? SliverToBoxAdapter(
                      child: Center(
                        child: Column(
                          children: [
                            const SizedBox(height: 60),
                            Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: _primaryColor.withAlpha(15),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(Icons.account_balance_wallet_outlined, size: 64, color: _primaryColor.withAlpha(180)),
                            ),
                            const SizedBox(height: 24),
                            Text(
                              'No Accounts Added Yet',
                              style: AppTheme.heading4.copyWith(
                                color: isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Track expenses per bank account or credit card',
                              textAlign: TextAlign.center,
                              style: AppTheme.bodyMedium.copyWith(
                                color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
                              ),
                            ),
                            const SizedBox(height: 24),
                            ElevatedButton.icon(
                              onPressed: () => _showAddAccountSheet(context),
                              icon: const Icon(Icons.add_rounded),
                              label: const Text('Add Account'),
                            ),
                          ],
                        ),
                      ),
                    )
                  : SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final account = accounts[index];
                          return _buildAccountCard(context, account, isDark);
                        },
                        childCount: accounts.length,
                      ),
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: accounts.isNotEmpty
          ? Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: const LinearGradient(colors: AppTheme.primaryGradient),
                boxShadow: AppTheme.shadowSmall,
              ),
              child: FloatingActionButton(
                onPressed: () => _showAddAccountSheet(context),
                backgroundColor: Colors.transparent,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                child: const Icon(Icons.add_rounded, size: 28, color: Colors.white),
              ),
            )
          : null,
    );
  }

  Widget _buildSummaryCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(20),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(color: Colors.white.withAlpha(180), fontSize: 11, fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(value, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountCard(BuildContext context, Account account, bool isDark) {
    final color = Color(int.parse('FF${account.colorHex ?? '6366F1'}', radix: 16));
    final isBank = account.type == AccountType.bank;

    return GestureDetector(
      onTap: () => _showAddAccountSheet(context, editAccount: account),
      onLongPress: () => _showDeleteConfirmation(context, account),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(18),
        decoration: AppTheme.cardDecoration(context),
        child: Row(
          children: [
            Container(
              width: 52, height: 52,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [color, color.withAlpha(180)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                isBank ? Icons.account_balance_rounded : Icons.credit_card_rounded,
                color: Colors.white,
                size: 26,
              ),
            ),
            const SizedBox(width: 16),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          account.name,
                          style: AppTheme.bodyLarge.copyWith(
                            fontWeight: FontWeight.w800,
                            color: isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight,
                          ),
                        ),
                      ),
                      if (account.isDefault)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.amber.withAlpha(30),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.star_rounded, color: Colors.amber, size: 14),
                              const SizedBox(width: 2),
                              Text('Default', style: TextStyle(color: Colors.amber.shade700, fontSize: 10, fontWeight: FontWeight.w800)),
                            ],
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${isBank ? 'Bank Account' : 'Credit Card'} • ₹${account.balance.toStringAsFixed(0)}',
                    style: AppTheme.caption.copyWith(
                      color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
                    ),
                  ),
                ],
              ),
            ),

            Icon(
              Icons.chevron_right_rounded,
              color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
              size: 24,
            ),
          ],
        ),
      ),
    );
  }
}
