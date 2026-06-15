import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../database/database_helper.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  String _role = 'tenant';
  bool _obscurePassword = true;

  int? _selectedOwnerId;
  bool _linkingLoaded = false;
  List<Map<String, dynamic>> _owners = [];

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _loadOwners() async {
    if (_linkingLoaded) return;
    final db = DatabaseHelper.instance;
    _owners = await db.queryAll('owners');
    _linkingLoaded = true;
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Create Account')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                const Icon(Icons.home_work_outlined, size: 56),
                const SizedBox(height: 8),
                Text('Join REMS',
                    style: theme.textTheme.headlineSmall
                        ?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 32),
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Full Name',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person_outlined),
                  ),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Enter your name' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Enter your email';
                    if (!v.contains('@')) return 'Invalid email';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _phoneController,
                  decoration: const InputDecoration(
                    labelText: 'Phone Number',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.phone_outlined),
                  ),
                  keyboardType: TextInputType.phone,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Enter your phone';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.lock_outlined),
                    suffixIcon: IconButton(
                      icon: Icon(_obscurePassword
                          ? Icons.visibility_off
                          : Icons.visibility),
                      onPressed: () =>
                          setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                  obscureText: _obscurePassword,
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Enter a password';
                    if (v.length < 6) return 'At least 6 characters';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _confirmPasswordController,
                  decoration: const InputDecoration(
                    labelText: 'Confirm Password',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.lock_outlined),
                  ),
                  obscureText: true,
                  validator: (v) {
                    if (v != _passwordController.text) return 'Passwords do not match';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _role,
                  decoration: const InputDecoration(
                    labelText: 'I am a...',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.badge_outlined),
                  ),
                  items: const [
                    DropdownMenuItem(
                        value: 'landlord',
                        child: Text('Landlord / Property Manager')),
                    DropdownMenuItem(
                        value: 'owner', child: Text('Property Owner')),
                    DropdownMenuItem(
                        value: 'tenant', child: Text('Tenant / Renter')),
                    DropdownMenuItem(
                        value: 'caretaker', child: Text('Caretaker')),
                  ],
                  onChanged: (v) {
                    setState(() {
                      _role = v!;
                      _selectedOwnerId = null;
                    });
                  },
                ),
                if (_role == 'owner' || _role == 'tenant') ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline,
                            size: 20, color: colorScheme.primary),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _role == 'owner'
                                ? 'An owner profile will be created automatically for you in our cloud database.'
                                : 'A tenant profile will be created automatically for you in our cloud database.',
                            style: TextStyle(
                                fontSize: 13, color: colorScheme.primary),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                if (_role == 'landlord' || _role == 'caretaker') ...[
                  const SizedBox(height: 16),
                  FutureBuilder(
                    future: _loadOwners(),
                    builder: (context, _) => DropdownButtonFormField<int>(
                      value: _selectedOwnerId,
                      decoration: const InputDecoration(
                        labelText: 'Work for which Owner?',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                      hint: const Text('Select an owner (optional)'),
                      items: [
                        const DropdownMenuItem(
                            value: null, child: Text('None (skip)')),
                        ..._owners.map((o) => DropdownMenuItem(
                            value: o['id'] as int,
                            child: Text(o['name'] as String))),
                      ],
                      onChanged: (v) =>
                          setState(() => _selectedOwnerId = v),
                    ),
                  ),
                ],
                if (authProvider.error != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    authProvider.error!,
                    style: TextStyle(color: Colors.red[700], fontSize: 13),
                  ),
                ],
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: FilledButton(
                    onPressed: authProvider.isLoading
                        ? null
                        : () => _register(authProvider),
                    child: authProvider.isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : const Text('Create Account',
                            style: TextStyle(fontSize: 16)),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Already have an account?'),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Sign In'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _register(AuthProvider provider) async {
    if (!_formKey.currentState!.validate()) return;
    final ok = await provider.register(
      _emailController.text.trim(),
      _passwordController.text,
      _nameController.text.trim(),
      _role,
      phone: _phoneController.text.trim(),
      ownerId: _selectedOwnerId,
    );
    if (ok && mounted) {
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }
}
