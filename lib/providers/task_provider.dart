import 'package:flutter/foundation.dart';
import '../database/database_helper.dart';
import '../models/task.dart';

class TaskProvider extends ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper.instance;
  List<Task> _tasks = [];
  bool _isLoading = false;

  List<Task> get tasks => _tasks;
  bool get isLoading => _isLoading;

  Future<void> loadTasks({String? status, int? propertyId}) async {
    _isLoading = true;
    notifyListeners();
    final maps = await _db.getTasks(status: status, propertyId: propertyId);
    _tasks = maps.map((m) => Task.fromMap(m)).toList();
    _isLoading = false;
    notifyListeners();
  }

  Future<List<Task>> searchTasks(String query) async {
    final maps = await _db.searchTasks(query);
    return maps.map((m) => Task.fromMap(m)).toList();
  }

  Future<void> addTask(Task task) async {
    await _db.insert('tasks', task.toMap());
    await loadTasks();
  }

  Future<void> updateTask(Task task) async {
    await _db.update('tasks', task.toMap(), task.id!);
    await loadTasks();
  }

  Future<void> completeTask(int id) async {
    await _db.update('tasks', {
      'status': 'Completed',
      'completed_at': DateTime.now().toIso8601String(),
    }, id);
    await loadTasks();
  }

  Future<void> deleteTask(int id) async {
    await _db.delete('tasks', id);
    await loadTasks();
  }

  int get pendingCount => _tasks.where((t) => t.status == 'Pending').length;
  int get overdueCount => _tasks.where((t) {
        if (t.status == 'Completed' || t.dueDate == null) return false;
        return t.dueDate!.isBefore(DateTime.now());
      }).length;
}
