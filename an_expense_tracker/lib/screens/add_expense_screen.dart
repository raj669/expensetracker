import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/category.dart';

class AddExpenseScreen extends StatefulWidget {
  const AddExpenseScreen({super.key});

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  String _selectedCategory = ExpenseCategory.categories.first;

  bool _isLoading = false;

  Future<void> _addExpense() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final amountText = _amountController.text.trim();

    if (amountText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter an amount')),
      );
      return;
    }

    final amount = double.tryParse(amountText);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid amount')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final title = _titleController.text.trim().isEmpty
          ? ExpenseCategory.defaultTitle(_selectedCategory)
          : _titleController.text.trim();

      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('expenses')
          .add({
        'title': title,
        'amount': amount,
        'category': _selectedCategory,
        'timestamp': DateTime.now(),
      });

      setState(() => _isLoading = false);

      if (mounted) {
        Navigator.pushReplacementNamed(context, '/home');
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  void _cancel() {
    Navigator.pop(context);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Add Expense",
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.deepPurple,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Category dropdown
            DropdownButtonFormField<String>(
              value: _selectedCategory,
              decoration: InputDecoration(
                labelText: "Category",
                labelStyle: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Colors.grey[200],
              ),
              items: ExpenseCategory.categories.map((cat) {
                return DropdownMenuItem(
                  value: cat,
                  child: Text(
                    '${ExpenseCategory.getEmoji(cat)}  $cat',
                    style: const TextStyle(fontSize: 18),
                  ),
                );
              }).toList(),
              onChanged: (val) {
                if (val != null) setState(() => _selectedCategory = val);
              },
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _titleController,
              style: const TextStyle(fontSize: 20, color: Colors.black),
              decoration: InputDecoration(
                labelText: "Title (optional)",
                hintText: "e.g. Chicken Burger",
                labelStyle: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Colors.grey[200],
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _amountController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              style: const TextStyle(fontSize: 20, color: Colors.black),
              decoration: InputDecoration(
                labelText: "Amount",
                labelStyle: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Colors.grey[200],
              ),
            ),
            const SizedBox(height: 24),
            // Stacked Buttons
            _isLoading
                ? const CircularProgressIndicator()
                : Column(
                    children: [
                      SizedBox(
                        width: double.infinity,
                        height: 60,
                        child: ElevatedButton(
                          onPressed: _addExpense,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.deepPurple,
                            foregroundColor: Colors.white,
                            textStyle: const TextStyle(
                                fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                          child: const Text("Add Expense"),
                        ),
                      ),
                      const SizedBox(height: 15),
                      SizedBox(
                        width: double.infinity,
                        height: 60,
                        child: ElevatedButton(
                          onPressed: _cancel,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey[400],
                            foregroundColor: Colors.black,
                            textStyle: const TextStyle(
                                fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                          child: const Text("Cancel"),
                        ),
                      ),
                    ],
                  ),
          ],
        ),
      ),
    );
  }
}
