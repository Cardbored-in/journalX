import 'entry_type.dart';

class Entry {
  final String id;
  final EntryType type;
  final String? title;
  final String content;
  final String? imagePath;
  final Map<String, dynamic> metadata;
  final DateTime createdAt;
  final DateTime updatedAt;

  Entry({
    required this.id,
    required this.type,
    this.title,
    required this.content,
    this.imagePath,
    Map<String, dynamic>? metadata,
    required this.createdAt,
    required this.updatedAt,
  }) : metadata = metadata ?? {};

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type.name,
      'title': title,
      'content': content,
      'imagePath': imagePath,
      'metadata': metadata,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory Entry.fromMap(Map<String, dynamic> map) {
    return Entry(
      id: map['id'] as String,
      type: EntryType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => EntryType.journal,
      ),
      title: map['title'] as String?,
      content: map['content'] as String? ?? '',
      imagePath: map['imagePath'] as String?,
      metadata: map['metadata'] is Map<String, dynamic>
          ? Map<String, dynamic>.from(map['metadata'])
          : {},
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: DateTime.parse(map['updatedAt'] as String),
    );
  }

  Entry copyWith({
    String? id,
    EntryType? type,
    String? title,
    String? content,
    String? imagePath,
    Map<String, dynamic>? metadata,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Entry(
      id: id ?? this.id,
      type: type ?? this.type,
      title: title ?? this.title,
      content: content ?? this.content,
      imagePath: imagePath ?? this.imagePath,
      metadata: metadata ?? this.metadata,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Helper getters for specific entry types
  double? get amount {
    if (type == EntryType.expense && metadata.containsKey('amount')) {
      return (metadata['amount'] as num?)?.toDouble();
    }
    return null;
  }

  String? get category {
    if (metadata.containsKey('category')) {
      return metadata['category'] as String?;
    }
    return null;
  }

  String? get paymentModeId {
    if (metadata.containsKey('paymentModeId')) {
      return metadata['paymentModeId'] as String?;
    }
    return null;
  }

  int? get rating {
    if ((type == EntryType.media || type == EntryType.dream) &&
        metadata.containsKey('rating')) {
      return metadata['rating'] as int?;
    }
    return null;
  }

  String? get mood {
    if (type == EntryType.journal && metadata.containsKey('mood')) {
      return metadata['mood'] as String?;
    }
    return null;
  }

  String? get chefNote {
    if (type == EntryType.food && metadata.containsKey('chefNote')) {
      return metadata['chefNote'] as String?;
    }
    return null;
  }
}
