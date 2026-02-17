import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../data/models/payment_mode.dart';
import '../../data/database/database_helper.dart';
import '../../core/theme/app_theme.dart';

class PaymentModeManagementScreen extends StatefulWidget {
  const PaymentModeManagementScreen({super.key});

  @override
  State<PaymentModeManagementScreen> createState() =>
      _PaymentModeManagementScreenState();
}

class _PaymentModeManagementScreenState
    extends State<PaymentModeManagementScreen> {
  List<PaymentMode> _paymentModes = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPaymentModes();
  }

  Future<void> _loadPaymentModes() async {
    setState(() => _isLoading = true);
    try {
      final modes = await DatabaseHelper.instance.getAllPaymentModes();
      setState(() {
        _paymentModes = modes;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading payment modes: $e')),
        );
      }
    }
  }

  Future<void> _addPaymentMode() async {
    final nameController = TextEditingController();
    final lastFourController = TextEditingController();
    PaymentModeType selectedType = PaymentModeType.cash;

    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surfaceColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Add Payment Mode',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Payment Type',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: PaymentModeType.values.map((type) {
                  final isSelected = selectedType == type;
                  String label;
                  IconData icon;
                  switch (type) {
                    case PaymentModeType.cash:
                      label = '💵 Cash';
                      icon = Icons.money;
                      break;
                    case PaymentModeType.upi:
                      label = '📱 UPI';
                      icon = Icons.account_balance;
                      break;
                    case PaymentModeType.card:
                      label = '💳 Card';
                      icon = Icons.credit_card;
                      break;
                  }
                  return ChoiceChip(
                    label: Text(label),
                    selected: isSelected,
                    onSelected: (selected) {
                      setModalState(() => selectedType = type);
                    },
                    selectedColor: AppTheme.primaryColor.withOpacity(0.3),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  hintText: selectedType == PaymentModeType.cash
                      ? 'Name (e.g., Cash)'
                      : selectedType == PaymentModeType.upi
                          ? 'Bank Name (e.g., HDFC Bank)'
                          : 'Card Name (e.g., SBI Credit Card)',
                ),
                autofocus: true,
              ),
              if (selectedType != PaymentModeType.cash) ...[
                const SizedBox(height: 16),
                TextField(
                  controller: lastFourController,
                  decoration: const InputDecoration(
                    hintText: 'Last 4 digits',
                  ),
                  keyboardType: TextInputType.number,
                  maxLength: 4,
                ),
              ],
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Add'),
              ),
            ],
          ),
        ),
      ),
    );

    if (result == true) {
      if (nameController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter a name')),
        );
        return;
      }

      String? lastFour;
      if (selectedType != PaymentModeType.cash) {
        if (lastFourController.text.trim().isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please enter last 4 digits')),
          );
          return;
        }
        lastFour = lastFourController.text.trim();
      }

      final paymentMode = PaymentMode(
        id: const Uuid().v4(),
        name: nameController.text.trim(),
        type: selectedType,
        lastFourDigits: lastFour,
        createdAt: DateTime.now(),
      );

      await DatabaseHelper.instance.insertPaymentMode(paymentMode);
      _loadPaymentModes();
    }
  }

  Future<void> _deletePaymentMode(PaymentMode mode) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Payment Mode'),
        content: Text('Delete "${mode.displayName}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorColor,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await DatabaseHelper.instance.deletePaymentMode(mode.id);
      _loadPaymentModes();
    }
  }

  IconData _getTypeIcon(PaymentModeType type) {
    switch (type) {
      case PaymentModeType.cash:
        return Icons.money;
      case PaymentModeType.upi:
        return Icons.account_balance;
      case PaymentModeType.card:
        return Icons.credit_card;
    }
  }

  Color _getTypeColor(PaymentModeType type) {
    switch (type) {
      case PaymentModeType.cash:
        return Colors.green;
      case PaymentModeType.upi:
        return Colors.blue;
      case PaymentModeType.card:
        return Colors.orange;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Payment Modes'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _addPaymentMode,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _paymentModes.isEmpty
              ? _buildEmptyState()
              : _buildPaymentModeList(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.payment,
            size: 80,
            color: AppTheme.onSurfaceColor.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'No payment modes yet',
            style: TextStyle(
              fontSize: 20,
              color: AppTheme.onSurfaceColor.withOpacity(0.5),
            ),
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: _addPaymentMode,
            icon: const Icon(Icons.add),
            label: const Text('Add Payment Mode'),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentModeList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _paymentModes.length,
      itemBuilder: (context, index) {
        final mode = _paymentModes[index];
        return _buildPaymentModeCard(mode);
      },
    );
  }

  Widget _buildPaymentModeCard(PaymentMode mode) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: _getTypeColor(mode.type).withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Icon(
              _getTypeIcon(mode.type),
              color: _getTypeColor(mode.type),
            ),
          ),
        ),
        title: Text(
          mode.displayName,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          mode.type.name.toUpperCase(),
          style: TextStyle(
            color: _getTypeColor(mode.type),
            fontSize: 12,
          ),
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'delete') {
              _deletePaymentMode(mode);
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete, size: 20, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Delete', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
