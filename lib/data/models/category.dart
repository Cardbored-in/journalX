import 'package:uuid/uuid.dart';

class Category {
  final String id;
  final String name;
  final String icon;
  final bool isDefault;
  final DateTime createdAt;

  Category({
    required this.id,
    required this.name,
    required this.icon,
    this.isDefault = false,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'icon': icon,
      'isDefault': isDefault ? 1 : 0,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Category.fromMap(Map<String, dynamic> map) {
    return Category(
      id: map['id'] as String,
      name: map['name'] as String,
      icon: map['icon'] as String,
      isDefault: (map['isDefault'] as int) == 1,
      createdAt: DateTime.parse(map['createdAt'] as String),
    );
  }

  Category copyWith({
    String? id,
    String? name,
    String? icon,
    bool? isDefault,
    DateTime? createdAt,
  }) {
    return Category(
      id: id ?? this.id,
      name: name ?? this.name,
      icon: icon ?? this.icon,
      isDefault: isDefault ?? this.isDefault,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  // Default categories to populate on first launch
  static List<Category> get defaultCategories {
    final now = DateTime.now();
    return [
      Category(
          id: const Uuid().v4(),
          name: 'Groceries',
          icon: '🛒',
          isDefault: true,
          createdAt: now),
      Category(
          id: const Uuid().v4(),
          name: 'Bills',
          icon: '📄',
          isDefault: true,
          createdAt: now),
      Category(
          id: const Uuid().v4(),
          name: 'Education',
          icon: '📚',
          isDefault: true,
          createdAt: now),
      Category(
          id: const Uuid().v4(),
          name: 'Shopping',
          icon: '🛍️',
          isDefault: true,
          createdAt: now),
      Category(
          id: const Uuid().v4(),
          name: 'Gift',
          icon: '🎁',
          isDefault: true,
          createdAt: now),
      Category(
          id: const Uuid().v4(),
          name: 'Other',
          icon: '💰',
          isDefault: true,
          createdAt: now),
    ];
  }
}
