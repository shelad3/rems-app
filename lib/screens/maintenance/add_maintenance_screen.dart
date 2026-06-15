import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/maintenance_request.dart';
import '../../providers/maintenance_provider.dart';
import '../../providers/tenant_provider.dart';
import '../../providers/property_provider.dart';

class AddMaintenanceScreen extends StatefulWidget {
  const AddMaintenanceScreen({super.key});

  @override
  State<AddMaintenanceScreen> createState() => _AddMaintenanceScreenState();
}

class _AddMaintenanceScreenState extends State<AddMaintenanceScreen> {
  final _formKey = GlobalKey<FormState>();
  int? _selectedTenantId;
  int? _selectedPropertyId;
  int? _selectedUnitId;
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  String _priority = 'Medium';

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _descriptionController = TextEditingController();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TenantProvider>().loadTenants();
      context.read<PropertyProvider>().loadProperties();
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tenantProvider = context.watch<TenantProvider>();
    final propertyProvider = context.watch<PropertyProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('New Maintenance Request')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Title',
                prefixIcon: Icon(Icons.title),
                border: OutlineInputBorder(),
              ),
              validator: (v) =>
                  v?.isEmpty ?? true ? 'Enter a title' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description',
                prefixIcon: Icon(Icons.description),
                border: OutlineInputBorder(),
              ),
              maxLines: 4,
              validator: (v) =>
                  v?.isEmpty ?? true ? 'Describe the issue' : null,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<int>(
              value: _selectedTenantId,
              decoration: const InputDecoration(
                labelText: 'Reported By',
                prefixIcon: Icon(Icons.person),
                border: OutlineInputBorder(),
              ),
              items: tenantProvider.tenants.map((t) {
                return DropdownMenuItem(value: t.id, child: Text(t.name));
              }).toList(),
              onChanged: (v) => setState(() => _selectedTenantId = v),
              validator: (v) => v == null ? 'Select a tenant' : null,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<int>(
              value: _selectedPropertyId,
              decoration: const InputDecoration(
                labelText: 'Property',
                prefixIcon: Icon(Icons.business),
                border: OutlineInputBorder(),
              ),
              items: propertyProvider.properties.map((p) {
                return DropdownMenuItem(value: p.id, child: Text(p.name));
              }).toList(),
              onChanged: (v) {
                setState(() {
                  _selectedPropertyId = v;
                  _selectedUnitId = null;
                });
                if (v != null) {
                  propertyProvider.loadUnitsByProperty(v);
                }
              },
              validator: (v) => v == null ? 'Select a property' : null,
            ),
            if (_selectedPropertyId != null) ...[
              const SizedBox(height: 16),
              DropdownButtonFormField<int>(
                value: _selectedUnitId,
                decoration: const InputDecoration(
                  labelText: 'Unit',
                  prefixIcon: Icon(Icons.door_front_door),
                  border: OutlineInputBorder(),
                ),
                items: propertyProvider.units.map((u) {
                  return DropdownMenuItem(
                      value: u.id,
                      child: Text('Unit ${u.unitNumber}'));
                }).toList(),
                onChanged: (v) => setState(() => _selectedUnitId = v),
                validator: (v) => v == null ? 'Select a unit' : null,
              ),
            ],
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _priority,
              decoration: const InputDecoration(
                labelText: 'Priority',
                prefixIcon: Icon(Icons.flag),
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(
                    value: 'Low', child: Text('Low')),
                DropdownMenuItem(
                    value: 'Medium', child: Text('Medium')),
                DropdownMenuItem(
                    value: 'High', child: Text('High')),
                DropdownMenuItem(
                    value: 'Emergency',
                    child: Text('Emergency',
                        style: TextStyle(color: Colors.red))),
              ],
              onChanged: (v) => setState(() => _priority = v!),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _saveRequest,
              icon: const Icon(Icons.add),
              label: const Text('Submit Request'),
              style: FilledButton.styleFrom(padding: const EdgeInsets.all(16)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveRequest() async {
    if (!_formKey.currentState!.validate()) return;

    final request = MaintenanceRequest(
      unitId: _selectedUnitId!,
      tenantId: _selectedTenantId!,
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      priority: _priority,
    );

    await context.read<MaintenanceProvider>().addRequest(request);
    if (mounted) Navigator.pop(context);
  }
}
