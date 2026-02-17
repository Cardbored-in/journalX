class AppSettings {
  final String currencySymbol;
  final bool appDetectionEnabled;
  final bool categoriesInitialized;
  final bool paymentModesInitialized;

  // Module enable/disable flags
  final bool moduleJournalEnabled;
  final bool moduleFoodEnabled;
  final bool moduleExpenseEnabled;
  final bool moduleMidnightThoughtEnabled;
  final bool moduleSparkEnabled;
  final bool moduleMediaEnabled;
  final bool moduleDreamEnabled;

  AppSettings({
    this.currencySymbol = '₹',
    this.appDetectionEnabled = false,
    this.categoriesInitialized = false,
    this.paymentModesInitialized = false,
    this.moduleJournalEnabled = true,
    this.moduleFoodEnabled = true,
    this.moduleExpenseEnabled = true,
    this.moduleMidnightThoughtEnabled = true,
    this.moduleSparkEnabled = true,
    this.moduleMediaEnabled = true,
    this.moduleDreamEnabled = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'currencySymbol': currencySymbol,
      'appDetectionEnabled': appDetectionEnabled ? 1 : 0,
      'categoriesInitialized': categoriesInitialized ? 1 : 0,
      'paymentModesInitialized': paymentModesInitialized ? 1 : 0,
      'moduleJournalEnabled': moduleJournalEnabled ? 1 : 0,
      'moduleFoodEnabled': moduleFoodEnabled ? 1 : 0,
      'moduleExpenseEnabled': moduleExpenseEnabled ? 1 : 0,
      'moduleMidnightThoughtEnabled': moduleMidnightThoughtEnabled ? 1 : 0,
      'moduleSparkEnabled': moduleSparkEnabled ? 1 : 0,
      'moduleMediaEnabled': moduleMediaEnabled ? 1 : 0,
      'moduleDreamEnabled': moduleDreamEnabled ? 1 : 0,
    };
  }

  factory AppSettings.fromMap(Map<String, dynamic> map) {
    return AppSettings(
      currencySymbol: map['currencySymbol'] as String? ?? '₹',
      appDetectionEnabled: (map['appDetectionEnabled'] as int?) == 1,
      categoriesInitialized: (map['categoriesInitialized'] as int?) == 1,
      paymentModesInitialized: (map['paymentModesInitialized'] as int?) == 1,
      moduleJournalEnabled: (map['moduleJournalEnabled'] as int?) != 0,
      moduleFoodEnabled: (map['moduleFoodEnabled'] as int?) != 0,
      moduleExpenseEnabled: (map['moduleExpenseEnabled'] as int?) != 0,
      moduleMidnightThoughtEnabled:
          (map['moduleMidnightThoughtEnabled'] as int?) != 0,
      moduleSparkEnabled: (map['moduleSparkEnabled'] as int?) != 0,
      moduleMediaEnabled: (map['moduleMediaEnabled'] as int?) != 0,
      moduleDreamEnabled: (map['moduleDreamEnabled'] as int?) != 0,
    );
  }

  AppSettings copyWith({
    String? currencySymbol,
    bool? appDetectionEnabled,
    bool? categoriesInitialized,
    bool? paymentModesInitialized,
    bool? moduleJournalEnabled,
    bool? moduleFoodEnabled,
    bool? moduleExpenseEnabled,
    bool? moduleMidnightThoughtEnabled,
    bool? moduleSparkEnabled,
    bool? moduleMediaEnabled,
    bool? moduleDreamEnabled,
  }) {
    return AppSettings(
      currencySymbol: currencySymbol ?? this.currencySymbol,
      appDetectionEnabled: appDetectionEnabled ?? this.appDetectionEnabled,
      categoriesInitialized:
          categoriesInitialized ?? this.categoriesInitialized,
      paymentModesInitialized:
          paymentModesInitialized ?? this.paymentModesInitialized,
      moduleJournalEnabled: moduleJournalEnabled ?? this.moduleJournalEnabled,
      moduleFoodEnabled: moduleFoodEnabled ?? this.moduleFoodEnabled,
      moduleExpenseEnabled: moduleExpenseEnabled ?? this.moduleExpenseEnabled,
      moduleMidnightThoughtEnabled:
          moduleMidnightThoughtEnabled ?? this.moduleMidnightThoughtEnabled,
      moduleSparkEnabled: moduleSparkEnabled ?? this.moduleSparkEnabled,
      moduleMediaEnabled: moduleMediaEnabled ?? this.moduleMediaEnabled,
      moduleDreamEnabled: moduleDreamEnabled ?? this.moduleDreamEnabled,
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
