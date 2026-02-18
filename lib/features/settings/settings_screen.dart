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

      // Track seen transactions to avoid duplicates
      final seenTransactions = <String>{};

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
            // Parse receiver
            final receiver = _parseReceiver(body);

            // Skip duplicates based on amount + timestamp + rough description
            final transactionKey =
                '${amount}_${timestamp ~/ 60000}_${(receiver ?? "").substring(0, (receiver ?? "").length.clamp(0, 5))}';
            if (seenTransactions.contains(transactionKey)) {
              continue;
            }
            seenTransactions.add(transactionKey);

            final description = receiver ?? 'Imported from SMS';

            // Detect category from merchant
            final category = _detectCategory(body, description);

            // Detect bank name and card last 4 digits
            final bankName = _detectBankName(address, body);
            final cardLast4 = _detectCardLast4(body);

            // Get or create payment mode
            final paymentModeId =
                await _getOrCreatePaymentMode(bankName, cardLast4);

            // Create expense with raw SMS for debugging
            final expense = Expense(
              id: const Uuid().v4(),
              amount: amount,
              description: description,
              category: category,
              paymentModeId: paymentModeId,
              createdAt: DateTime.fromMillisecondsSinceEpoch(timestamp),
              rawSms: body, // Save raw SMS for debugging
            );

            // Save to database
            await DatabaseHelper.instance.insert('expenses', expense.toMap());
            savedCount++;
          }
        }
      }

      String message = 'Imported $savedCount expenses from $days days';

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
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

  // Detect bank name from address/message
  String _detectBankName(String address, String message) {
    final addrUpper = address.toUpperCase();
    final msgUpper = message.toUpperCase();

    if (addrUpper.contains('HDFC') || msgUpper.contains('HDFC'))
      return 'HDFC Bank';
    if (addrUpper.contains('SBI') ||
        msgUpper.contains('STATE BANK') ||
        msgUpper.contains('SBI')) return 'SBI';
    if (addrUpper.contains('ICICI') || msgUpper.contains('ICICI'))
      return 'ICICI Bank';
    if (addrUpper.contains('AXIS') || msgUpper.contains('AXIS'))
      return 'Axis Bank';
    if (addrUpper.contains('KOTAK') || msgUpper.contains('KOTAK'))
      return 'Kotak Bank';
    if (addrUpper.contains('YES') || msgUpper.contains('YES BANK'))
      return 'Yes Bank';
    if (addrUpper.contains('INDUSIND') || msgUpper.contains('INDUSIND'))
      return 'IndusInd Bank';
    if (addrUpper.contains('PNB') || msgUpper.contains('PUNJAB NATIONAL'))
      return 'PNB';
    if (addrUpper.contains('CANARA') || msgUpper.contains('CANARA'))
      return 'Canara Bank';
    if (addrUpper.contains('UNION') || msgUpper.contains('UNION BANK'))
      return 'Union Bank';
    if (addrUpper.contains('BANK OF BARODA') || msgUpper.contains('BOB'))
      return 'Bank of Baroda';
    if (addrUpper.contains('IDBI') || msgUpper.contains('IDBI'))
      return 'IDBI Bank';
    if (addrUpper.contains('CITI') || msgUpper.contains('CITI'))
      return 'Citibank';
    if (addrUpper.contains('AMEX') || msgUpper.contains('AMERICAN EXPRESS'))
      return 'American Express';
    if (addrUpper.contains('PAYTM') || msgUpper.contains('PAYTM'))
      return 'Paytm';
    if (addrUpper.contains('PHONEPE') || msgUpper.contains('PHONEPE'))
      return 'PhonePe';
    if (addrUpper.contains('GPAY') ||
        msgUpper.contains('GPAY') ||
        msgUpper.contains('GOOGLE PAY')) return 'Google Pay';
    if (addrUpper.contains('AMAZON') || msgUpper.contains('AMAZON'))
      return 'Amazon Pay';

    return 'Bank/Unknown';
  }

  // Get or create payment mode - returns the payment mode ID
  Future<String?> _getOrCreatePaymentMode(
      String bankName, String? cardLast4) async {
    // Build payment mode display: "HDFC Bank •••• 1234" or just "HDFC Bank" or just "•••• 1234"
    final String paymentModeDisplay;
    if (bankName != 'Bank/Unknown' && cardLast4 != null) {
      paymentModeDisplay = '$bankName •••• $cardLast4';
    } else if (bankName != 'Bank/Unknown') {
      paymentModeDisplay = bankName;
    } else if (cardLast4 != null) {
      paymentModeDisplay = '•••• $cardLast4';
    } else {
      paymentModeDisplay = 'Unknown';
    }

    // Check if payment mode exists
    final db = await DatabaseHelper.instance.database;
    final existing = await db.query(
      'payment_modes',
      where: 'name = ?',
      whereArgs: [paymentModeDisplay],
    );

    if (existing.isNotEmpty) {
      return existing.first['id'] as String;
    }

    // Create new payment mode
    final id = const Uuid().v4();
    final type = _getPaymentModeType(bankName, cardLast4);

    await db.insert('payment_modes', {
      'id': id,
      'name': paymentModeDisplay,
      'type': type,
      'lastFourDigits': cardLast4,
      'createdAt': DateTime.now().toIso8601String(),
    });

    return id;
  }

  String _getPaymentModeType(String bankName, String? cardLast4) {
    if (cardLast4 != null) return 'Card';
    final lowerName = bankName.toLowerCase();
    if (lowerName.contains('bank')) return 'Bank';
    if (lowerName.contains('paytm')) return 'UPI';
    if (lowerName.contains('phonepe')) return 'UPI';
    if (lowerName.contains('google pay') || lowerName.contains('gpay'))
      return 'UPI';
    return 'Other';
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

    // First, try to get merchant name from "AT" pattern (for card transactions)
    final atPattern = RegExp(r'AT\s+([A-Z][A-Z0-9\s]+)', caseSensitive: false);
    final atMatch = atPattern.firstMatch(msg);
    if (atMatch != null) {
      var value = atMatch.group(1)?.trim() ?? '';
      // Clean up the merchant name - remove trailing dates like "ON 2026", "ON 15/02/26"
      value = value
          .replaceAll(RegExp(r'\s+ON\s*\d{1,2}[-/]\d{1,2}[-/]\d{2,4}.*'), '')
          .trim();
      value = value.replaceAll(RegExp(r'\s+ON\s*\d{2,4}.*'), '').trim();
      value = value.replaceAll(RegExp(r'\s+Not.*'), '').trim();
      value = value.replaceAll(RegExp(r'\s+To\s+Block.*'), '').trim();
      if (value.length >= 2 && value.length <= 40) {
        return value;
      }
    }

    // For card transactions with "Spent ... At", extract the merchant
    final spentAtPattern = RegExp(
        r'SPENT\s+(?:RS\.?|INR)?\s*[\d,]+\s+(?:ON\s+)?(?:YOUR\s+)?[A-Z]+\s+CARD\s+(?:ENDING\s+)?\d+\s+AT\s+([A-Z][A-Z0-9\s]+)',
        caseSensitive: false);
    final spentMatch = spentAtPattern.firstMatch(msg);
    if (spentMatch != null) {
      var value = spentMatch.group(1)?.trim() ?? '';
      value = value.replaceAll(RegExp(r'\s+On.*'), '').trim();
      if (value.length >= 2 && value.length <= 40) {
        return value;
      }
    }

    // Patterns to find person/receiver for UPI transfers
    final patterns = [
      RegExp(r'TO\s+([A-Z][A-Z\s]+)'),
      RegExp(r'PAID\s+TO\s+([A-Z][A-Z0-9@]+)'),
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

  // Check if transaction is a self-transfer (same person sending to themselves)
  bool _isSelfTransfer(String message, String? receiver) {
    if (receiver == null) return false;
    final msg = message.toUpperCase();

    // Pattern 1: Check if it's a UPI "Sent" transaction (likely self-transfer if amount is high)
    if (msg.contains('SENT RS.') || msg.contains('SENT RS')) {
      // If it's "Sent" and the message contains bank account (not a merchant), it's likely self-transfer
      if (msg.contains('FROM HDFC') ||
          msg.contains('FROM SBI') ||
          msg.contains('FROM ICICI') ||
          msg.contains('FROM AXIS') ||
          msg.contains('FROM KOTAK') ||
          msg.contains('FROM YES')) {
        // Check if receiver looks like a person's name (not a merchant)
        if (receiver.length < 20 &&
            !receiver.contains('LIMITED') &&
            !receiver.contains('TECHNOLOGIES') &&
            !receiver.contains('SERVICES')) {
          // This is likely a self-transfer to another account
          return true;
        }
      }
    }

    // Pattern 2: Compare sender and receiver names
    final senderPatterns = [
      RegExp(r'FROM\s+([A-Z][A-Z\s]+)', caseSensitive: false),
      RegExp(r'BY\s+([A-Z][A-Z\s]+)', caseSensitive: false),
    ];

    for (final pattern in senderPatterns) {
      final match = pattern.firstMatch(msg);
      if (match != null) {
        final sender = match.group(1)?.toUpperCase().trim() ?? '';
        // Compare sender and receiver (simple check)
        final receiverClean = receiver.toUpperCase().replaceAll(' ', '');
        final senderClean = sender.replaceAll(' ', '');

        // If sender and receiver seem similar (partial match), it's likely self-transfer
        if (senderClean.isNotEmpty && receiverClean.isNotEmpty) {
          if (senderClean.contains(receiverClean) ||
              receiverClean.contains(senderClean)) {
            return true;
          }
          // Also check if first names match
          final senderFirst = senderClean.split(' ').first;
          final receiverFirst = receiverClean.split(' ').first;
          if (senderFirst.length > 2 && senderFirst == receiverFirst) {
            return true;
          }
        }
      }
    }

    return false;
  }

  // Detect category from merchant/description
  String _detectCategory(String message, String description) {
    final msg = message.toUpperCase();
    final desc = description.toUpperCase();

    // FIRST: Check for E-mandate/Auto-debit/Recurring payments - HIGHEST PRIORITY
    if (msg.contains('E-MANDATE') ||
        msg.contains('E MANDATE') ||
        msg.contains('AUTO DEBIT') ||
        msg.contains('AUTOMATIC DEBIT') ||
        msg.contains('AUTO DEBITED') ||
        msg.contains('WILL BE AUTO') ||
        msg.contains('STANDING INSTRUCTION')) {
      return 'Recurring';
    }

    // Skip if it's a bill payment notification (not a purchase)
    if (msg.contains('OUTSTANDING') ||
        msg.contains('DUE ON') ||
        msg.contains('MIN. AMOUNT') ||
        msg.contains('PLEASE IGNORE') ||
        msg.contains('QUICKPAY') ||
        msg.contains('CARDHOLDER') && msg.contains('OUTSTANDING')) {
      return 'Other';
    }

    // Food & Delivery
    if (msg.contains('SWIGGY') ||
        desc.contains('SWIGGY') ||
        msg.contains('ZOMATO') ||
        desc.contains('ZOMATO') ||
        msg.contains('FOOD') ||
        desc.contains('FOOD') ||
        msg.contains('RESTAURANT') ||
        desc.contains('RESTAURANT')) {
      return 'Food';
    }

    // Shopping
    if (msg.contains('AMAZON') ||
        desc.contains('AMAZON') ||
        msg.contains('FLIPKART') ||
        desc.contains('FLIPKART') ||
        msg.contains('MYNTRA') ||
        desc.contains('MYNTRA') ||
        msg.contains('SHOP') ||
        desc.contains('SHOP') ||
        msg.contains('BUNDL') ||
        desc.contains('BUNDL')) {
      return 'Shopping';
    }

    // Transport
    if (msg.contains('UBER') ||
        desc.contains('UBER') ||
        msg.contains('OLA') ||
        desc.contains('OLA') ||
        msg.contains('RAPIDO') ||
        desc.contains('RAPIDO') ||
        msg.contains('AUTO') ||
        desc.contains('AUTO') ||
        msg.contains('BUS') ||
        desc.contains('BUS') ||
        msg.contains('TRAIN') ||
        desc.contains('TRAIN') ||
        msg.contains('METRO') ||
        desc.contains('METRO')) {
      return 'Transport';
    }

    // Entertainment
    if (msg.contains('NETFLIX') ||
        desc.contains('NETFLIX') ||
        msg.contains('PRIME') ||
        desc.contains('PRIME') ||
        msg.contains('HOTSTAR') ||
        desc.contains('HOTSTAR') ||
        msg.contains('DISNEY') ||
        desc.contains('DISNEY') ||
        msg.contains('SPOTIFY') ||
        desc.contains('SPOTIFY') ||
        msg.contains('BOOKMYSHOW') ||
        desc.contains('BOOKMYSHOW') ||
        msg.contains('MOVIE') ||
        desc.contains('MOVIE')) {
      return 'Entertainment';
    }

    // Bills & Utilities
    if (msg.contains('ELECTRICITY') ||
        desc.contains('ELECTRICITY') ||
        msg.contains('WATER') ||
        desc.contains('WATER') ||
        msg.contains('GAS') ||
        desc.contains('GAS') ||
        msg.contains('INTERNET') ||
        desc.contains('INTERNET') ||
        msg.contains('MOBILE RECHARGE') ||
        desc.contains('MOBILE') ||
        msg.contains('DTH') ||
        desc.contains('DTH')) {
      return 'Bills';
    }

    // Health
    if (msg.contains('MEDICINE') ||
        desc.contains('MEDICINE') ||
        msg.contains('PHARMACY') ||
        desc.contains('PHARMACY') ||
        msg.contains('HOSPITAL') ||
        desc.contains('HOSPITAL') ||
        msg.contains('DOCTOR') ||
        desc.contains('DOCTOR') ||
        msg.contains('HEALTH') ||
        desc.contains('HEALTH')) {
      return 'Health';
    }

    // Insurance - only actual insurance with explicit premium/policy keywords
    if ((msg.contains('INSURANCE') || desc.contains('INSURANCE')) &&
        (msg.contains('PREMIUM') ||
            msg.contains('POLICY') ||
            msg.contains('CLAIM'))) {
      return 'Insurance';
    }

    if (msg.contains('LIC') || desc.contains('LIC')) {
      return 'Insurance';
    }

    // Explicit TATA AIA premium
    if ((msg.contains('TATA AIA') || desc.contains('TATA AIA')) &&
        msg.contains('PREMIUM')) {
      return 'Insurance';
    }

    // Education
    if (msg.contains('COURSE') ||
        desc.contains('COURSE') ||
        msg.contains('EDUCATION') ||
        desc.contains('EDUCATION') ||
        msg.contains('TUITION') ||
        desc.contains('TUITION') ||
        msg.contains('BOOK') ||
        desc.contains('BOOK')) {
      return 'Education';
    }

    // Tech/Subscriptions
    if ((msg.contains('GOOGLE PLAY') || desc.contains('GOOGLE PLAY')) ||
        msg.contains('APPLE') ||
        desc.contains('APPLE') ||
        msg.contains('MICROSOFT') ||
        desc.contains('MICROSOFT') ||
        msg.contains('SPOTIFY') ||
        desc.contains('SPOTIFY')) {
      return 'Tech';
    }

    return 'Other';
  }

  // Detect card last 4 digits from message
  String? _detectCardLast4(String message) {
    final msg = message.toUpperCase();

    // Pattern 1: "Card 4286" or "Card ending 4286"
    final cardPatterns = [
      RegExp(r'CARD\s*(?:ENDING\s*)?(\d{4})', caseSensitive: false),
      RegExp(r'ENDING\s*(\d{4})', caseSensitive: false),
      RegExp(r'\*(\d{4})\b', caseSensitive: false),
      RegExp(r'XX(\d{4})', caseSensitive: false),
    ];

    for (final pattern in cardPatterns) {
      final match = pattern.firstMatch(msg);
      if (match != null) {
        return match.group(1);
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

        // Open Data Folder
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

        const SizedBox(height: 12),

        // Export to CSV
        Container(
          decoration: BoxDecoration(
            color: AppTheme.surfaceColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            leading: const Icon(Icons.download),
            title: const Text('Export Expenses to CSV'),
            subtitle: const Text('Includes raw SMS for debugging'),
            trailing: const Icon(Icons.chevron_right),
            onTap: _exportExpensesToCsv,
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

  Future<void> _exportExpensesToCsv() async {
    try {
      // Show loading
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) =>
              const Center(child: CircularProgressIndicator()),
        );
      }

      // Fetch all expenses
      final expensesData = await DatabaseHelper.instance.queryAll('expenses');
      final expenses = expensesData.map((map) => Expense.fromMap(map)).toList();

      if (expenses.isEmpty) {
        if (mounted) Navigator.pop(context);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No expenses to export')),
          );
        }
        return;
      }

      // Build CSV content
      final csvLines = <String>[];

      // Header with raw SMS for debugging
      csvLines.add('Date,Amount,Category,PaymentMode,Description,Raw SMS');

      for (final expense in expenses) {
        // Escape quotes in raw SMS
        final rawSms = expense.rawSms?.replaceAll('"', '""') ?? '';
        final description = expense.description.replaceAll('"', '""');
        final paymentMode = expense.paymentModeId ?? '';

        csvLines.add(
            '${expense.createdAt.toIso8601String()},${expense.amount},${expense.category},"$paymentMode","$description","$rawSms"');
      }

      final csvContent = csvLines.join('\n');
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'expenses_$timestamp.csv';

      // Try to save to Downloads using platform channel
      try {
        const platform = MethodChannel('android/EXPORT');
        await platform.invokeMethod('saveToDownloads', {
          'filename': fileName,
          'content': csvContent,
        });

        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content:
                  Text('Exported ${expenses.length} expenses to Downloads'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        // Fallback: save to app directory and share
        final directory = await getApplicationDocumentsDirectory();
        final filePath = '${directory.path}/$fileName';
        final file = File(filePath);
        await file.writeAsString(csvContent);

        if (mounted) {
          Navigator.pop(context);
          // Show share dialog
          await OpenFilex.open(filePath);
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
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
