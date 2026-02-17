import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/entry.dart';
import '../../data/models/entry_type.dart';
import '../../data/models/note.dart';
import '../../data/models/expense.dart';
import '../../data/models/meal.dart';
import '../../data/models/app_settings.dart';
import '../../data/database/database_helper.dart';
import '../../providers/module_providers.dart';
import '../../core/theme/app_theme.dart';
import 'widgets/midnight_thought_card.dart';
import 'widgets/journal_card.dart';
import 'widgets/food_card.dart';
import 'widgets/spark_card.dart';
import 'widgets/media_card.dart';
import 'widgets/dream_card.dart';
import 'widgets/expense_card.dart';

class TimelineScreen extends ConsumerStatefulWidget {
  final VoidCallback? onResume;

  const TimelineScreen({super.key, this.onResume});

  @override
  ConsumerState<TimelineScreen> createState() => _TimelineScreenState();
}

class _TimelineScreenState extends ConsumerState<TimelineScreen>
    with WidgetsBindingObserver {
  List<Entry> _entries = [];
  bool _isLoading = true;
  AppSettings? _settings;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadEntries();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // Public method to refresh timeline
  void refresh() {
    _loadEntries();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Reload entries when app is resumed (user switches back to the app)
      _loadEntries();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Reload when switching to this tab
    _loadEntries();
  }

  Future<void> _loadEntries() async {
    setState(() => _isLoading = true);
    try {
      // Get module settings
      _settings = await DatabaseHelper.instance.getSettings();

      // Get entries from unified entries table
      final entries = await DatabaseHelper.instance.getAllEntries();

      // Also get notes and convert them to entries for backward compatibility
      final notesData = await DatabaseHelper.instance.queryAll('notes');
      final notes = notesData.map((map) => Note.fromMap(map)).toList();

      // Convert notes to entries
      final noteEntries = notes
          .map((note) => Entry(
                id: note.id,
                type: EntryType.journal,
                content: note.content,
                metadata: note.mood != null ? {'mood': note.mood} : {},
                createdAt: note.createdAt,
                updatedAt: note.updatedAt,
              ))
          .toList();

      // Also get expenses and convert them to entries
      final expensesData = await DatabaseHelper.instance.queryAll('expenses');
      final expenses = expensesData.map((map) => Expense.fromMap(map)).toList();

      final expenseEntries = expenses
          .map((expense) => Entry(
                id: expense.id,
                type: EntryType.expense,
                content: expense.description,
                metadata: {
                  'amount': expense.amount,
                  'category': expense.category,
                  'paymentModeId': expense.paymentModeId,
                },
                createdAt: expense.createdAt,
                updatedAt: expense.createdAt,
              ))
          .toList();

      // Also get meals and convert them to entries
      final mealsData = await DatabaseHelper.instance.queryAll('meals');
      final meals = mealsData.map((map) => Meal.fromMap(map)).toList();

      final mealEntries = meals
          .map((meal) => Entry(
                id: meal.id,
                type: EntryType.food,
                title: meal.title,
                content: meal.chefNote ?? '',
                imagePath: meal.imagePath,
                metadata: {},
                createdAt: meal.createdAt,
                updatedAt: meal.createdAt,
              ))
          .toList();

      // Combine all entries
      var allEntries = <Entry>[
        ...entries,
        ...noteEntries,
        ...expenseEntries,
        ...mealEntries,
      ];

      // Filter based on module settings
      allEntries = _filterBySettings(allEntries);

      // Sort by date - oldest first
      allEntries.sort((a, b) => a.createdAt.compareTo(b.createdAt));

      setState(() {
        _entries = allEntries;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading entries: $e')),
        );
      }
    }
  }

  List<Entry> _filterBySettings(List<Entry> entries) {
    if (_settings == null) return entries;

    return entries.where((entry) {
      switch (entry.type) {
        case EntryType.journal:
          return _settings!.moduleJournalEnabled;
        case EntryType.food:
          return _settings!.moduleFoodEnabled;
        case EntryType.expense:
          return _settings!.moduleExpenseEnabled;
        case EntryType.midnightThought:
          return _settings!.moduleMidnightThoughtEnabled;
        case EntryType.spark:
          return _settings!.moduleSparkEnabled;
        case EntryType.media:
          return _settings!.moduleMediaEnabled;
        case EntryType.dream:
          return _settings!.moduleDreamEnabled;
      }
    }).toList();
  }

  Widget _buildEntryCard(Entry entry) {
    switch (entry.type) {
      case EntryType.midnightThought:
        return MidnightThoughtCard(entry: entry);
      case EntryType.journal:
        return JournalCard(entry: entry);
      case EntryType.food:
        return FoodCard(entry: entry);
      case EntryType.spark:
        return SparkCard(entry: entry);
      case EntryType.media:
        return MediaCard(entry: entry);
      case EntryType.dream:
        return DreamCard(entry: entry);
      case EntryType.expense:
        return ExpenseCard(entry: entry);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Timeline',
          style: GoogleFonts.playfairDisplay(
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _entries.isEmpty
              ? _buildEmptyState()
              : _buildTimeline(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.timeline,
            size: 80,
            color: AppTheme.onSurfaceColor.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'No entries yet',
            style: TextStyle(
              fontSize: 20,
              color: AppTheme.onSurfaceColor.withOpacity(0.5),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap + to create your first entry',
            style: TextStyle(
              color: AppTheme.onSurfaceColor.withOpacity(0.3),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeline() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: _entries.length,
      itemBuilder: (context, index) {
        final entry = _entries[index];
        final isLast = index == _entries.length - 1;

        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Timeline line and dot
              SizedBox(
                width: 40,
                child: Column(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: _getColorForType(entry.type),
                        shape: BoxShape.circle,
                      ),
                    ),
                    if (!isLast)
                      Expanded(
                        child: Container(
                          width: 2,
                          color: AppTheme.onSurfaceColor.withOpacity(0.2),
                        ),
                      ),
                  ],
                ),
              ),
              // Entry card
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: _buildEntryCard(entry),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Color _getColorForType(EntryType type) {
    switch (type) {
      case EntryType.journal:
        return AppTheme.primaryColor;
      case EntryType.food:
        return Colors.orange;
      case EntryType.expense:
        return Colors.green;
      case EntryType.midnightThought:
        return Colors.green.shade700;
      case EntryType.spark:
        return Colors.amber;
      case EntryType.media:
        return Colors.purple;
      case EntryType.dream:
        return Colors.indigo;
    }
  }
}
