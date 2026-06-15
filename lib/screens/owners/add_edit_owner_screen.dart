import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/owner.dart';
import '../../providers/owner_provider.dart';

class AddEditOwnerScreen extends StatefulWidget {
  final Owner? owner;

  const AddEditOwnerScreen({super.key, this.owner});

  @override
  State<AddEditOwnerScreen> createState() => _AddEditOwnerScreenState();
}

class _AddEditOwnerScreenState extends State<AddEditOwnerScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;
  late TextEditingController _notesController;
  String _lookingFor = '';

  bool get isEditing => widget.owner != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.owner?.name ?? '');
    _emailController = TextEditingController(text: widget.owner?.email ?? '');
    _phoneController = TextEditingController(text: widget.owner?.phone ?? '');
    _addressController =
        TextEditingController(text: widget.owner?.address ?? '');
    _notesController = TextEditingController(text: widget.owner?.notes ?? '');
    _lookingFor = widget.owner?.lookingFor ?? '';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Owner' : 'Add Owner'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Full Name',
                prefixIcon: Icon(Icons.person),
                border: OutlineInputBorder(),
              ),
              validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Email',
                prefixIcon: Icon(Icons.email),
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
              validator: (v) {
                if (v?.isEmpty ?? true) return 'Required';
                if (!v!.contains('@')) return 'Invalid email';
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _phoneController,
              decoration: const InputDecoration(
                labelText: 'Phone',
                prefixIcon: Icon(Icons.phone),
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.phone,
              validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
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
            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Notes',
                prefixIcon: Icon(Icons.notes),
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _lookingFor,
              decoration: const InputDecoration(
                labelText: 'Looking for...',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person_search),
              ),
              items: const [
                DropdownMenuItem(value: '', child: Text('Not looking')),
                DropdownMenuItem(value: 'landlord', child: Text('A Landlord / Property Manager')),
                DropdownMenuItem(value: 'caretaker', child: Text('A Caretaker')),
                DropdownMenuItem(value: 'both', child: Text('Both Landlord & Caretaker')),
              ],
              onChanged: (v) => setState(() => _lookingFor = v!),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _saveOwner,
              icon: Icon(isEditing ? Icons.save : Icons.person_add),
              label: Text(isEditing ? 'Save Changes' : 'Add Owner'),
              style: FilledButton.styleFrom(padding: const EdgeInsets.all(16)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveOwner() async {
    if (!_formKey.currentState!.validate()) return;

    final owner = Owner(
      id: widget.owner?.id,
      name: _nameController.text.trim(),
      email: _emailController.text.trim(),
      phone: _phoneController.text.trim(),
      address: _addressController.text.trim(),
      notes: _notesController.text.trim(),
      lookingFor: _lookingFor,
      createdAt: widget.owner?.createdAt,
    );

    final provider = context.read<OwnerProvider>();
    if (isEditing) {
      await provider.updateOwner(owner);
    } else {
      final id = await provider.addOwner(owner);
      if (mounted) Navigator.pop(context, owner.copyWith(id: id));
      return;
    }

    if (mounted) Navigator.pop(context, owner);
  }
}
