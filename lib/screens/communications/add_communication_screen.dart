import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/communication_provider.dart';
import '../../providers/property_provider.dart';
import '../../providers/tenant_provider.dart';
import '../../providers/owner_provider.dart';
import '../../models/communication_log.dart';

class AddCommunicationScreen extends StatefulWidget {
  final int? tenantId;
  final int? propertyId;
  const AddCommunicationScreen({super.key, this.tenantId, this.propertyId});

  @override
  State<AddCommunicationScreen> createState() => _AddCommunicationScreenState();
}

class _AddCommunicationScreenState extends State<AddCommunicationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _subjectController = TextEditingController();
  final _notesController = TextEditingController();
  String _type = 'Phone';
  String _direction = 'Outbound';
  int? _propertyId;
  int? _tenantId;
  int? _ownerId;
  DateTime _date = DateTime.now();

  @override
  void initState() {
    super.initState();
    _tenantId = widget.tenantId;
    _propertyId = widget.propertyId;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PropertyProvider>().loadProperties();
      context.read<TenantProvider>().loadTenants();
      context.read<OwnerProvider>().loadOwners();
    });
  }

  @override
  void dispose() {
    _subjectController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final properties = context.watch<PropertyProvider>().properties;
    final tenants = context.watch<TenantProvider>().tenants;
    final owners = context.watch<OwnerProvider>().owners;

    return Scaffold(
      appBar: AppBar(title: const Text('Log Communication')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            DropdownButtonFormField<String>(
              value: _type,
              decoration: const InputDecoration(labelText: 'Type', border: OutlineInputBorder()),
              items: ['Phone', 'Email', 'SMS', 'In-person', 'Mail']
                  .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                  .toList(),
              onChanged: (v) => setState(() => _type = v!),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _direction,
              decoration: const InputDecoration(labelText: 'Direction', border: OutlineInputBorder()),
              items: ['Outbound', 'Inbound']
                  .map((d) => DropdownMenuItem(value: d, child: Text(d)))
                  .toList(),
              onChanged: (v) => setState(() => _direction = v!),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _subjectController,
              decoration: const InputDecoration(labelText: 'Subject', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            InkWell(
              onTap: _pickDate,
              child: InputDecorator(
                decoration: const InputDecoration(labelText: 'Date & Time', border: OutlineInputBorder()),
                child: Text(DateFormat.yMMMd().add_jm().format(_date)),
              ),
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
            DropdownButtonFormField<int>(
              value: _ownerId,
              decoration: const InputDecoration(labelText: 'Owner (optional)', border: OutlineInputBorder()),
              items: [const DropdownMenuItem(value: null, child: Text('None')), ...owners.map((o) => DropdownMenuItem(value: o.id, child: Text(o.name)))],
              onChanged: (v) => setState(() => _ownerId = v),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(labelText: 'Notes', border: OutlineInputBorder()),
              maxLines: 4,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _save,
              icon: const Icon(Icons.save),
              label: const Text('Save Log'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context, initialDate: _date,
      firstDate: DateTime(2020), lastDate: DateTime.now(),
    );
    if (date != null && mounted) {
      final time = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(_date));
      if (time != null) {
        setState(() => _date = DateTime(date.year, date.month, date.day, time.hour, time.minute));
      }
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    await context.read<CommunicationProvider>().addLog(
      CommunicationLog(
        propertyId: _propertyId,
        tenantId: _tenantId,
        ownerId: _ownerId,
        type: _type,
        direction: _direction,
        subject: _subjectController.text.trim(),
        notes: _notesController.text.trim(),
        communicationDate: _date,
      ),
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Communication logged')),
      );
      Navigator.pop(context);
    }
  }
}
