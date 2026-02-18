import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/category.dart';
import '../models/payment_mode.dart';
import '../models/app_settings.dart';
import '../models/entry.dart';
import '../models/entry_type.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('journalx.db');
    return _database!;
  }

  Future<Database> _initDB(String fileName) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, fileName);

    return await openDatabase(
      path,
      version: 5, // Incremented version for new columns
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Add new tables and columns for version 2
      await _createCategoriesTable(db);
      await _createPaymentModesTable(db);
      await _createSettingsTable(db);

      // Add paymentModeId column to expenses table
      await db.execute('ALTER TABLE expenses ADD COLUMN paymentModeId TEXT');
    }

    if (oldVersion < 3) {
      // Add module enable columns to settings
      await db.execute(
          'ALTER TABLE settings ADD COLUMN moduleJournalEnabled INTEGER DEFAULT 1');
      await db.execute(
          'ALTER TABLE settings ADD COLUMN moduleFoodEnabled INTEGER DEFAULT 1');
      await db.execute(
          'ALTER TABLE settings ADD COLUMN moduleExpenseEnabled INTEGER DEFAULT 1');
      await db.execute(
          'ALTER TABLE settings ADD COLUMN moduleMidnightThoughtEnabled INTEGER DEFAULT 1');
      await db.execute(
          'ALTER TABLE settings ADD COLUMN moduleSparkEnabled INTEGER DEFAULT 1');
      await db.execute(
          'ALTER TABLE settings ADD COLUMN moduleMediaEnabled INTEGER DEFAULT 1');
      await db.execute(
          'ALTER TABLE settings ADD COLUMN moduleDreamEnabled INTEGER DEFAULT 1');

      // Create entries table
      await _createEntriesTable(db);
    }

    if (oldVersion < 4) {
      // Add rawSms column for debugging
      await db.execute('ALTER TABLE expenses ADD COLUMN rawSms TEXT');
    }
  }

  Future<void> _createDB(Database db, int version) async {
    // Food Logger Table
    await db.execute('''
      CREATE TABLE meals (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        imagePath TEXT NOT NULL,
        chefNote TEXT,
        createdAt TEXT NOT NULL
      )
    ''');

    // Shayari/Notes Table
    await db.execute('''
      CREATE TABLE notes (
        id TEXT PRIMARY KEY,
        content TEXT NOT NULL,
        mood TEXT,
        createdAt TEXT NOT NULL,
        updatedAt TEXT NOT NULL
      )
    ''');

    // Expense Tracker Table
    await db.execute('''
      CREATE TABLE expenses (
        id TEXT PRIMARY KEY,
        amount REAL NOT NULL,
        description TEXT NOT NULL,
        category TEXT NOT NULL,
        paymentModeId TEXT,
        createdAt TEXT NOT NULL,
        rawSms TEXT
      )
    ''');

    // Create indexes for faster searching
    await db.execute('CREATE INDEX idx_meals_title ON meals(title)');
    await db.execute('CREATE INDEX idx_notes_content ON notes(content)');
    await db.execute(
        'CREATE INDEX idx_expenses_description ON expenses(description)');
    await db
        .execute('CREATE INDEX idx_expenses_category ON expenses(category)');

    // Create new tables for version 2
    await _createCategoriesTable(db);
    await _createPaymentModesTable(db);
    await _createSettingsTable(db);

    // Create unified entries table
    await _createEntriesTable(db);
  }

  Future<void> _createCategoriesTable(Database db) async {
    await db.execute('''
      CREATE TABLE categories (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        icon TEXT NOT NULL,
        isDefault INTEGER DEFAULT 0,
        createdAt TEXT NOT NULL
      )
    ''');
  }

  Future<void> _createPaymentModesTable(Database db) async {
    await db.execute('''
      CREATE TABLE payment_modes (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        type TEXT NOT NULL,
        lastFourDigits TEXT,
        createdAt TEXT NOT NULL
      )
    ''');
  }

  Future<void> _createSettingsTable(Database db) async {
    await db.execute('''
      CREATE TABLE settings (
        id INTEGER PRIMARY KEY,
        currencySymbol TEXT DEFAULT '₹',
        appDetectionEnabled INTEGER DEFAULT 0,
        categoriesInitialized INTEGER DEFAULT 0,
        paymentModesInitialized INTEGER DEFAULT 0,
        moduleJournalEnabled INTEGER DEFAULT 1,
        moduleFoodEnabled INTEGER DEFAULT 1,
        moduleExpenseEnabled INTEGER DEFAULT 1,
        moduleMidnightThoughtEnabled INTEGER DEFAULT 1,
        moduleSparkEnabled INTEGER DEFAULT 1,
        moduleMediaEnabled INTEGER DEFAULT 1,
        moduleDreamEnabled INTEGER DEFAULT 1
      )
    ''');

    // Insert default settings
    await db.insert('settings', {
      'id': 1,
      'currencySymbol': '₹',
      'appDetectionEnabled': 0,
      'categoriesInitialized': 0,
      'paymentModesInitialized': 0,
      'moduleJournalEnabled': 1,
      'moduleFoodEnabled': 1,
      'moduleExpenseEnabled': 1,
      'moduleMidnightThoughtEnabled': 1,
      'moduleSparkEnabled': 1,
      'moduleMediaEnabled': 1,
      'moduleDreamEnabled': 1,
    });
  }

  // ============== Unified Entries Table ==============

  Future<void> _createEntriesTable(Database db) async {
    await db.execute('''
      CREATE TABLE entries (
        id TEXT PRIMARY KEY,
        type TEXT NOT NULL,
        title TEXT,
        content TEXT NOT NULL,
        imagePath TEXT,
        metadata TEXT,
        createdAt TEXT NOT NULL,
        updatedAt TEXT NOT NULL
      )
    ''');

    // Create index for sorting
    await db
        .execute('CREATE INDEX idx_entries_createdAt ON entries(createdAt)');
    await db.execute('CREATE INDEX idx_entries_type ON entries(type)');
  }

  // ============== Category Operations ==============

  Future<void> initializeDefaultCategories() async {
    final db = await database;
    final settings = await getSettings();

    if (!settings.categoriesInitialized) {
      final categories = Category.defaultCategories;
      for (final category in categories) {
        await db.insert('categories', category.toMap());
      }
      await updateSetting('categoriesInitialized', 1);
    }
  }

  Future<List<Category>> getAllCategories() async {
    final db = await database;
    final result = await db.query('categories', orderBy: 'name ASC');
    return result.map((map) => Category.fromMap(map)).toList();
  }

  Future<int> insertCategory(Category category) async {
    final db = await database;
    return await db.insert('categories', category.toMap());
  }

  Future<int> updateCategory(Category category) async {
    final db = await database;
    return await db.update(
      'categories',
      category.toMap(),
      where: 'id = ?',
      whereArgs: [category.id],
    );
  }

  Future<int> deleteCategory(String id) async {
    final db = await database;
    return await db.delete('categories', where: 'id = ?', whereArgs: [id]);
  }

  // ============== Payment Mode Operations ==============

  Future<void> initializeDefaultPaymentModes() async {
    final db = await database;
    final settings = await getSettings();

    if (!settings.paymentModesInitialized) {
      final paymentModes = PaymentMode.defaultPaymentModes;
      for (final mode in paymentModes) {
        await db.insert('payment_modes', mode.toMap());
      }
      await updateSetting('paymentModesInitialized', 1);
    }
  }

  Future<List<PaymentMode>> getAllPaymentModes() async {
    final db = await database;
    final result = await db.query('payment_modes', orderBy: 'name ASC');
    return result.map((map) => PaymentMode.fromMap(map)).toList();
  }

  Future<int> insertPaymentMode(PaymentMode mode) async {
    final db = await database;
    return await db.insert('payment_modes', mode.toMap());
  }

  Future<int> updatePaymentMode(PaymentMode mode) async {
    final db = await database;
    return await db.update(
      'payment_modes',
      mode.toMap(),
      where: 'id = ?',
      whereArgs: [mode.id],
    );
  }

  Future<int> deletePaymentMode(String id) async {
    final db = await database;
    return await db.delete('payment_modes', where: 'id = ?', whereArgs: [id]);
  }

  // ============== Settings Operations ==============

  Future<AppSettings> getSettings() async {
    final db = await database;
    final result = await db.query('settings', where: 'id = ?', whereArgs: [1]);
    if (result.isEmpty) {
      return AppSettings();
    }
    return AppSettings.fromMap(result.first);
  }

  Future<int> updateSetting(String key, dynamic value) async {
    final db = await database;
    return await db.update(
      'settings',
      {key: value},
      where: 'id = ?',
      whereArgs: [1],
    );
  }

  // ============== Generic CRUD operations ==============

  Future<int> insert(String table, Map<String, dynamic> data) async {
    final db = await database;
    return await db.insert(table, data);
  }

  Future<List<Map<String, dynamic>>> queryAll(String table) async {
    final db = await database;
    return await db.query(table, orderBy: 'createdAt DESC');
  }

  Future<List<Map<String, dynamic>>> search(
      String table, String column, String query) async {
    final db = await database;
    return await db.query(
      table,
      where: '$column LIKE ?',
      whereArgs: ['%$query%'],
      orderBy: 'createdAt DESC',
    );
  }

  Future<int> update(String table, Map<String, dynamic> data, String id) async {
    final db = await database;
    return await db.update(
      table,
      data,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> delete(String table, String id) async {
    final db = await database;
    return await db.delete(
      table,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> close() async {
    final db = await database;
    db.close();
  }

  // ============== Unified Entry Operations ==============

  Future<int> insertEntry(Entry entry) async {
    final db = await database;
    return await db.insert('entries', entry.toMap());
  }

  Future<List<Entry>> getAllEntries() async {
    final db = await database;
    final result = await db.query('entries', orderBy: 'createdAt DESC');
    return result.map((map) => Entry.fromMap(map)).toList();
  }

  Future<List<Entry>> getEntriesByType(EntryType type) async {
    final db = await database;
    final result = await db.query(
      'entries',
      where: 'type = ?',
      whereArgs: [type.name],
      orderBy: 'createdAt DESC',
    );
    return result.map((map) => Entry.fromMap(map)).toList();
  }

  Future<int> updateEntry(Entry entry) async {
    final db = await database;
    return await db.update(
      'entries',
      entry.toMap(),
      where: 'id = ?',
      whereArgs: [entry.id],
    );
  }

  Future<int> deleteEntry(String id) async {
    final db = await database;
    return await db.delete('entries', where: 'id = ?', whereArgs: [id]);
  }
}
