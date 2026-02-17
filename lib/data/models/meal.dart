class Meal {
  final String id;
  final String title;
  final String imagePath;
  final String? chefNote;
  final DateTime createdAt;

  Meal({
    required this.id,
    required this.title,
    required this.imagePath,
    this.chefNote,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'imagePath': imagePath,
      'chefNote': chefNote,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Meal.fromMap(Map<String, dynamic> map) {
    return Meal(
      id: map['id'] as String,
      title: map['title'] as String,
      imagePath: map['imagePath'] as String,
      chefNote: map['chefNote'] as String?,
      createdAt: DateTime.parse(map['createdAt'] as String),
    );
  }

  Meal copyWith({
    String? id,
    String? title,
    String? imagePath,
    String? chefNote,
    DateTime? createdAt,
  }) {
    return Meal(
      id: id ?? this.id,
      title: title ?? this.title,
      imagePath: imagePath ?? this.imagePath,
      chefNote: chefNote ?? this.chefNote,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
