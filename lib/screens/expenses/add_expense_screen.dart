import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import '../../providers/expense_provider.dart';
import '../../providers/property_provider.dart';
import '../../models/expense.dart';
import '../../services/file_manager_service.dart';

class AddExpenseScreen extends StatefulWidget {
  final int? propertyId;
  const AddExpenseScreen({super.key, this.propertyId});

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  final _descController = TextEditingController();
  String _category = 'Repairs';
  int? _propertyId;
  String? _receiptPath;
  DateTime _expenseDate = DateTime.now();

  final _categories = [
    'Repairs', 'Utilities', 'Insurance', 'Taxes',
    'Maintenance', 'Supplies', 'Marketing', 'Legal', 'Other'
  ];

  @override
  void initState() {
    super.initState();
    _propertyId = widget.propertyId;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PropertyProvider>().loadProperties();
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _descController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final properties = context.watch<PropertyProvider>().properties;

    return Scaffold(
      appBar: AppBar(title: const Text('Add Expense')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Title', border: OutlineInputBorder()),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _amountController,
              decoration: const InputDecoration(
                labelText: 'Amount', border: OutlineInputBorder(), prefixText: '\$ '),
              keyboardType: TextInputType.number,
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Required';
                if (double.tryParse(v) == null) return 'Invalid amount';
                return null;
              },
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _category,
              decoration: const InputDecoration(labelText: 'Category', border: OutlineInputBorder()),
              items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
              onChanged: (v) => setState(() => _category = v!),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<int>(
              value: _propertyId,
              decoration: const InputDecoration(labelText: 'Property', border: OutlineInputBorder()),
              items: properties.map((p) => DropdownMenuItem(value: p.id, child: Text(p.name))).toList(),
              onChanged: (v) => setState(() => _propertyId = v),
              validator: (v) => v == null ? 'Select property' : null,
            ),
            const SizedBox(height: 12),
            InkWell(
              onTap: _pickDate,
              child: InputDecorator(
                decoration: const InputDecoration(labelText: 'Expense Date', border: OutlineInputBorder()),
                child: Text(DateFormat.yMMMd().format(_expenseDate)),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _descController,
              decoration: const InputDecoration(labelText: 'Description (optional)', border: OutlineInputBorder()),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            _receiptPath != null
                ? Card(
                    child: ListTile(
                      leading: const Icon(Icons.receipt),
                      title: const Text('Receipt attached'),
                      trailing: IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => setState(() => _receiptPath = null),
                      ),
                    ),
                  )
                : OutlinedButton.icon(
                    onPressed: _pickReceipt,
                    icon: const Icon(Icons.upload_file),
                    label: const Text('Attach Receipt'),
                  ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _save,
              icon: const Icon(Icons.save),
              label: const Text('Save Expense'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _expenseDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (date != null) setState(() => _expenseDate = date);
  }

  Future<void> _pickReceipt() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf'],
    );
    if (result != null && result.files.single.path != null) {
      final path = await FileManagerService.instance.saveFile(
        result.files.single.path!,
        subfolder: 'receipts',
      );
      setState(() => _receiptPath = path);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    await context.read<ExpenseProvider>().addExpense(
      Expense(
        propertyId: _propertyId!,
        title: _titleController.text.trim(),
        amount: double.parse(_amountController.text.trim()),
        category: _category,
        description: _descController.text.trim(),
        receiptPath: _receiptPath,
        expenseDate: _expenseDate,
      ),
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Expense saved')),
      );
      Navigator.pop(context);
    }
  }
}
