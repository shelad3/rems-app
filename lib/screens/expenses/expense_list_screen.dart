import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/expense_provider.dart';
import '../../providers/property_provider.dart';
import '../../models/expense.dart';
import 'add_expense_screen.dart';

class ExpenseListScreen extends StatefulWidget {
  final int? propertyId;
  const ExpenseListScreen({super.key, this.propertyId});

  @override
  State<ExpenseListScreen> createState() => _ExpenseListScreenState();
}

class _ExpenseListScreenState extends State<ExpenseListScreen> {
  final _searchController = TextEditingController();
  List<Expense> _searchResults = [];
  bool _isSearching = false;
  String _selectedCategory = 'All';

  final _categories = [
    'All', 'Repairs', 'Utilities', 'Insurance', 'Taxes',
    'Maintenance', 'Supplies', 'Marketing', 'Legal', 'Other'
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ExpenseProvider>().loadAllExpenses();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ExpenseProvider>();
    final currencyFormat = NumberFormat.currency(symbol: '\$');

    final filtered = _selectedCategory == 'All'
        ? provider.expenses
        : provider.expenses.where((e) => e.category == _selectedCategory).toList();

    final displayList = _isSearching ? _searchResults : filtered;

    return Scaffold(
      appBar: AppBar(
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'Search expenses...',
                  border: InputBorder.none,
                ),
                onChanged: (v) async {
                  if (v.isNotEmpty) {
                    _searchResults = await provider.searchExpenses(v);
                  } else {
                    _searchResults = [];
                  }
                  setState(() {});
                },
              )
            : const Text('Expenses'),
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search),
            onPressed: () => setState(() {
              _isSearching = !_isSearching;
              if (!_isSearching) {
                _searchController.clear();
                _searchResults = [];
              }
            }),
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AddExpenseScreen()),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSummaryBar(provider, currencyFormat),
          _buildCategoryFilter(),
          Expanded(
            child: provider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : _buildList(provider, displayList, currencyFormat),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryBar(ExpenseProvider provider, NumberFormat fmt) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    const Text('Total Expenses', style: TextStyle(fontSize: 11, color: Colors.grey)),
                    const SizedBox(height: 4),
                    Text(fmt.format(provider.getTotalExpenses()),
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    const Text('Transactions', style: TextStyle(fontSize: 11, color: Colors.grey)),
                    const SizedBox(height: 4),
                    Text('${provider.getExpenseCount()}',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryFilter() {
    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        children: _categories.map((cat) {
          final selected = _selectedCategory == cat;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3),
            child: ChoiceChip(
              label: Text(cat, style: const TextStyle(fontSize: 12)),
              selected: selected,
              onSelected: (_) => setState(() => _selectedCategory = cat),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildList(ExpenseProvider provider, List<Expense> expenses, NumberFormat currencyFormat) {
    if (expenses.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.money_off, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text('No expenses recorded', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: () => Navigator.push(
                context, MaterialPageRoute(builder: (_) => const AddExpenseScreen())),
              icon: const Icon(Icons.add),
              label: const Text('Add Expense'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => provider.loadAllExpenses(),
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: expenses.length,
        itemBuilder: (context, index) {
          final expense = expenses[index];
          return Dismissible(
            key: ValueKey(expense.id),
            direction: DismissDirection.endToStart,
            background: Container(
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 24),
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.red, borderRadius: BorderRadius.circular(12)),
              child: const Icon(Icons.delete, color: Colors.white),
            ),
            confirmDismiss: (_) async {
              HapticFeedback.mediumImpact();
              final ok = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Delete Expense'),
                  content: Text('Delete "${expense.title}"?'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      style: TextButton.styleFrom(foregroundColor: Colors.red),
                      child: const Text('Delete'),
                    ),
                  ],
                ),
              );
              if (ok == true) provider.deleteExpense(expense.id!);
              return false;
            },
            child: Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: _categoryColor(expense.category).withValues(alpha: 0.1),
                  child: Icon(_categoryIcon(expense.category), color: _categoryColor(expense.category), size: 20),
                ),
                title: Text(expense.title),
                subtitle: Text(
                  '${expense.category} \u2022 ${DateFormat.yMMMd().format(expense.expenseDate)}',
                  style: const TextStyle(fontSize: 12),
                ),
                trailing: Text(
                  currencyFormat.format(expense.amount),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.red[700],
                  ),
                ),
                onTap: () => _showExpenseDetails(expense),
              ),
            ),
          );
        },
      ),
    );
  }

  Color _categoryColor(String category) {
    switch (category) {
      case 'Repairs': return Colors.orange;
      case 'Utilities': return Colors.blue;
      case 'Insurance': return Colors.green;
      case 'Taxes': return Colors.red;
      case 'Maintenance': return Colors.teal;
      case 'Supplies': return Colors.purple;
      case 'Marketing': return Colors.pink;
      case 'Legal': return Colors.indigo;
      default: return Colors.grey;
    }
  }

  IconData _categoryIcon(String category) {
    switch (category) {
      case 'Repairs': return Icons.build;
      case 'Utilities': return Icons.bolt;
      case 'Insurance': return Icons.shield;
      case 'Taxes': return Icons.receipt_long;
      case 'Maintenance': return Icons.handyman;
      case 'Supplies': return Icons.inventory;
      case 'Marketing': return Icons.campaign;
      case 'Legal': return Icons.gavel;
      default: return Icons.receipt;
    }
  }

  void _showExpenseDetails(Expense expense) {
    final currencyFormat = NumberFormat.currency(symbol: '\$');
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(expense.title, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(currencyFormat.format(expense.amount),
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.red[700])),
            const SizedBox(height: 12),
            _detailRow(Icons.category, 'Category', expense.category),
            _detailRow(Icons.calendar_today, 'Date', DateFormat.yMMMd().format(expense.expenseDate)),
            if (expense.description.isNotEmpty) _detailRow(Icons.notes, 'Description', expense.description),
            if (expense.receiptPath != null) ...[
              const SizedBox(height: 8),
              Row(children: [
                const Icon(Icons.receipt, size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                const Text('Receipt: ', style: TextStyle(fontWeight: FontWeight.w500, color: Colors.grey)),
                Text('Attached'),
              ]),
            ],
          ],
        ),
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(children: [
        Icon(icon, size: 16, color: Colors.grey),
        const SizedBox(width: 8),
        Text('$label: ', style: const TextStyle(fontWeight: FontWeight.w500, color: Colors.grey)),
        Expanded(child: Text(value)),
      ]),
    );
  }
}
