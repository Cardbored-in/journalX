import 'dart:io';
import 'package:uuid/uuid.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import '../../data/models/app_settings.dart';
import '../../data/models/entry_type.dart';
import '../../data/models/expense.dart';
import '../../data/database/database_helper.dart';
import '../../core/theme/app_theme.dart';
import '../../main.dart';
import '../../providers/module_providers.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  AppSettings? _settings;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final settings = await DatabaseHelper.instance.getSettings();
      setState(() {
        _settings = settings;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _updateCurrency(String symbol) async {
    await DatabaseHelper.instance.updateSetting('currencySymbol', symbol);
    _loadSettings();
  }

  Future<void> _toggleAppDetection(bool value) async {
    await DatabaseHelper.instance
        .updateSetting('appDetectionEnabled', value ? 1 : 0);
    _loadSettings();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: _isLoading || _settings == null
          ? const Center(child: CircularProgressIndicator())
          : Consumer(
              builder: (context, ref, child) {
                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    _buildCurrencySection(),
                    const SizedBox(height: 24),
                    _buildSmsDetectionSection(),
                    const SizedBox(height: 24),
                    _buildAppDetectionSection(),
                    const SizedBox(height: 24),
                    _buildModulesSection(ref),
                    const SizedBox(height: 24),
                    _buildStorageSection(),
                    const SizedBox(height: 24),
                    _buildDangerZoneSection(),
                    const SizedBox(height: 24),
                    _buildAboutSection(),
                  ],
                );
              },
            ),
    );
  }

  Widget _buildSmsDetectionSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'SMS Expense Detection',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Automatically detect expenses from bank SMS messages',
          style: TextStyle(
            color: AppTheme.onSurfaceColor.withOpacity(0.6),
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 16),

        // Grant Permission Button
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.surfaceColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.sms, size: 24),
                  SizedBox(width: 12),
                  Text(
                    'Grant SMS Permission',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                'Required to detect bank messages. This permission is only used to detect expense SMS and is never uploaded anywhere.',
                style: TextStyle(fontSize: 13),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _requestSmsPermission,
                  icon: const Icon(Icons.security),
                  label: const Text('Request Permission'),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // Import Past Transactions Button
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.surfaceColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.history, size: 24),
                  SizedBox(width: 12),
                  Text(
                    'Import Past Transactions',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                'Scan past SMS messages to find and import expenses',
                style: TextStyle(fontSize: 13),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _showImportDialog,
                  icon: const Icon(Icons.download),
                  label: const Text('Import Expenses'),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.blue.withOpacity(0.3)),
          ),
          child: const Row(
            children: [
              Icon(Icons.info_outline, color: Colors.blue),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Supported: HDFC, SBI, ICICI, Axis, Kotak, Yes Bank, and all major Indian banks. Also detects UPI transactions.',
                  style: TextStyle(fontSize: 13),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _requestSmsPermission() async {
    try {
      const platform = MethodChannel('android/PERMISSIONS');
      await platform.invokeMethod('requestSmsPermission');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please grant SMS permission from the system dialog'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  void _showImportDialog() {
    final daysController = TextEditingController(text: '7');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Import Past Expenses'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('How many days of SMS to scan?'),
            const SizedBox(height: 16),
            TextField(
              controller: daysController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Number of days',
                hintText: 'e.g., 7, 30, 90',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Tip: 7 days for weekly sync, 30 for monthly',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              final days = int.tryParse(daysController.text) ?? 7;
              _importPastExpenses(days);
            },
            child: const Text('Import'),
          ),
        ],
      ),
    );
  }

  Future<void> _importPastExpenses(int days) async {
    try {
      // Show loading
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Scanning and importing expenses...')),
        );
      }

      const platform = MethodChannel('android/SMS');
      final List<dynamic> smsResult =
          await platform.invokeMethod('readOldSms', {'days': days});

      // Parse and filter expenses, then save to database
      int savedCount = 0;
      for (final sms in smsResult) {
        final body = sms['body'] as String;
        final address = sms['address'] as String;
        final timestamp = sms['date'] as int;

        if (_isExpenseMessage(body)) {
          // Parse amount from message
          final amount = _parseAmount(body);
          if (amount != null && amount > 0) {
            // Parse receiver/merchant
            final receiver = _parseReceiver(body);
            final description = receiver ?? 'Imported from SMS';

            // Create expense
            final expense = Expense(
              id: const Uuid().v4(),
              amount: amount,
              description: description,
              category: 'Other',
              createdAt: DateTime.fromMillisecondsSinceEpoch(timestamp),
            );

            // Save to database
            await DatabaseHelper.instance.insert('expenses', expense.toMap());
            savedCount++;
          }
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Imported $savedCount expenses from $days days'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  bool _isExpenseMessage(String message) {
    final msg = message.toUpperCase();
    return msg.contains('DEBITED') ||
        msg.contains('PAID') ||
        msg.contains('CHARGED') ||
        msg.contains('PURCHASE') ||
        msg.contains('SPENT') ||
        msg.contains('TRANSACTION') ||
        msg.contains('SENT') ||
        msg.contains('DEBIT');
  }

  double? _parseAmount(String message) {
    // Extract amount - same patterns as SmsReceiver
    final patterns = [
      RegExp(r'Rs\.\s*([\d,]+\.?\d*)', caseSensitive: false),
      RegExp(r'₹\s*([\d,]+\.?\d*)'),
      RegExp(r'INR\s*([\d,]+\.?\d*)', caseSensitive: false),
      RegExp(r'Amount\s+of\s+Rs\.\s*([\d,]+\.?\d*)', caseSensitive: false),
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(message);
      if (match != null) {
        final amountStr = match.group(1)?.replaceAll(',', '') ?? '';
        return double.tryParse(amountStr);
      }
    }
    return null;
  }

  String? _parseReceiver(String message) {
    final msg = message.toUpperCase();

    // Patterns to find merchant/receiver
    final patterns = [
      RegExp(r'TO\s+([A-Z][A-Z\s]+)'),
      RegExp(r'PAID\s+TO\s+([A-Z][A-Z0-9@]+)'),
      RegExp(r'AT\s+([A-Z][A-Z0-9\s]+)'),
      RegExp(r'SENT\s+TO\s+([A-Z][A-Z\s]+)'),
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(msg);
      if (match != null) {
        var value = match.group(1)?.trim() ?? '';
        // Clean up - remove trailing "ON" or other words
        value = value.replaceAll(RegExp(r'\s+ON\s+.*'), '').trim();
        if (value.length >= 2 && value.length <= 30) {
          return value;
        }
      }
    }

    // For UPI transactions
    if (msg.contains('UPI') || msg.contains('@')) {
      final upiPattern =
          RegExp(r'([A-Za-z0-9._-]+@[A-Za-z0-9._-]+)', caseSensitive: false);
      final upiMatch = upiPattern.firstMatch(msg);
      if (upiMatch != null) {
        return upiMatch.group(1);
      }
    }

    return null;
  }

  Widget _buildStorageSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Storage',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'View and manage app data stored locally',
          style: TextStyle(
            color: AppTheme.onSurfaceColor.withOpacity(0.6),
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: AppTheme.surfaceColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            leading: const Icon(Icons.folder_open),
            title: const Text('Open Data Folder'),
            subtitle: const Text('View stored files in file manager'),
            trailing: const Icon(Icons.chevron_right),
            onTap: _openDataFolder,
          ),
        ),
      ],
    );
  }

  Future<void> _openDataFolder() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      await OpenFilex.open(directory.path);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error opening folder: $e')),
        );
      }
    }
  }

  Widget _buildDangerZoneSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Danger Zone',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.red,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Irreversible actions - proceed with caution',
          style: TextStyle(
            color: AppTheme.onSurfaceColor.withOpacity(0.6),
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: AppTheme.surfaceColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.red.withOpacity(0.3)),
          ),
          child: ListTile(
            leading: const Icon(Icons.delete_forever, color: Colors.red),
            title: const Text(
              'Reset Database',
              style: TextStyle(color: Colors.red),
            ),
            subtitle: const Text('Delete all entries and reset app'),
            trailing: const Icon(Icons.chevron_right, color: Colors.red),
            onTap: _showResetConfirmation,
          ),
        ),
      ],
    );
  }

  void _showResetConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Database?'),
        content: const Text(
          'This will delete ALL your data including:\n\n'
          '• Journal entries\n'
          '• Food logs\n'
          '• Expenses\n'
          '• Notes\n'
          '• All other entries\n\n'
          'This action cannot be undone!',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _resetDatabase();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Reset Everything'),
          ),
        ],
      ),
    );
  }

  Future<void> _resetDatabase() async {
    try {
      final db = await DatabaseHelper.instance.database;

      // Delete all data from tables
      await db.delete('entries');
      await db.delete('notes');
      await db.delete('meals');
      await db.delete('expenses');
      await db.delete('categories');
      await db.delete('payment_modes');

      // Reset settings but keep module preferences
      await db.update(
          'settings',
          {
            'currencySymbol': '₹',
            'appDetectionEnabled': 0,
            'categoriesInitialized': 0,
            'paymentModesInitialized': 0,
          },
          where: 'id = ?',
          whereArgs: [1]);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Database has been reset. Please restart the app.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error resetting database: $e')),
        );
      }
    }
  }

  Widget _buildCurrencySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Currency',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Select your preferred currency symbol',
          style: TextStyle(
            color: AppTheme.onSurfaceColor.withOpacity(0.6),
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: AppTheme.surfaceColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: AppSettings.availableCurrencies.map((currency) {
              final isSelected =
                  _settings!.currencySymbol == currency['symbol'];
              return ListTile(
                leading: Text(
                  currency['symbol']!,
                  style: const TextStyle(fontSize: 24),
                ),
                title: Text(currency['name']!),
                trailing: isSelected
                    ? const Icon(Icons.check, color: AppTheme.primaryColor)
                    : null,
                onTap: () => _updateCurrency(currency['symbol']!),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildAppDetectionSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'App Detection',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Get notified when you open payment apps like GPay or PhonePe',
          style: TextStyle(
            color: AppTheme.onSurfaceColor.withOpacity(0.6),
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: AppTheme.surfaceColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: SwitchListTile(
            title: const Text('Enable App Detection'),
            subtitle: const Text(
              'Shows notification to log expense when GPay or PhonePe is opened',
            ),
            value: _settings!.appDetectionEnabled,
            onChanged: _toggleAppDetection,
          ),
        ),
        if (_settings!.appDetectionEnabled) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.orange.withOpacity(0.3)),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline, color: Colors.orange),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Go to Settings > Accessibility > JournalX and enable the service for this feature to work.',
                    style: TextStyle(fontSize: 14),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildModulesSection(WidgetRef ref) {
    final modules = ref.watch(moduleProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Modules',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Enable or disable features in your app',
          style: TextStyle(
            color: AppTheme.onSurfaceColor.withOpacity(0.6),
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: AppTheme.surfaceColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: EntryType.values.map((type) {
              final isEnabled = modules[type] ?? true;
              return SwitchListTile(
                title: Text('${type.icon} ${type.displayName}'),
                subtitle: Text(
                  type.description,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.onSurfaceColor.withOpacity(0.6),
                  ),
                ),
                value: isEnabled,
                onChanged: (value) {
                  ref.read(moduleProvider.notifier).toggleModule(type, value);
                },
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildAboutSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'About',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: AppTheme.surfaceColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.info_outline),
                title: const Text('Version'),
                subtitle: Text(buildVersion),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.storage),
                title: const Text('Data Storage'),
                subtitle:
                    const Text('All data is stored locally on your device'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
