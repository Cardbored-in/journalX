import 'package:uuid/uuid.dart';

enum PaymentModeType {
  cash,
  upi,
  card,
}

class PaymentMode {
  final String id;
  final String name;
  final PaymentModeType type;
  final String? lastFourDigits;
  final DateTime createdAt;

  PaymentMode({
    required this.id,
    required this.name,
    required this.type,
    this.lastFourDigits,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'type': type.name,
      'lastFourDigits': lastFourDigits,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory PaymentMode.fromMap(Map<String, dynamic> map) {
    return PaymentMode(
      id: map['id'] as String,
      name: map['name'] as String,
      type: PaymentModeType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => PaymentModeType.cash,
      ),
      lastFourDigits: map['lastFourDigits'] as String?,
      createdAt: DateTime.parse(map['createdAt'] as String),
    );
  }

  PaymentMode copyWith({
    String? id,
    String? name,
    PaymentModeType? type,
    String? lastFourDigits,
    DateTime? createdAt,
  }) {
    return PaymentMode(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      lastFourDigits: lastFourDigits ?? this.lastFourDigits,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  String get displayName {
    // If name already contains the last 4 digits (from SMS auto-detection), just return name
    if (lastFourDigits != null && lastFourDigits!.isNotEmpty) {
      // Check if name already has the card digits (avoid duplication) - case insensitive
      if (name.toLowerCase().contains(lastFourDigits!.toLowerCase())) {
        return name;
      }
      return '$name ••••$lastFourDigits';
    }
    return name;
  }

  // Default payment modes
  static List<PaymentMode> get defaultPaymentModes {
    final now = DateTime.now();
    return [
      PaymentMode(
        id: const Uuid().v4(),
        name: 'Cash',
        type: PaymentModeType.cash,
        createdAt: now,
      ),
      PaymentMode(
        id: const Uuid().v4(),
        name: 'UPI',
        type: PaymentModeType.upi,
        createdAt: now,
      ),
    ];
  }
}
