import 'package:exptrackerforhybridos/app_constants.dart';
import 'package:exptrackerforhybridos/providers/expense_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class QuickAddExpenseForm extends StatefulWidget {
  const QuickAddExpenseForm({super.key});

  @override
  State<QuickAddExpenseForm> createState() => _QuickAddExpenseFormState();
}

class _QuickAddExpenseFormState extends State<QuickAddExpenseForm> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  String? _selectedCategory;
  String? _selectedPaymentMethod;

  late final List<DropdownMenuItem<String>> _categoryItems;
  late final List<DropdownMenuItem<String>> _paymentMethodItems;

  @override
  void initState() {
    super.initState();

    _categoryItems = categories.map((String category) {
      return DropdownMenuItem(
        value: category,
        child: Text(category),
      );
    }).toList();

    _paymentMethodItems = paymentMethods.map((String method) {
      return DropdownMenuItem(
        value: method,
        child: Text(method),
      );
    }).toList();
  }

  void _saveExpense() {
    if (_formKey.currentState!.validate()) {
      Provider.of<ExpenseProvider>(context, listen: false).addExpense(
        double.parse(_amountController.text),
        _selectedCategory!,
        DateTime.now(),
        _selectedPaymentMethod!,
        null, // No notes in quick add
      );
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text('Quick Add Expense', style: Theme.of(context).textTheme.titleLarge),
            TextFormField(
              controller: _amountController,
              decoration: const InputDecoration(labelText: 'Amount'),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter an amount.';
                }
                if (double.tryParse(value) == null) {
                  return 'Please enter a valid number.';
                }
                if (double.parse(value) <= 0) {
                  return 'Please enter an amount greater than 0.';
                }
                return null;
              },
            ),
            DropdownButtonFormField<String>(
              initialValue: _selectedCategory,
              decoration: const InputDecoration(labelText: 'Category'),
              items: _categoryItems,
              onChanged: (newValue) {
                setState(() {
                  _selectedCategory = newValue;
                });
              },
              validator: (value) =>
                  value == null ? 'Please select a category' : null,
            ),
            DropdownButtonFormField<String>(
              initialValue: _selectedPaymentMethod,
              decoration: const InputDecoration(labelText: 'Payment Method'),
              items: _paymentMethodItems,
              onChanged: (newValue) {
                setState(() {
                  _selectedPaymentMethod = newValue;
                });
              },
              validator: (value) =>
                  value == null ? 'Please select a payment method' : null,
            ),
            const SizedBox(height: 20),
            ElevatedButton(onPressed: _saveExpense, child: const Text('Save')),
          ],
        ),
      ),
    );
  }
}
