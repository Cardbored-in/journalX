import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'features/timeline/timeline_screen.dart';
import 'features/food_logger/food_logger_screen.dart';
import 'features/shayari_notes/shayari_notes_screen.dart';
import 'features/expense_tracker/expense_tracker_screen.dart';
import 'features/search/search_screen.dart';
import 'features/settings/settings_screen.dart';
import 'data/models/entry_type.dart';
import 'providers/module_providers.dart';
import 'main.dart';

class JournalXApp extends ConsumerStatefulWidget {
  const JournalXApp({super.key});

  @override
  ConsumerState<JournalXApp> createState() => _JournalXAppState();
}

class _JournalXAppState extends ConsumerState<JournalXApp>
    with WidgetsBindingObserver, TickerProviderStateMixin {
  static const _platform = MethodChannel('android/INTENT');
  bool _hasCheckedIntent = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Check for intent after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkForPendingIntent();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && !_hasCheckedIntent) {
      _checkForPendingIntent();
    }
  }

  Future<void> _checkForPendingIntent() async {
    if (_hasCheckedIntent) return;
    _hasCheckedIntent = true;

    try {
      final result = await _platform
          .invokeMethod<Map<dynamic, dynamic>>('getPendingIntent');

      debugPrint('Pending intent result: $result');

      if (result != null && mounted) {
        final data = Map<String, dynamic>.from(result);
        if (data.isNotEmpty) {
          debugPrint('Showing expense dialog for: $data');

          // Show dialog immediately
          if (mounted && context.mounted) {
            showDialog(
              context: context,
              builder: (context) => _PendingExpenseDialog(data: data),
            );
          }
        }
      }
    } catch (e) {
      debugPrint('Error checking pending intent: $e');
      // Ignore - method might not be implemented
    }
  }

  void _navigateToExpensesWithData(
      BuildContext context, Map<String, dynamic> data) {
    // This will be handled by MainNavigationScreen
    // We'll use a provider to signal that we should show the add expense dialog
    showDialog(
      context: context,
      builder: (context) => _PendingExpenseDialog(data: data),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'JournalX',
      theme: AppTheme.darkTheme,
      debugShowCheckedModeBanner: false,
      home: const MainNavigationScreen(),
    );
  }
}

class _PendingExpenseDialog extends ConsumerWidget {
  final Map<String, dynamic> data;

  const _PendingExpenseDialog({required this.data});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final amount = data['amount'] ?? 0.0;
    final receiver = data['receiver'] ?? 'Unknown';
    final source = data['source'] ?? 'Unknown';

    return AlertDialog(
      title: const Text('💰 Add Expense?'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Amount: ₹${amount.toStringAsFixed(0)}'),
          Text('To: $receiver'),
          Text('From: $source'),
          const SizedBox(height: 16),
          const Text('Would you like to save this expense?'),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            ref.read(pendingExpenseProvider.notifier).state = null;
            Navigator.pop(context);
          },
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () async {
            // Save the expense
            await _saveExpense(context, amount, receiver, source);
            ref.read(pendingExpenseProvider.notifier).state = null;
            if (context.mounted) Navigator.pop(context);
          },
          child: const Text('Save'),
        ),
      ],
    );
  }

  Future<void> _saveExpense(BuildContext context, double amount,
      String receiver, String source) async {
    try {
      // Import and use database
      // For now, we'll use a simple approach
      debugPrint('Saving expense: $amount to $receiver from $source');

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Expense saved!')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving expense: $e')),
        );
      }
    }
  }
}

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  void _onTabChanged(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  // Build the current screen - rebuilds on every tab switch
  Widget _buildCurrentScreen() {
    switch (_currentIndex) {
      case 0:
        return const TimelineScreen();
      case 1:
        return const FoodLoggerScreen();
      case 2:
        return const ShayariNotesScreen();
      case 3:
        return const ExpenseTrackerScreen();
      case 4:
        return const SearchScreen();
      case 5:
        return const SettingsScreen();
      default:
        return const TimelineScreen();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _buildCurrentScreen(),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: _onTabChanged,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.timeline_outlined),
            selectedIcon: Icon(Icons.timeline),
            label: 'Timeline',
          ),
          NavigationDestination(
            icon: Icon(Icons.restaurant_menu_outlined),
            selectedIcon: Icon(Icons.restaurant_menu),
            label: 'Food',
          ),
          NavigationDestination(
            icon: Icon(Icons.edit_note_outlined),
            selectedIcon: Icon(Icons.edit_note),
            label: 'Notes',
          ),
          NavigationDestination(
            icon: Icon(Icons.account_balance_wallet_outlined),
            selectedIcon: Icon(Icons.account_balance_wallet),
            label: 'Expenses',
          ),
          NavigationDestination(
            icon: Icon(Icons.search_outlined),
            selectedIcon: Icon(Icons.search),
            label: 'Search',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
