import 'package:exptrackerforhybridos/app_constants.dart';
import 'package:exptrackerforhybridos/models/expense_model.dart';
import 'package:exptrackerforhybridos/providers/expense_provider.dart';
import 'package:exptrackerforhybridos/providers/account_provider.dart';
import 'package:exptrackerforhybridos/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class AddExpenseScreen extends StatefulWidget {
  final Expense? expense;
  final double? prefilledAmount;
  final String? prefilledCategory;
  final String? prefilledPaymentMethod;
  final String? prefilledNotes;
  final DateTime? prefilledDate;

  const AddExpenseScreen({
    super.key,
    this.expense,
    this.prefilledAmount,
    this.prefilledCategory,
    this.prefilledPaymentMethod,
    this.prefilledNotes,
    this.prefilledDate,
  });

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();
  
  String? _selectedCategory;
  String? _selectedPaymentMethod;
  int? _selectedAccountId;
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _selectedPaymentMethod = widget.prefilledPaymentMethod ?? 'UPI';
    _notesController.text = widget.prefilledNotes ?? '';
    _selectedDate = widget.prefilledDate ?? DateTime.now();

    if (widget.expense != null) {
      _amountController.text = widget.expense!.amount.toString();
      _notesController.text = widget.expense!.notes ?? '';
      _selectedCategory = widget.expense!.category;
      _selectedPaymentMethod = widget.expense!.paymentMethod;
      _selectedDate = widget.expense!.date;
      _selectedAccountId = widget.expense!.accountId;
    } else if (widget.prefilledAmount != null) {
      _amountController.text = widget.prefilledAmount!.toStringAsFixed(0);
      _selectedCategory = widget.prefilledCategory;
    } else if (widget.prefilledCategory != null) {
      _selectedCategory = widget.prefilledCategory;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final accountProvider = Provider.of<AccountProvider>(context, listen: false);
      if (_selectedAccountId == null && accountProvider.defaultAccount != null) {
        setState(() => _selectedAccountId = accountProvider.defaultAccount!.id);
      }
    });
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    
    HapticFeedback.heavyImpact();
    final amount = double.parse(_amountController.text);
    
    final expenseProvider = Provider.of<ExpenseProvider>(context, listen: false);
    if (widget.expense == null) {
      expenseProvider.addExpense(
        amount,
        _selectedCategory ?? 'Other',
        _selectedDate,
        _selectedPaymentMethod,
        _notesController.text,
        accountId: _selectedAccountId,
      );
      if (_selectedAccountId != null) {
        Provider.of<AccountProvider>(context, listen: false).deductFromAccount(_selectedAccountId!, amount);
      }
    } else {
      expenseProvider.updateExpense(
        widget.expense!.id!,
        amount,
        _selectedCategory ?? 'Other',
        _selectedDate,
        _selectedPaymentMethod,
        _notesController.text,
        accountId: _selectedAccountId,
      );
    }
    
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.9,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.cardDark : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.withAlpha(50),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            
            Text(
              widget.expense == null ? 'Add Expense' : 'Edit Expense',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 24),
            
            Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _amountController,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w800),
                    decoration: const InputDecoration(
                      prefixText: '₹ ',
                      hintText: '0',
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                    ),
                    autofocus: widget.prefilledAmount == null && widget.expense == null,
                    validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
                  ),
                  const SizedBox(height: 20),
                  
                  _buildDropdown(
                    label: 'Category',
                    value: _selectedCategory,
                    items: categories,
                    onChanged: (v) => setState(() => _selectedCategory = v),
                    icon: Icons.category_rounded,
                  ),
                  
                  const SizedBox(height: 12),
                  _buildDatePicker(context, isDark),
                  const SizedBox(height: 12),
                  
                  _buildDropdown(
                    label: 'Payment Method',
                    value: _selectedPaymentMethod,
                    items: paymentMethods,
                    onChanged: (v) => setState(() => _selectedPaymentMethod = v),
                    icon: Icons.payment_rounded,
                  ),
                  
                  const SizedBox(height: 12),
                  
                  TextFormField(
                    controller: _notesController,
                    decoration: InputDecoration(
                      hintText: 'Add a note (optional)',
                      prefixIcon: const Icon(Icons.notes_rounded, size: 20),
                      fillColor: isDark ? Colors.white.withAlpha(5) : Colors.grey.shade50,
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                  
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _save,
                      child: Text(widget.expense == null ? 'Record Expense' : 'Update Expense'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdown({
    required String label,
    required String? value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
    required IconData icon,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withAlpha(5) : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? Colors.white10 : Colors.grey.shade200),
      ),
      child: DropdownButtonFormField<String>(
        initialValue: value,
        items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
        onChanged: onChanged,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, size: 20),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
        ),
        dropdownColor: isDark ? AppTheme.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
    );
  }

  Widget _buildDatePicker(BuildContext context, bool isDark) {
    return GestureDetector(
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: _selectedDate,
          firstDate: DateTime(2020),
          lastDate: DateTime.now(),
        );
        if (date != null) setState(() => _selectedDate = date);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withAlpha(5) : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isDark ? Colors.white10 : Colors.grey.shade200),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_month_rounded, size: 20, color: AppTheme.primaryColor),
            const SizedBox(width: 12),
            Text(
              DateFormat('MMMM dd, yyyy').format(_selectedDate),
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            const Spacer(),
            const Icon(Icons.chevron_right_rounded, size: 20, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}
