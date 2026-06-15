import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../providers/auth_provider.dart';
import '../../services/firestore_service.dart';

class UnitDetailScreen extends StatefulWidget {
  final String unitId;
  final Map<String, dynamic> unitData;

  const UnitDetailScreen({
    super.key,
    required this.unitId,
    required this.unitData,
  });

  @override
  State<UnitDetailScreen> createState() => _UnitDetailScreenState();
}

class _UnitDetailScreenState extends State<UnitDetailScreen> {
  final _firestore = FirestoreService.instance;
  final _fmt = NumberFormat.currency(symbol: 'KES ');
  bool _applying = false;
  bool _hasApplied = false;
  String? _propertyName;
  String? _ownerName;
  String? _landlordName;
  bool _loadingHierarchy = true;

  @override
  void initState() {
    super.initState();
    _checkExistingApplication();
    _loadHierarchy();
  }

  Future<void> _loadHierarchy() async {
    final propId = widget.unitData['propertyId'] as String?;
    if (propId == null || propId.isEmpty) {
      if (mounted) setState(() => _loadingHierarchy = false);
      return;
    }
    final prop = await _firestore.getProperty(propId);
    if (prop == null) {
      if (mounted) setState(() => _loadingHierarchy = false);
      return;
    }
    _propertyName = prop['name'] as String?;
    final ownerId = prop['ownerId'] as String?;
    final landlordId = prop['landlordId'] as String?;
    if (ownerId != null && ownerId.isNotEmpty) {
      final owner = await _firestore.getUser(ownerId);
      _ownerName = owner?['name'] as String?;
    }
    if (landlordId != null && landlordId.isNotEmpty) {
      final landlord = await _firestore.getUser(landlordId);
      _landlordName = landlord?['name'] as String?;
    }
    if (mounted) setState(() => _loadingHierarchy = false);
  }

  Future<void> _checkExistingApplication() async {
    final auth = context.read<AuthProvider>();
    if (auth.user?.uid == null) return;
    final apps = await _firestore.applicationsRef
        .where('unitId', isEqualTo: widget.unitId)
        .where('tenantId', isEqualTo: auth.user!.uid)
        .where('status', whereIn: ['pending', 'countered', 'accepted', 'approved'])
        .limit(1)
        .get();
    if (mounted) setState(() => _hasApplied = apps.docs.isNotEmpty);
  }

  Future<void> _apply() async {
    final auth = context.read<AuthProvider>();
    if (auth.user?.uid == null) return;

    final careId = widget.unitData['caretakerId'] as String? ?? '';
    final rent = (widget.unitData['rentAmount'] as num?)?.toDouble() ?? 0;
    setState(() => _applying = true);

    try {
      await _firestore.addApplication({
        'unitId': widget.unitId,
        'tenantId': auth.user!.uid,
        'tenantName': auth.user!.name,
        'caretakerId': careId,
        'status': 'pending',
        'proposedRent': rent,
        'proposedDeposit': rent * 0.5,
        'proposedDuration': '1 year',
        'createdAt': DateTime.now().toIso8601String(),
      });
      setState(() => _hasApplied = true);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Application submitted! Waiting for caretaker review.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }

    setState(() => _applying = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final data = widget.unitData;
    final rent = (data['rentAmount'] as num?)?.toDouble() ?? 0;

    return Scaffold(
      appBar: AppBar(title: Text('Unit ${data['unitNumber'] ?? ''}')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Container(
            height: 200,
            decoration: BoxDecoration(
              color: colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Icon(Icons.business, size: 80, color: colorScheme.primary),
            ),
          ),
          const SizedBox(height: 24),
          Text('Unit ${data['unitNumber'] ?? ''}',
              style: theme.textTheme.headlineSmall
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          if (_propertyName != null)
            Text(_propertyName!, style: TextStyle(fontSize: 14, color: Colors.grey[700])),
          if (_loadingHierarchy)
            const Padding(
              padding: EdgeInsets.only(top: 4),
              child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
            ),
          const SizedBox(height: 16),
          Row(
            children: [
              Icon(Icons.monetization_on, color: Colors.green),
              const SizedBox(width: 8),
              Text(_fmt.format(rent) + ' /mo',
                  style: const TextStyle(
                      fontSize: 24, fontWeight: FontWeight.bold, color: Colors.green)),
            ],
          ),
          const SizedBox(height: 8),
          Chip(
            avatar: Icon(Icons.check_circle, size: 16, color: Colors.green),
            label: const Text('Vacant', style: TextStyle(fontSize: 12)),
            backgroundColor: Colors.green.withValues(alpha: 0.1),
          ),
          const SizedBox(height: 24),
          // ─── Hierarchy ────────────────────────────────────
          if (_propertyName != null || _ownerName != null || _landlordName != null) ...[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Property Details',
                        style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    if (_propertyName != null)
                      _infoRow(Icons.domain, 'Building', _propertyName!),
                    if (_ownerName != null)
                      _infoRow(Icons.person, 'Owner', _ownerName!),
                    if (_landlordName != null)
                      _infoRow(Icons.manage_accounts, 'Manager', _landlordName!),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
          const Divider(),
          const SizedBox(height: 16),
          Text('About this unit',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(data['description'] as String? ?? 'No description provided.',
              style: const TextStyle(fontSize: 14, height: 1.5)),
          const SizedBox(height: 24),
          // ─── Apply Button ──────────────────────────────────
          SizedBox(
            width: double.infinity,
            height: 56,
            child: FilledButton.icon(
              onPressed: _hasApplied || _applying ? null : _apply,
              icon: _applying
                  ? const SizedBox(
                      width: 20, height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : Icon(_hasApplied ? Icons.check : Icons.send),
              label: Text(
                _hasApplied ? 'Application Submitted' : 'Apply for Lease',
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ),
          if (_hasApplied)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Card(
                color: Colors.blue.withValues(alpha: 0.05),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, size: 18, color: Colors.blue[700]),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Your application of ${_fmt.format(rent)}/mo has been sent to the property manager for review.',
                          style: TextStyle(fontSize: 12, color: Colors.blue[700]),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 8),
        SizedBox(width: 70, child: Text(label, style: TextStyle(fontSize: 13, color: Colors.grey[600]))),
        Expanded(child: Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500))),
      ]),
    );
  }
}
