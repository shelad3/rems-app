import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/task_provider.dart';
import '../../models/task.dart';
import 'add_task_screen.dart';

class TaskListScreen extends StatefulWidget {
  const TaskListScreen({super.key});

  @override
  State<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen> {
  String _filter = 'All';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TaskProvider>().loadTasks();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TaskProvider>();

    final tasks = _filter == 'All'
        ? provider.tasks
        : provider.tasks.where((t) => t.status == _filter).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tasks'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => Navigator.push(
              context, MaterialPageRoute(builder: (_) => const AddTaskScreen())),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSummaryBar(provider),
          _buildFilterBar(),
          Expanded(
            child: provider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : _buildList(provider, tasks),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryBar(TaskProvider provider) {
    return Container(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          _summaryChip('Pending', provider.pendingCount, Colors.orange),
          const SizedBox(width: 8),
          _summaryChip('Overdue', provider.overdueCount, Colors.red),
          const SizedBox(width: 8),
          _summaryChip('Total', provider.tasks.length, Colors.blue),
        ],
      ),
    );
  }

  Widget _summaryChip(String label, int count, Color color) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            children: [
              Text('$count', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
              Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: ['All', 'Pending', 'In Progress', 'Completed'].map((f) {
          final selected = _filter == f;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3),
            child: ChoiceChip(
              label: Text(f, style: const TextStyle(fontSize: 11)),
              selected: selected,
              onSelected: (_) => setState(() => _filter = f),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildList(TaskProvider provider, List<Task> tasks) {
    if (tasks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.checklist, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text('No tasks', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: () => Navigator.push(
                context, MaterialPageRoute(builder: (_) => const AddTaskScreen())),
              icon: const Icon(Icons.add),
              label: const Text('Add Task'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => provider.loadTasks(),
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: tasks.length,
        itemBuilder: (context, index) {
          final task = tasks[index];
          final isOverdue = task.status != 'Completed' && task.dueDate != null && task.dueDate!.isBefore(DateTime.now());

          return Dismissible(
            key: ValueKey(task.id),
            direction: DismissDirection.endToStart,
            background: Container(
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 24),
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(12)),
              child: const Icon(Icons.delete, color: Colors.white),
            ),
            confirmDismiss: (_) async {
              HapticFeedback.mediumImpact();
              final ok = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Delete Task'),
                  content: Text('Delete "${task.title}"?'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      style: TextButton.styleFrom(foregroundColor: Colors.red), child: const Text('Delete'),
                    ),
                  ],
                ),
              );
              if (ok == true) provider.deleteTask(task.id!);
              return false;
            },
            child: Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: CheckboxListTile(
                secondary: CircleAvatar(
                  backgroundColor: _priorityColor(task.priority).withValues(alpha: 0.1),
                  child: Icon(_priorityIcon(task.priority), color: _priorityColor(task.priority), size: 20),
                ),
                title: Text(task.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (task.assignedTo != null)
                      Text('Assigned to ${task.assignedTo}', style: const TextStyle(fontSize: 11)),
                    if (task.dueDate != null)
                      Row(
                        children: [
                          Icon(Icons.access_time, size: 12, color: isOverdue ? Colors.red : Colors.grey),
                          const SizedBox(width: 4),
                          Text(
                            DateFormat.yMMMd().format(task.dueDate!),
                            style: TextStyle(fontSize: 11, color: isOverdue ? Colors.red : Colors.grey),
                          ),
                        ],
                      ),
                  ],
                ),
                value: task.status == 'Completed',
                controlAffinity: ListTileControlAffinity.trailing,
                onChanged: task.status == 'Completed'
                    ? null
                    : (_) => provider.completeTask(task.id!),
              ),
            ),
          );
        },
      ),
    );
  }

  Color _priorityColor(String priority) {
    switch (priority) {
      case 'High': return Colors.red;
      case 'Medium': return Colors.orange;
      case 'Low': return Colors.green;
      default: return Colors.grey;
    }
  }

  IconData _priorityIcon(String priority) {
    switch (priority) {
      case 'High': return Icons.flag;
      case 'Medium': return Icons.flag_outlined;
      case 'Low': return Icons.outlined_flag;
      default: return Icons.task;
    }
  }
}
