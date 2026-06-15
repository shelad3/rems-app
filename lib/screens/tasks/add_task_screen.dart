import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/task_provider.dart';
import '../../providers/property_provider.dart';
import '../../providers/tenant_provider.dart';
import '../../models/task.dart';

class AddTaskScreen extends StatefulWidget {
  final int? propertyId;
  final int? tenantId;
  const AddTaskScreen({super.key, this.propertyId, this.tenantId});

  @override
  State<AddTaskScreen> createState() => _AddTaskScreenState();
}

class _AddTaskScreenState extends State<AddTaskScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _assignedController = TextEditingController();
  String _priority = 'Medium';
  int? _propertyId;
  int? _tenantId;
  DateTime? _dueDate;

  @override
  void initState() {
    super.initState();
    _propertyId = widget.propertyId;
    _tenantId = widget.tenantId;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PropertyProvider>().loadProperties();
      context.read<TenantProvider>().loadTenants();
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _assignedController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final properties = context.watch<PropertyProvider>().properties;
    final tenants = context.watch<TenantProvider>().tenants;

    return Scaffold(
      appBar: AppBar(title: const Text('Add Task')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Task Title', border: OutlineInputBorder()),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _priority,
              decoration: const InputDecoration(labelText: 'Priority', border: OutlineInputBorder()),
              items: ['High', 'Medium', 'Low']
                  .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                  .toList(),
              onChanged: (v) => setState(() => _priority = v!),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<int>(
              value: _propertyId,
              decoration: const InputDecoration(labelText: 'Property (optional)', border: OutlineInputBorder()),
              items: [const DropdownMenuItem(value: null, child: Text('None')), ...properties.map((p) => DropdownMenuItem(value: p.id, child: Text(p.name)))],
              onChanged: (v) => setState(() => _propertyId = v),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<int>(
              value: _tenantId,
              decoration: const InputDecoration(labelText: 'Tenant (optional)', border: OutlineInputBorder()),
              items: [const DropdownMenuItem(value: null, child: Text('None')), ...tenants.map((t) => DropdownMenuItem(value: t.id, child: Text(t.name)))],
              onChanged: (v) => setState(() => _tenantId = v),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _assignedController,
              decoration: const InputDecoration(labelText: 'Assigned To', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            InkWell(
              onTap: _pickDueDate,
              child: InputDecorator(
                decoration: const InputDecoration(labelText: 'Due Date (optional)', border: OutlineInputBorder()),
                child: Text(_dueDate != null ? DateFormat.yMMMd().format(_dueDate!) : 'No due date'),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _descController,
              decoration: const InputDecoration(labelText: 'Description', border: OutlineInputBorder()),
              maxLines: 3,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _save,
              icon: const Icon(Icons.save),
              label: const Text('Create Task'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickDueDate() async {
    final date = await showDatePicker(
      context: context, initialDate: _dueDate ?? DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime.now(), lastDate: DateTime(2030),
    );
    if (date != null) setState(() => _dueDate = date);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    await context.read<TaskProvider>().addTask(
      Task(
        propertyId: _propertyId,
        tenantId: _tenantId,
        title: _titleController.text.trim(),
        description: _descController.text.trim(),
        priority: _priority,
        assignedTo: _assignedController.text.trim(),
        dueDate: _dueDate,
      ),
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Task created')));
      Navigator.pop(context);
    }
  }
}
