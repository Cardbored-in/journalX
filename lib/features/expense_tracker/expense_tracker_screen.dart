import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';
import '../../data/models/expense.dart';
import '../../data/models/category.dart';
import '../../data/models/payment_mode.dart';
import '../../data/models/app_settings.dart';
import '../../data/database/database_helper.dart';
import '../../core/theme/app_theme.dart';
import 'category_management_screen.dart';
import 'payment_mode_management_screen.dart';

class ExpenseTrackerScreen extends StatefulWidget {
  const ExpenseTrackerScreen({super.key});

  @override
  State<ExpenseTrackerScreen> createState() => _ExpenseTrackerScreenState();
}

class _ExpenseTrackerScreenState extends State<ExpenseTrackerScreen> {
  List<Expense> _expenses = [];
  List<Category> _categories = [];
  List<PaymentMode> _paymentModes = [];
  AppSettings? _settings;
  bool _isLoading = true;
  String _selectedCategory = 'All';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final expensesData = await DatabaseHelper.instance.queryAll('expenses');
      final categories = await DatabaseHelper.instance.getAllCategories();
      final paymentModes = await DatabaseHelper.instance.getAllPaymentModes();
      final settings = await DatabaseHelper.instance.getSettings();

      setState(() {
        _expenses = expensesData.map((map) => Expense.fromMap(map)).toList();
        _categories = categories;
        _paymentModes = paymentModes;
        _settings = settings;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading data: $e')),
        );
      }
    }
  }

  String get _currencySymbol {
    return _settings?.currencySymbol ?? '₹';
  }

  List<Expense> get _filteredExpenses {
    var filtered = _expenses;

    if (_selectedCategory != 'All') {
      filtered =
          filtered.where((e) => e.category == _selectedCategory).toList();
    }

    if (_searchController.text.isNotEmpty) {
      final query = _searchController.text.toLowerCase();
      filtered = filtered
          .where((e) => e.description.toLowerCase().contains(query))
          .toList();
    }

    return filtered;
  }

  double get _totalExpenses {
    return _filteredExpenses.fold(0, (sum, e) => sum + e.amount);
  }

  String _getCategoryIcon(String categoryName) {
    final category = _categories.firstWhere(
      (c) => c.name == categoryName,
      orElse: () => Category(
        id: '',
        name: categoryName,
        icon: '💰',
        createdAt: DateTime.now(),
      ),
    );
    return category.icon;
  }

  PaymentMode? _getPaymentModeById(String? id) {
    if (id == null) return null;
    try {
      return _paymentModes.firstWhere((m) => m.id == id);
    } catch (e) {
      return null;
    }
  }

  Future<void> _addExpense() async {
    if (_categories.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add categories first')),
      );
      return;
    }

    final amountController = TextEditingController();
    final descriptionController = TextEditingController();
    String selectedCategory = _categories.first.name;
    String? selectedPaymentModeId;

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
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Add Expense',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: amountController,
                  decoration: InputDecoration(
                    hintText: 'Amount',
                    prefixText: '$_currencySymbol ',
                  ),
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  autofocus: true,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(
                    hintText: 'What did you spend on?',
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Category',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _categories.map((category) {
                    final isSelected = selectedCategory == category.name;
                    return ChoiceChip(
                      label: Text('${category.icon} ${category.name}'),
                      selected: isSelected,
                      onSelected: (selected) {
                        setModalState(() {
                          selectedCategory = category.name;
                        });
                      },
                      selectedColor: AppTheme.primaryColor.withOpacity(0.3),
                    );
                  }).toList(),
                ),
                if (_paymentModes.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  const Text(
                    'Payment Mode',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _paymentModes.map((mode) {
                      final isSelected = selectedPaymentModeId == mode.id;
                      return ChoiceChip(
                        label: Text(mode.displayName),
                        selected: isSelected,
                        onSelected: (selected) {
                          setModalState(() {
                            selectedPaymentModeId = selected ? mode.id : null;
                          });
                        },
                        selectedColor: AppTheme.secondaryColor.withOpacity(0.3),
                      );
                    }).toList(),
                  ),
                ],
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Save'),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (result == true) {
      final amount = double.tryParse(amountController.text);
      if (amount == null || amount <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter a valid amount')),
        );
        return;
      }

      final expense = Expense(
        id: const Uuid().v4(),
        amount: amount,
        description: descriptionController.text.trim(),
        category: selectedCategory,
        paymentModeId: selectedPaymentModeId,
        createdAt: DateTime.now(),
      );

      await DatabaseHelper.instance.insert('expenses', expense.toMap());
      _loadData();
    }
  }

  Future<void> _deleteExpense(Expense expense) async {
    await DatabaseHelper.instance.delete('expenses', expense.id);
    _loadData();
  }

  Future<void> _showExpenseOptions(Expense expense) async {
    final action = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: AppTheme.surfaceColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.edit),
            title: const Text('Edit'),
            onTap: () => Navigator.pop(context, 'edit'),
          ),
          ListTile(
            leading: const Icon(Icons.delete, color: Colors.red),
            title: const Text('Delete', style: TextStyle(color: Colors.red)),
            onTap: () => Navigator.pop(context, 'delete'),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );

    if (action == 'edit') {
      _editExpense(expense);
    } else if (action == 'delete') {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Delete Expense'),
          content: Text(
              'Delete this expense of ${_currencySymbol}${expense.amount}?'),
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
        await DatabaseHelper.instance.delete('expenses', expense.id);
        _loadData();
      }
    }
  }

  Future<void> _editExpense(Expense expense) async {
    final amountController =
        TextEditingController(text: expense.amount.toString());
    final descriptionController =
        TextEditingController(text: expense.description);
    String selectedCategory = expense.category;
    String? selectedPaymentModeId = expense.paymentModeId;

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
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Edit Expense',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: amountController,
                  decoration: InputDecoration(
                    hintText: 'Amount',
                    prefixText: '$_currencySymbol ',
                  ),
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  autofocus: true,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(
                    hintText: 'What did you spend on?',
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Category',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _categories.map((category) {
                    final isSelected = selectedCategory == category.name;
                    return ChoiceChip(
                      label: Text('${category.icon} ${category.name}'),
                      selected: isSelected,
                      onSelected: (selected) {
                        setModalState(() {
                          selectedCategory = category.name;
                        });
                      },
                      selectedColor: AppTheme.primaryColor.withOpacity(0.3),
                    );
                  }).toList(),
                ),
                if (_paymentModes.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  const Text(
                    'Payment Mode',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _paymentModes.map((mode) {
                      final isSelected = selectedPaymentModeId == mode.id;
                      return ChoiceChip(
                        label: Text(mode.displayName),
                        selected: isSelected,
                        onSelected: (selected) {
                          setModalState(() {
                            selectedPaymentModeId = selected ? mode.id : null;
                          });
                        },
                        selectedColor: AppTheme.secondaryColor.withOpacity(0.3),
                      );
                    }).toList(),
                  ),
                ],
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Save Changes'),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (result == true) {
      final amount = double.tryParse(amountController.text);
      if (amount == null || amount <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter a valid amount')),
        );
        return;
      }

      final updatedExpense = expense.copyWith(
        amount: amount,
        description: descriptionController.text.trim(),
        category: selectedCategory,
        paymentModeId: selectedPaymentModeId,
      );

      await DatabaseHelper.instance
          .update('expenses', updatedExpense.toMap(), expense.id);
      _loadData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Expenses'),
        actions: [
          IconButton(
            icon: const Icon(Icons.category),
            tooltip: 'Manage Categories',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const CategoryManagementScreen(),
                ),
              ).then((_) => _loadData());
            },
          ),
          IconButton(
            icon: const Icon(Icons.payment),
            tooltip: 'Manage Payment Modes',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const PaymentModeManagementScreen(),
                ),
              ).then((_) => _loadData());
            },
          ),
        ],
      ),
      body: Column(
        children: [
          _buildHeader(),
          _buildCategoryFilter(),
          _buildSearchBar(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredExpenses.isEmpty
                    ? _buildEmptyState()
                    : _buildExpensesList(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addExpense,
        icon: const Icon(Icons.add),
        label: const Text('Add'),
      ),
    );
  }

  Widget _buildHeader() {
    final currencyFormat = NumberFormat.currency(symbol: _currencySymbol);

    return Container(
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryColor,
            AppTheme.primaryColor.withOpacity(0.7),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          const Text(
            'Total Spending',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            currencyFormat.format(_totalExpenses),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${_filteredExpenses.length} transactions',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryFilter() {
    final categoryNames = ['All', ..._categories.map((c) => c.name)];

    return SizedBox(
      height: 50,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: categoryNames.length,
        itemBuilder: (context, index) {
          final category = categoryNames[index];
          final isSelected = _selectedCategory == category;

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(
                category == 'All'
                    ? 'All'
                    : '${_getCategoryIcon(category)} $category',
              ),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  _selectedCategory = category;
                });
              },
              selectedColor: AppTheme.primaryColor.withOpacity(0.3),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search expenses...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    setState(() {});
                  },
                )
              : null,
          isDense: true,
          contentPadding:
              const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
        ),
        onChanged: (value) => setState(() {}),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.account_balance_wallet,
            size: 80,
            color: AppTheme.onSurfaceColor.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'No expenses yet',
            style: TextStyle(
              fontSize: 20,
              color: AppTheme.onSurfaceColor.withOpacity(0.5),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap + to add your first expense',
            style: TextStyle(
              color: AppTheme.onSurfaceColor.withOpacity(0.3),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpensesList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _filteredExpenses.length,
      itemBuilder: (context, index) {
        final expense = _filteredExpenses[index];
        return _buildExpenseCard(expense);
      },
    );
  }

  Widget _buildExpenseCard(Expense expense) {
    final dateFormat = DateFormat('MMM d, yyyy');
    final currencyFormat = NumberFormat.currency(symbol: _currencySymbol);
    final paymentMode = _getPaymentModeById(expense.paymentModeId);

    return Dismissible(
      key: Key(expense.id),
      direction: DismissDirection.endToStart,
      confirmDismiss: (direction) async {
        final confirm = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Delete Expense'),
            content: Text(
                'Delete this expense of ${_currencySymbol}${expense.amount}?'),
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
        return confirm ?? false;
      },
      onDismissed: (_) => _deleteExpense(expense),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: AppTheme.errorColor,
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      child: InkWell(
        onTap: () => _showExpenseOptions(expense),
        onLongPress: () => _showExpenseOptions(expense),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.surfaceColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    _getCategoryIcon(expense.category),
                    style: const TextStyle(fontSize: 24),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      expense.category,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (expense.description.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        expense.description,
                        style: TextStyle(
                          color: AppTheme.onSurfaceColor.withOpacity(0.7),
                          fontSize: 13,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 4),
                    Text(
                      paymentMode != null
                          ? '${paymentMode.displayName} • ${dateFormat.format(expense.createdAt)}'
                          : dateFormat.format(expense.createdAt),
                      style: TextStyle(
                        color: AppTheme.onSurfaceColor.withOpacity(0.5),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    currencyFormat.format(expense.amount),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
