import 'package:cloud_firestore/cloud_firestore.dart';
import 'category.dart';

class ExpenseModel {
  final String id;
  final String title;
  final double amount;
  final String category;
  final DateTime timestamp;

  ExpenseModel({
    required this.id,
    required this.title,
    required this.amount,
    required this.category,
    required this.timestamp,
  });

  String get emoji => ExpenseCategory.getEmoji(category);

  factory ExpenseModel.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final ts = data['timestamp'];
    return ExpenseModel(
      id: doc.id,
      title: (data['title'] as String?)?.isNotEmpty == true
          ? data['title'] as String
          : ExpenseCategory.defaultTitle(data['category'] ?? 'Other'),
      amount: (data['amount'] as num?)?.toDouble() ?? 0.0,
      category: data['category'] as String? ?? 'Other',
      timestamp: ts != null ? (ts as Timestamp).toDate() : DateTime.now(),
    );
  }
}
