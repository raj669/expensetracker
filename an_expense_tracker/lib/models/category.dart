class ExpenseCategory {
  static const List<String> categories = [
    'Food',
    'Shopping',
    'Transportation',
    'Healthcare',
    'Education',
    'Entertainment',
    'Bills',
    'Travel',
    'Personal',
    'Other',
  ];

  static const Map<String, String> emojis = {
    'Food': '🍔',
    'Shopping': '🛒',
    'Transportation': '🚗',
    'Healthcare': '🏥',
    'Education': '🎓',
    'Entertainment': '🎮',
    'Bills': '💳',
    'Travel': '✈️',
    'Personal': '💇',
    'Other': '📦',
  };

  static String getEmoji(String category) {
    return emojis[category] ?? '📦';
  }

  static String defaultTitle(String category) {
    return '$category Expense';
  }
}
