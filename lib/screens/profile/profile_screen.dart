import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  bool _editing = false;

  @override
  void initState() {
    super.initState();
    final auth = context.read<AuthProvider>();
    _nameController = TextEditingController(text: auth.user?.name ?? '');
    _emailController = TextEditingController(text: auth.user?.email ?? '');
    _phoneController = TextEditingController(text: auth.user?.phone ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _toggleEdit() {
    if (_editing) {
      final auth = context.read<AuthProvider>();
      auth.updateProfile(
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
      );
    }
    setState(() => _editing = !_editing);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
        actions: [
          IconButton(
            icon: Icon(_editing ? Icons.save_outlined : Icons.edit_outlined),
            onPressed: _toggleEdit,
            tooltip: _editing ? 'Save' : 'Edit',
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Center(
            child: CircleAvatar(
              radius: 48,
              backgroundColor: colorScheme.primary,
              child: Text(
                (auth.user?.name.isNotEmpty == true
                        ? auth.user!.name[0]
                        : '?')
                    .toUpperCase(),
                style: const TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                    color: Colors.white),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Chip(
            avatar: Icon(_roleIcon(auth.user?.role ?? ''),
                size: 18, color: colorScheme.primary),
            label: Text(
              _roleLabel(auth.user?.role ?? ''),
              style: TextStyle(fontWeight: FontWeight.w600, color: colorScheme.primary),
            ),
            backgroundColor: colorScheme.primary.withValues(alpha: 0.1),
          ),
          const SizedBox(height: 32),
          _buildField('Full Name', _nameController, !_editing),
          const SizedBox(height: 16),
          _buildField('Email', _emailController, true),
          const SizedBox(height: 16),
          _buildField('Phone', _phoneController, !_editing),
          if (auth.user?.ownerId != null) ...[
            const SizedBox(height: 16),
            _buildInfoTile(Icons.business, 'Owner ID: ${auth.user!.ownerId}'),
          ],
          if (auth.user?.tenantId != null) ...[
            const SizedBox(height: 16),
            _buildInfoTile(Icons.people, 'Tenant ID: ${auth.user!.tenantId}'),
          ],
          const SizedBox(height: 16),
          _buildInfoTile(Icons.fingerprint, 'UID: ${auth.user?.uid ?? ''}'),
          const SizedBox(height: 40),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => auth.logout(),
              icon: const Icon(Icons.logout, color: Colors.red),
              label: const Text('Sign Out',
                  style: TextStyle(color: Colors.red, fontSize: 16)),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                side: const BorderSide(color: Colors.red),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildField(
      String label, TextEditingController controller, bool readOnly) {
    return TextField(
      controller: controller,
      readOnly: readOnly,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        prefixIcon: readOnly ? const Icon(Icons.lock_outlined, size: 18) : null,
        suffixIcon: readOnly
            ? null
            : const Icon(Icons.edit, size: 18, color: Colors.blue),
      ),
    );
  }

  Widget _buildInfoTile(IconData icon, String text) {
    return ListTile(
      dense: true,
      leading: Icon(icon, size: 20, color: Colors.grey),
      title: Text(text, style: const TextStyle(fontSize: 13, color: Colors.grey)),
    );
  }

  IconData _roleIcon(String role) {
    switch (role) {
      case 'landlord': return Icons.admin_panel_settings;
      case 'owner': return Icons.account_balance;
      case 'caretaker': return Icons.engineering;
      case 'tenant': return Icons.people;
      default: return Icons.person;
    }
  }

  String _roleLabel(String role) {
    switch (role) {
      case 'landlord': return 'Landlord / Property Manager';
      case 'owner': return 'Property Owner';
      case 'caretaker': return 'Caretaker';
      case 'tenant': return 'Tenant';
      default: return 'User';
    }
  }
}
