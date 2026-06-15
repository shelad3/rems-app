import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/property.dart';
import '../../models/unit.dart';
import '../../models/owner.dart';
import '../../providers/property_provider.dart';
import '../../providers/owner_provider.dart';
import '../../providers/auth_provider.dart';
import '../owners/add_edit_owner_screen.dart';

class AddEditPropertyScreen extends StatefulWidget {
  final Property? property;

  const AddEditPropertyScreen({super.key, this.property});

  @override
  State<AddEditPropertyScreen> createState() => _AddEditPropertyScreenState();
}

class _AddEditPropertyScreenState extends State<AddEditPropertyScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _addressController;
  late TextEditingController _cityController;
  late TextEditingController _stateController;
  late TextEditingController _zipController;
  late TextEditingController _notesController;
  int? _selectedOwnerId;
  String _type = 'Residential';
  String _status = 'rental';
  int _totalUnits = 1;

  bool get isEditing => widget.property != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.property?.name ?? '');
    _addressController =
        TextEditingController(text: widget.property?.address ?? '');
    _cityController = TextEditingController(text: widget.property?.city ?? '');
    _stateController =
        TextEditingController(text: widget.property?.state ?? '');
    _zipController = TextEditingController(text: widget.property?.zip ?? '');
    _notesController =
        TextEditingController(text: widget.property?.notes ?? '');
    _selectedOwnerId = widget.property?.ownerId;
    _type = widget.property?.type ?? 'Residential';
    _status = widget.property?.status ?? 'rental';
    _totalUnits = widget.property?.totalUnits ?? 1;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ownerProvider = context.read<OwnerProvider>();
      ownerProvider.loadOwners();
      final auth = context.read<AuthProvider>();
      if (auth.user?.role == 'owner' && auth.user?.ownerId != null) {
        setState(() => _selectedOwnerId = auth.user!.ownerId);
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _zipController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ownerProvider = context.watch<OwnerProvider>();
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Property' : 'Add Property'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Property Name',
                prefixIcon: Icon(Icons.business),
                border: OutlineInputBorder(),
              ),
              validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<int>(
                    value: _selectedOwnerId,
                    decoration: const InputDecoration(
                      labelText: 'Owner',
                      prefixIcon: Icon(Icons.person),
                      border: OutlineInputBorder(),
                    ),
                    hint: const Text('Select owner'),
                    items: ownerProvider.owners.map((o) {
                      return DropdownMenuItem(value: o.id, child: Text(o.name));
                    }).toList(),
                    onChanged: (v) => setState(() => _selectedOwnerId = v),
                    validator: (v) => v == null ? 'Select an owner' : null,
                  ),
                ),
                const SizedBox(width: 8),
                Tooltip(
                  message: 'Add new owner',
                  child: IconButton.filled(
                    onPressed: _addNewOwner,
                    icon: const Icon(Icons.person_add),
                    style: IconButton.styleFrom(
                      minimumSize: const Size(48, 56),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _type,
              decoration: const InputDecoration(
                labelText: 'Property Type',
                prefixIcon: Icon(Icons.category),
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'Residential', child: Text('Residential')),
                DropdownMenuItem(value: 'Commercial', child: Text('Commercial')),
                DropdownMenuItem(value: 'Mixed Use', child: Text('Mixed Use')),
              ],
              onChanged: (v) => setState(() => _type = v!),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _status,
              decoration: const InputDecoration(
                labelText: 'Listing Status',
                prefixIcon: Icon(Icons.info_outline),
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'rental', child: Text('Rental')),
                DropdownMenuItem(value: 'for_sale', child: Text('For Sale')),
                DropdownMenuItem(value: 'under_construction', child: Text('Under Construction')),
              ],
              onChanged: (v) => setState(() => _status = v!),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _addressController,
              decoration: const InputDecoration(
                labelText: 'Address',
                prefixIcon: Icon(Icons.location_on),
                border: OutlineInputBorder(),
              ),
              validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _cityController,
                    decoration: const InputDecoration(
                      labelText: 'City',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _stateController,
                    decoration: const InputDecoration(
                      labelText: 'State',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 100,
                  child: TextFormField(
                    controller: _zipController,
                    decoration: const InputDecoration(
                      labelText: 'ZIP',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                  ),
                ),
              ],
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
            if (!isEditing) ...[
              const SizedBox(height: 24),
              Text(
                'Units',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Text('Number of units:'),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.remove_circle_outline),
                    onPressed: _totalUnits > 1
                        ? () => setState(() => _totalUnits--)
                        : null,
                  ),
                  Text(
                    '$_totalUnits',
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline),
                    onPressed: () => setState(() => _totalUnits++),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _saveProperty,
              icon: Icon(isEditing ? Icons.save : Icons.add),
              label: Text(isEditing ? 'Save Changes' : 'Add Property'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.all(16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _addNewOwner() async {
    final result = await Navigator.push<Owner>(
      context,
      MaterialPageRoute(builder: (_) => const AddEditOwnerScreen()),
    );
    if (result != null) {
      await context.read<OwnerProvider>().loadOwners();
      setState(() => _selectedOwnerId = result.id);
    }
  }

  Future<void> _saveProperty() async {
    if (!_formKey.currentState!.validate()) return;

    final property = Property(
      id: widget.property?.id,
      ownerId: _selectedOwnerId!,
      name: _nameController.text.trim(),
      address: _addressController.text.trim(),
      city: _cityController.text.trim(),
      state: _stateController.text.trim(),
      zip: _zipController.text.trim(),
      type: _type,
      status: _status,
      totalUnits: _totalUnits,
      notes: _notesController.text.trim(),
      createdAt: widget.property?.createdAt,
    );

    final provider = context.read<PropertyProvider>();
    if (isEditing) {
      await provider.updateProperty(property);
    } else {
      final propertyId = await provider.addProperty(property);
      for (int i = 1; i <= _totalUnits; i++) {
        await provider.addUnit(Unit(
          propertyId: propertyId,
          unitNumber: i.toString().padLeft(2, '0'),
          rentAmount: 0,
        ));
      }
    }

    if (mounted) Navigator.pop(context);
  }
}
