import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../providers/auth_provider.dart';
import '../../services/firestore_service.dart';
import 'unit_detail_screen.dart';

class TenantDiscoveryScreen extends StatefulWidget {
  const TenantDiscoveryScreen({super.key});

  @override
  State<TenantDiscoveryScreen> createState() => _TenantDiscoveryScreenState();
}

class _TenantDiscoveryScreenState extends State<TenantDiscoveryScreen> {
  final _firestore = FirestoreService.instance;
  final _fmt = NumberFormat.currency(symbol: 'KES ');

  Future<Map<String, String?>> _getHierarchy(String? propId) async {
    if (propId == null || propId.isEmpty) return {};
    try {
      final prop = await _firestore.getProperty(propId);
      if (prop == null) return {};
      final ownerId = prop['ownerId'] as String?;
      final landlordId = prop['landlordId'] as String?;
      String? ownerName;
      String? landlordName;
      if (ownerId != null && ownerId.isNotEmpty) {
        final owner = await _firestore.getUser(ownerId);
        ownerName = owner?['name'] as String?;
      }
      if (landlordId != null && landlordId.isNotEmpty) {
        final landlord = await _firestore.getUser(landlordId);
        landlordName = landlord?['name'] as String?;
      }
      return {
        'propertyName': prop['name'] as String?,
        'ownerName': ownerName,
        'landlordName': landlordName,
      };
    } catch (_) {
      return {};
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Available Units')),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore.vacantUnitsStream(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final units = snapshot.data!.docs;

          if (units.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.home_outlined, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text('No vacant units available',
                      style: TextStyle(color: Colors.grey[600], fontSize: 16)),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {},
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: units.length,
              itemBuilder: (_, i) {
                final doc = units[i];
                final data = doc.data() as Map<String, dynamic>;
                return _UnitCard(
                  docId: doc.id,
                  data: data,
                  fmt: _fmt,
                  theme: theme,
                  getHierarchy: _getHierarchy,
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _UnitCard extends StatefulWidget {
  final String docId;
  final Map<String, dynamic> data;
  final NumberFormat fmt;
  final ThemeData theme;
  final Future<Map<String, String?>> Function(String?) getHierarchy;

  const _UnitCard({
    required this.docId,
    required this.data,
    required this.fmt,
    required this.theme,
    required this.getHierarchy,
  });

  @override
  State<_UnitCard> createState() => _UnitCardState();
}

class _UnitCardState extends State<_UnitCard> {
  String? _propertyName;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final h = await widget.getHierarchy(widget.data['propertyId'] as String?);
    if (mounted) setState(() {
      _propertyName = h['propertyName'];
      _loaded = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.data;
    final unitNum = data['unitNumber'] as String? ?? '';
    final location = data['location'] as String? ?? '';
    final rent = (data['rentAmount'] as num?)?.toDouble() ?? 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => UnitDetailScreen(unitId: widget.docId, unitData: data),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: widget.theme.colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.business, size: 36),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Unit $unitNum',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    if (_propertyName != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(_propertyName!,
                            style: const TextStyle(color: Colors.grey, fontSize: 12)),
                      ),
                    if (location.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(location,
                          style: const TextStyle(color: Colors.grey, fontSize: 12)),
                    ],
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text(widget.fmt.format(rent) + '/mo',
                            style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: widget.theme.colorScheme.primary,
                                fontSize: 15)),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.green.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text('Vacant',
                              style: TextStyle(fontSize: 11, color: Colors.green)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}
