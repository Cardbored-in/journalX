class AppSettings {
  final String currencySymbol;
  final bool appDetectionEnabled;
  final bool categoriesInitialized;
  final bool paymentModesInitialized;

  AppSettings({
    this.currencySymbol = '₹',
    this.appDetectionEnabled = false,
    this.categoriesInitialized = false,
    this.paymentModesInitialized = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'currencySymbol': currencySymbol,
      'appDetectionEnabled': appDetectionEnabled ? 1 : 0,
      'categoriesInitialized': categoriesInitialized ? 1 : 0,
      'paymentModesInitialized': paymentModesInitialized ? 1 : 0,
    };
  }

  factory AppSettings.fromMap(Map<String, dynamic> map) {
    return AppSettings(
      currencySymbol: map['currencySymbol'] as String? ?? '₹',
      appDetectionEnabled: (map['appDetectionEnabled'] as int?) == 1,
      categoriesInitialized: (map['categoriesInitialized'] as int?) == 1,
      paymentModesInitialized: (map['paymentModesInitialized'] as int?) == 1,
    );
  }

  AppSettings copyWith({
    String? currencySymbol,
    bool? appDetectionEnabled,
    bool? categoriesInitialized,
    bool? paymentModesInitialized,
  }) {
    return AppSettings(
      currencySymbol: currencySymbol ?? this.currencySymbol,
      appDetectionEnabled: appDetectionEnabled ?? this.appDetectionEnabled,
      categoriesInitialized:
          categoriesInitialized ?? this.categoriesInitialized,
      paymentModesInitialized:
          paymentModesInitialized ?? this.paymentModesInitialized,
    );
  }

  // Available currency options
  static const List<Map<String, String>> availableCurrencies = [
    {'symbol': '₹', 'name': 'Indian Rupee'},
    {'symbol': '\$', 'name': 'US Dollar'},
    {'symbol': '€', 'name': 'Euro'},
    {'symbol': '£', 'name': 'British Pound'},
    {'symbol': '¥', 'name': 'Japanese Yen'},
    {'symbol': 'A\$', 'name': 'Australian Dollar'},
    {'symbol': 'C\$', 'name': 'Canadian Dollar'},
  ];
}
