import 'package:flutter/foundation.dart';
import '../database/database_helper.dart';
import '../models/expense.dart';

class ExpenseProvider extends ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper.instance;
  List<Expense> _expenses = [];
  List<Map<String, dynamic>> _categoryTotals = [];
  Map<String, dynamic> _summary = {};
  bool _isLoading = false;

  List<Expense> get expenses => _expenses;
  List<Map<String, dynamic>> get categoryTotals => _categoryTotals;
  Map<String, dynamic> get summary => _summary;
  bool get isLoading => _isLoading;

  Future<void> loadExpensesByProperty(int propertyId) async {
    _isLoading = true;
    notifyListeners();
    final maps = await _db.getExpensesByProperty(propertyId);
    _expenses = maps.map((m) => Expense.fromMap(m)).toList();
    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadAllExpenses() async {
    _isLoading = true;
    notifyListeners();
    final maps = await _db.queryAll('expenses');
    _expenses = maps.map((m) => Expense.fromMap(m)).toList();
    _categoryTotals = await _db.getExpensesByCategory();
    _summary = await _db.getExpenseSummary();
    _isLoading = false;
    notifyListeners();
  }

  Future<List<Expense>> searchExpenses(String query) async {
    final maps = await _db.searchExpenses(query);
    return maps.map((m) => Expense.fromMap(m)).toList();
  }

  Future<void> addExpense(Expense expense) async {
    await _db.insert('expenses', expense.toMap());
    await loadAllExpenses();
  }

  Future<void> updateExpense(Expense expense) async {
    await _db.update('expenses', expense.toMap(), expense.id!);
    await loadAllExpenses();
  }

  Future<void> deleteExpense(int id) async {
    await _db.delete('expenses', id);
    await loadAllExpenses();
  }

  Future<Map<String, dynamic>> getProfitLoss(int propertyId) async {
    return await _db.getProfitLoss(propertyId);
  }

  double getTotalExpenses() {
    return (_summary['total_expenses'] as num?)?.toDouble() ?? 0;
  }

  int getExpenseCount() {
    return (_summary['expense_count'] as int?) ?? 0;
  }
}
