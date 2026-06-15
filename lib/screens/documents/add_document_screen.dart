import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../../providers/document_provider.dart';
import '../../providers/property_provider.dart';
import '../../providers/tenant_provider.dart';
import '../../models/document.dart';
import '../../services/file_manager_service.dart';

class AddDocumentScreen extends StatefulWidget {
  final int? propertyId;
  final int? unitId;
  final int? tenantId;

  const AddDocumentScreen({
    super.key,
    this.propertyId,
    this.unitId,
    this.tenantId,
  });

  @override
  State<AddDocumentScreen> createState() => _AddDocumentScreenState();
}

class _AddDocumentScreenState extends State<AddDocumentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _notesController = TextEditingController();
  String _category = 'Other';
  String? _selectedFilePath;
  String? _selectedFileName;

  int? _selectedPropertyId;
  int? _selectedUnitId;
  int? _selectedTenantId;

  final _categories = [
    'Lease', 'ID', 'Inspection', 'Receipt', 'Contract', 'Notice', 'Other'
  ];

  bool get _hasTarget => widget.propertyId != null ||
      widget.unitId != null ||
      widget.tenantId != null;

  @override
  void initState() {
    super.initState();
    _selectedPropertyId = widget.propertyId;
    _selectedUnitId = widget.unitId;
    _selectedTenantId = widget.tenantId;
    if (!_hasTarget) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.read<PropertyProvider>().loadProperties();
        context.read<TenantProvider>().loadTenants();
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Upload Document')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (!_hasTarget) ...[
              _buildPropertyDropdown(),
              const SizedBox(height: 12),
              _buildTenantDropdown(),
              const SizedBox(height: 12),
            ],
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Document Name',
                border: OutlineInputBorder(),
              ),
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? 'Enter document name'
                  : null,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _category,
              decoration: const InputDecoration(
                labelText: 'Category',
                border: OutlineInputBorder(),
              ),
              items: _categories
                  .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                  .toList(),
              onChanged: (v) => setState(() => _category = v!),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Notes (optional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            _selectedFileName != null
                ? Card(
                    child: ListTile(
                      leading: const Icon(Icons.insert_drive_file),
                      title: Text(_selectedFileName!,
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                      trailing: IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => setState(() {
                          _selectedFilePath = null;
                          _selectedFileName = null;
                        }),
                      ),
                    ),
                  )
                : OutlinedButton.icon(
                    onPressed: _pickFile,
                    icon: const Icon(Icons.upload_file),
                    label: const Text('Select File'),
                  ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _save,
              icon: const Icon(Icons.save),
              label: const Text('Upload Document'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPropertyDropdown() {
    final properties = context.watch<PropertyProvider>().properties;
    return DropdownButtonFormField<int>(
      value: _selectedPropertyId,
      decoration: const InputDecoration(
        labelText: 'Property',
        border: OutlineInputBorder(),
      ),
      items: properties
          .map((p) =>
              DropdownMenuItem(value: p.id, child: Text(p.name)))
          .toList(),
      onChanged: (v) => setState(() => _selectedPropertyId = v),
    );
  }

  Widget _buildTenantDropdown() {
    final tenants = context.watch<TenantProvider>().tenants;
    return DropdownButtonFormField<int>(
      value: _selectedTenantId,
      decoration: const InputDecoration(
        labelText: 'Tenant',
        border: OutlineInputBorder(),
      ),
      items: tenants
          .map((t) =>
              DropdownMenuItem(value: t.id, child: Text(t.name)))
          .toList(),
      onChanged: (v) => setState(() => _selectedTenantId = v),
    );
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles();
    if (result != null && result.files.single.path != null) {
      setState(() {
        _selectedFilePath = result.files.single.path;
        _selectedFileName = result.files.single.name;
        if (_nameController.text.isEmpty) {
          _nameController.text = result.files.single.name;
        }
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate() || _selectedFilePath == null) {
      if (_selectedFilePath == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a file')),
        );
      }
      return;
    }

    final savedPath =
        await FileManagerService.instance.saveFile(_selectedFilePath!);

    final doc = Document(
      propertyId: _selectedPropertyId,
      unitId: _selectedUnitId,
      tenantId: _selectedTenantId,
      name: _nameController.text.trim(),
      filePath: savedPath,
      category: _category,
      notes: _notesController.text.trim(),
    );

    await context.read<DocumentProvider>().addDocument(doc);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Document uploaded')),
      );
      Navigator.pop(context);
    }
  }
}
