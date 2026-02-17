class Expense {
  final String id;
  final double amount;
  final String description;
  final String category;
  final String? paymentModeId;
  final DateTime createdAt;

  Expense({
    required this.id,
    required this.amount,
    required this.description,
    required this.category,
    this.paymentModeId,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'amount': amount,
      'description': description,
      'category': category,
      'paymentModeId': paymentModeId,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Expense.fromMap(Map<String, dynamic> map) {
    return Expense(
      id: map['id'] as String,
      amount: (map['amount'] as num).toDouble(),
      description: map['description'] as String,
      category: map['category'] as String,
      paymentModeId: map['paymentModeId'] as String?,
      createdAt: DateTime.parse(map['createdAt'] as String),
    );
  }

  Expense copyWith({
    String? id,
    double? amount,
    String? description,
    String? category,
    String? paymentModeId,
    DateTime? createdAt,
  }) {
    return Expense(
      id: id ?? this.id,
      amount: amount ?? this.amount,
      description: description ?? this.description,
      category: category ?? this.category,
      paymentModeId: paymentModeId ?? this.paymentModeId,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

// Helper class for category icons - used for backward compatibility
// Note: This will be replaced with dynamic categories from database
class ExpenseCategories {
  // Default categories - will be replaced by database categories
  static const List<String> categories = [
    'Food',
    'Transport',
    'Shopping',
    'Entertainment',
    'Bills',
    'Health',
    'Tech',
    'Travel',
    'Education',
    'Other',
  ];

  static String getIcon(String category) {
    switch (category) {
      case 'Food':
        return '🍔';
      case 'Transport':
        return '🚗';
      case 'Shopping':
        return '🛍️';
      case 'Entertainment':
        return '🎬';
      case 'Bills':
        return '📄';
      case 'Health':
        return '💊';
      case 'Tech':
        return '📱';
      case 'Travel':
        return '✈️';
      case 'Education':
        return '📚';
      default:
        return '💰';
    }
  }
}
