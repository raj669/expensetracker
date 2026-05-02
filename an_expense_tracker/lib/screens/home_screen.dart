import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../models/category.dart';
import '../models/expense_model.dart';
import '../widgets/charts_widget.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static final _dateFormat = DateFormat('yyyy/MM/dd - EEEE');

  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;
  User? user;
  double totalExpenses = 0.0;
  late Stream<QuerySnapshot> _expensesStream;

  bool selectionMode = false;
  Set<String> selectedDocs = {};
  bool _showCharts = false;

  @override
  void initState() {
    super.initState();
    user = _auth.currentUser;
    _expensesStream = _expensesCollection()
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  CollectionReference _expensesCollection() {
    return _firestore
        .collection('users')
        .doc(user!.uid)
        .collection('expenses');
  }

  void _deleteExpense(String docId) {
    _expensesCollection().doc(docId).delete();
  }

  Future<void> _deleteSelectedExpenses() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Deletion'),
        content: Text(
            'Are you sure you want to delete ${selectedDocs.length} selected expenses?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final batch = _firestore.batch();
      for (var docId in selectedDocs) {
        batch.delete(_expensesCollection().doc(docId));
      }
      await batch.commit();
      if (!mounted) return;
      setState(() {
        selectedDocs.clear();
        selectionMode = false;
      });
    }
  }

  void _cancelSelection() {
    setState(() {
      selectedDocs.clear();
      selectionMode = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final username = user?.displayName ?? "User";

    return Scaffold(
      appBar: AppBar(
        title: Text(
          selectionMode
              ? "${selectedDocs.length} selected"
              : 'Welcome, $username',
          style: const TextStyle(
              fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: Colors.deepPurple,
        actions: [
          if (selectionMode)
            IconButton(
              iconSize: 32,
              icon: const Icon(Icons.cancel, color: Colors.orangeAccent),
              tooltip: "Cancel Selection",
              onPressed: _cancelSelection,
            ),
          if (!selectionMode)
            IconButton(
              iconSize: 30,
              icon: Icon(
                _showCharts ? Icons.list : Icons.bar_chart,
                color: Colors.white,
              ),
              tooltip: _showCharts ? "Show List" : "Show Charts",
              onPressed: () {
                setState(() {
                  _showCharts = !_showCharts;
                });
              },
            ),
          if (!selectionMode)
            IconButton(
              iconSize: 30,
              icon: const Icon(Icons.select_all, color: Colors.white),
              tooltip: "Select Expenses",
              onPressed: () {
                setState(() {
                  selectionMode = true;
                });
              },
            ),
          if (selectionMode)
            IconButton(
              iconSize: 30,
              icon: const Icon(Icons.delete_forever, color: Colors.redAccent),
              tooltip: "Delete Selected",
              onPressed: selectedDocs.isEmpty ? null : _deleteSelectedExpenses,
            ),
          IconButton(
            iconSize: 30,
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () async {
              await _auth.signOut();
              if (!mounted) return;
              Navigator.pushReplacementNamed(context, '/');
            },
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _expensesStream,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;
          final expenses =
              docs.map((d) => ExpenseModel.fromDoc(d)).toList();
          totalExpenses = expenses.fold(0.0, (sum, e) => sum + e.amount);

          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Card(
                  color: Colors.deepPurple,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 8,
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Total Expenses',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold),
                        ),
                        Text(
                          '\$${totalExpenses.toStringAsFixed(2)}',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                if (_showCharts)
                  Expanded(
                    child: SingleChildScrollView(
                      child: ChartsWidget(expenses: expenses),
                    ),
                  )
                else
                  Expanded(
                    child: ListView.builder(
                      itemCount: docs.length,
                      itemBuilder: (context, index) {
                        final expense = expenses[index];
                        final expenseDate =
                            _dateFormat.format(expense.timestamp);
                        final docId = docs[index].id;
                        final isSelected = selectedDocs.contains(docId);

                        return Card(
                          elevation: isSelected ? 10 : 4,
                          shadowColor: isSelected
                              ? Colors.deepPurpleAccent
                              : Colors.grey,
                          shape: RoundedRectangleBorder(
                            side: isSelected
                                ? const BorderSide(
                                    color: Colors.deepPurple, width: 2)
                                : BorderSide.none,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          color: isSelected
                              ? Colors.deepPurple[50]
                              : Colors.white,
                          child: ListTile(
                            onLongPress: () {
                              setState(() {
                                selectionMode = true;
                                selectedDocs.add(docId);
                              });
                            },
                            onTap: selectionMode
                                ? () {
                                    setState(() {
                                      if (isSelected) {
                                        selectedDocs.remove(docId);
                                        if (selectedDocs.isEmpty) {
                                          selectionMode = false;
                                        }
                                      } else {
                                        selectedDocs.add(docId);
                                      }
                                    });
                                  }
                                : null,
                            leading: selectionMode
                                ? Checkbox(
                                    value: isSelected,
                                    activeColor: Colors.deepPurple,
                                    onChanged: (val) {
                                      setState(() {
                                        if (val == true) {
                                          selectedDocs.add(docId);
                                        } else {
                                          selectedDocs.remove(docId);
                                          if (selectedDocs.isEmpty) {
                                            selectionMode = false;
                                          }
                                        }
                                      });
                                    },
                                  )
                                : CircleAvatar(
                                    backgroundColor: Colors.deepPurple[50],
                                    child: Text(
                                      ExpenseCategory.getEmoji(
                                          expense.category),
                                      style: const TextStyle(fontSize: 20),
                                    ),
                                  ),
                            title: Text(
                              expense.title,
                              style: TextStyle(
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.w600,
                                  fontSize: 18,
                                  color: isSelected
                                      ? Colors.deepPurple
                                      : Colors.black),
                            ),
                            subtitle: Text(
                              '${expense.category} • $expenseDate',
                              style: const TextStyle(
                                  fontSize: 14, color: Colors.black87),
                            ),
                            trailing: selectionMode
                                ? null
                                : Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        '\$${expense.amount.toStringAsFixed(2)}',
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete,
                                            color: Colors.red),
                                        onPressed: () =>
                                            _deleteExpense(docId),
                                      ),
                                    ],
                                  ),
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: !selectionMode
          ? FloatingActionButton(
              backgroundColor: Colors.deepPurple,
              foregroundColor: Colors.white,
              elevation: 10,
              highlightElevation: 14,
              tooltip: 'Add Expense',
              onPressed: () {
                Navigator.pushNamed(context, '/addExpense');
              },
              child: const Icon(Icons.add, size: 36),
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}
