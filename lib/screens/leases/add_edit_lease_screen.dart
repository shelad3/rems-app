import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/lease.dart';
import '../../providers/lease_provider.dart';
import '../../providers/property_provider.dart';
import '../../providers/tenant_provider.dart';

class AddEditLeaseScreen extends StatefulWidget {
  final Lease? lease;

  const AddEditLeaseScreen({super.key, this.lease});

  @override
  State<AddEditLeaseScreen> createState() => _AddEditLeaseScreenState();
}

class _AddEditLeaseScreenState extends State<AddEditLeaseScreen> {
  final _formKey = GlobalKey<FormState>();
  int? _selectedTenantId;
  int? _selectedPropertyId;
  int? _selectedUnitId;
  late TextEditingController _rentController;
  late TextEditingController _depositController;
  late TextEditingController _notesController;
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now().add(const Duration(days: 365));

  @override
  void initState() {
    super.initState();
    _rentController = TextEditingController(
        text: widget.lease?.rentAmount.toString() ?? '');
    _depositController = TextEditingController(
        text: widget.lease?.securityDeposit.toString() ?? '');
    _notesController =
        TextEditingController(text: widget.lease?.notes ?? '');
    _startDate = widget.lease?.startDate ?? DateTime.now();
    _endDate = widget.lease?.endDate ??
        DateTime.now().add(const Duration(days: 365));
    _selectedTenantId = widget.lease?.tenantId;
    _selectedUnitId = widget.lease?.unitId;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TenantProvider>().loadTenants();
      context.read<PropertyProvider>().loadProperties();
    });
  }

  @override
  void dispose() {
    _rentController.dispose();
    _depositController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tenantProvider = context.watch<TenantProvider>();
    final propertyProvider = context.watch<PropertyProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.lease != null ? 'Edit Lease' : 'Create Lease'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            DropdownButtonFormField<int>(
              value: _selectedTenantId,
              decoration: const InputDecoration(
                labelText: 'Tenant',
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
                items: propertyProvider.units
                    .where((u) => !u.isOccupied)
                    .map((u) {
                  return DropdownMenuItem(
                      value: u.id, child: Text('Unit ${u.unitNumber}'));
                }).toList(),
                onChanged: (v) => setState(() => _selectedUnitId = v),
                validator: (v) => v == null
                    ? 'Select a unit (only vacant units shown)'
                    : null,
              ),
            ],
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildDatePicker(
                    label: 'Start Date',
                    date: _startDate,
                    onPick: (d) => setState(() => _startDate = d),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildDatePicker(
                    label: 'End Date',
                    date: _endDate,
                    onPick: (d) => setState(() => _endDate = d),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _rentController,
              decoration: const InputDecoration(
                labelText: 'Monthly Rent (\$)',
                prefixIcon: Icon(Icons.attach_money),
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              validator: (v) =>
                  v?.isEmpty ?? true ? 'Enter rent amount' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _depositController,
              decoration: const InputDecoration(
                labelText: 'Security Deposit (\$)',
                prefixIcon: Icon(Icons.savings),
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Notes',
                prefixIcon: Icon(Icons.notes),
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _saveLease,
              icon: Icon(widget.lease != null ? Icons.save : Icons.add),
              label: Text(
                  widget.lease != null ? 'Save Changes' : 'Create Lease'),
              style: FilledButton.styleFrom(padding: const EdgeInsets.all(16)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDatePicker({
    required String label,
    required DateTime date,
    required ValueChanged<DateTime> onPick,
  }) {
    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: date,
          firstDate: DateTime(2020),
          lastDate: DateTime(2035),
        );
        if (picked != null) onPick(picked);
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: const Icon(Icons.calendar_today),
          border: const OutlineInputBorder(),
        ),
        child: Text(
          '${date.month}/${date.day}/${date.year}',
          style: const TextStyle(fontSize: 14),
        ),
      ),
    );
  }

  Future<void> _saveLease() async {
    if (!_formKey.currentState!.validate()) return;

    final lease = Lease(
      id: widget.lease?.id,
      unitId: _selectedUnitId!,
      tenantId: _selectedTenantId!,
      startDate: _startDate,
      endDate: _endDate,
      rentAmount: double.tryParse(_rentController.text) ?? 0,
      securityDeposit: double.tryParse(_depositController.text) ?? 0,
      notes: _notesController.text.trim(),
      createdAt: widget.lease?.createdAt,
    );

    final provider = context.read<LeaseProvider>();
    if (widget.lease != null) {
      await provider.updateLease(lease);
    } else {
      await provider.addLease(lease);
    }

    if (mounted) Navigator.pop(context);
  }
}
