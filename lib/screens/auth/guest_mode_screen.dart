import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../database/database_helper.dart';

class GuestModeScreen extends StatefulWidget {
  const GuestModeScreen({super.key});

  @override
  State<GuestModeScreen> createState() => _GuestModeScreenState();
}

class _GuestModeScreenState extends State<GuestModeScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final db = DatabaseHelper.instance;

  List<Map<String, dynamic>> _vacantProperties = [];
  List<Map<String, dynamic>> _lookingForHelp = [];
  List<Map<String, dynamic>> _forSale = [];
  List<Map<String, dynamic>> _underConstruction = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);

    final allProperties = await db.queryAll('properties');
    final allUnits = await db.queryAll('units');
    final allOwners = await db.queryAll('owners');

    final ownerMap = {for (final o in allOwners) o['id'] as int: o['name'] as String};

    final propertyOwnerMap = <int, String>{};
    for (final p in allProperties) {
      final oid = p['owner_id'] as int?;
      if (oid != null && ownerMap.containsKey(oid)) {
        propertyOwnerMap[p['id'] as int] = ownerMap[oid]!;
      }
    }

    _vacantProperties = allProperties.where((p) {
      final propUnits = allUnits.where((u) => u['property_id'] == p['id']);
      return propUnits.any((u) => u['is_occupied'] == 0);
    }).map((p) {
      final pid = p['id'] as int;
      final vacant = allUnits.where((u) => u['property_id'] == pid && u['is_occupied'] == 0).toList();
      return {
        ...p,
        'owner_name': propertyOwnerMap[pid] ?? 'Unknown',
        'vacant_count': vacant.length,
        'vacant_units': vacant,
      };
    }).toList();

    final status = <String, List<Map<String, dynamic>>>{
      'for_sale': [],
      'under_construction': [],
    };

    for (final p in allProperties) {
      final s = p['status'] as String? ?? 'rental';
      final pid = p['id'] as int;
      final entry = {
        ...p,
        'owner_name': propertyOwnerMap[pid] ?? 'Unknown',
      };
      if (s == 'for_sale') status['for_sale']!.add(entry);
      if (s == 'under_construction') status['under_construction']!.add(entry);
    }

    _forSale = status['for_sale']!;
    _underConstruction = status['under_construction']!;

    _lookingForHelp = allOwners.where((o) {
      final lf = o['looking_for'] as String? ?? '';
      return lf.isNotEmpty;
    }).map((o) {
      final oid = o['id'] as int;
      final props = allProperties.where((p) => p['owner_id'] == oid).toList();
      return {
        ...o,
        'looking_for': o['looking_for'] as String? ?? '',
        'property_count': props.length,
        'properties': props,
      };
    }).toList();

    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Browse Listings'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: false,
          tabs: const [
            Tab(icon: Icon(Icons.home_outlined), text: 'Vacant'),
            Tab(icon: Icon(Icons.person_search_outlined), text: 'Help Wanted'),
            Tab(icon: Icon(Icons.sell_outlined), text: 'For Sale'),
            Tab(icon: Icon(Icons.construction_outlined), text: 'Building'),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildVacantTab(colorScheme),
                _buildHelpWantedTab(colorScheme),
                _buildForSaleTab(colorScheme),
                _buildConstructionTab(colorScheme),
              ],
            ),
    );
  }

  Widget _buildVacantTab(ColorScheme colors) {
    if (_vacantProperties.isEmpty) {
      return _emptyState('No vacant units available', Icons.home_outlined);
    }
    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _vacantProperties.length,
        itemBuilder: (_, i) => _buildVacantCard(_vacantProperties[i], colors),
      ),
    );
  }

  Widget _buildVacantCard(Map<String, dynamic> prop, ColorScheme colors) {
    final fmt = NumberFormat.currency(symbol: '\$');
    final units = prop['vacant_units'] as List;
    final lowestRent = units.isEmpty
        ? 0.0
        : (units.map((u) => (u['rent_amount'] as num?)?.toDouble() ?? 0)
            .reduce((a, b) => a < b ? a : b));

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text('${prop['vacant_count']} Vacant',
                      style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.green)),
                ),
                const Spacer(),
                Text(prop['type'] as String? ?? '',
                    style: const TextStyle(fontSize: 11, color: Colors.grey)),
              ],
            ),
            const SizedBox(height: 8),
            Text(prop['name'] as String? ?? '',
                style: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 4),
            Text('${prop['city']}, ${prop['state']}',
                style: const TextStyle(color: Colors.grey, fontSize: 13)),
            const SizedBox(height: 4),
            Text('Owner: ${prop['owner_name']}',
                style: const TextStyle(fontSize: 12)),
            if (lowestRent > 0) ...[
              const SizedBox(height: 4),
              Text('From $fmt$lowestRent /mo',
                  style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: colors.primary)),
            ],
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: units.map((u) => Chip(
                visualDensity: VisualDensity.compact,
                label: Text(
                  'Unit ${u['unit_number']}',
                  style: const TextStyle(fontSize: 10),
                ),
                backgroundColor: colors.surfaceVariant,
              )).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHelpWantedTab(ColorScheme colors) {
    if (_lookingForHelp.isEmpty) {
      return _emptyState(
          'No owners looking for help yet', Icons.person_search_outlined);
    }
    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _lookingForHelp.length,
        itemBuilder: (_, i) => _buildHelpCard(_lookingForHelp[i], colors),
      ),
    );
  }

  Widget _buildHelpCard(Map<String, dynamic> owner, ColorScheme colors) {
    final lookingFor = owner['looking_for'] as String? ?? '';
    final labels = lookingFor.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: colors.secondary,
                  child: Text(
                    (owner['name'] as String? ?? 'O')[0].toUpperCase(),
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(owner['name'] as String? ?? '',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16)),
                      Text('${owner['property_count']} properties',
                          style: const TextStyle(fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: labels.map((l) => Chip(
                visualDensity: VisualDensity.compact,
                avatar: Icon(
                  l == 'landlord'
                      ? Icons.admin_panel_settings
                      : Icons.engineering,
                  size: 16,
                ),
                label: Text(
                  l == 'landlord' ? 'Looking for Landlord' : 'Looking for Caretaker',
                  style: const TextStyle(fontSize: 11),
                ),
                backgroundColor: Colors.amber.withValues(alpha: 0.1),
              )).toList(),
            ),
            if (owner['email'] != null && (owner['email'] as String).isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.email_outlined, size: 14, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(owner['email'] as String? ?? '',
                      style: const TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildForSaleTab(ColorScheme colors) {
    if (_forSale.isEmpty) {
      return _emptyState('No properties for sale', Icons.sell_outlined);
    }
    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _forSale.length,
        itemBuilder: (_, i) => _buildListedCard(_forSale[i], colors, 'For Sale', Colors.blue),
      ),
    );
  }

  Widget _buildConstructionTab(ColorScheme colors) {
    if (_underConstruction.isEmpty) {
      return _emptyState('No projects under construction', Icons.construction_outlined);
    }
    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _underConstruction.length,
        itemBuilder: (_, i) =>
            _buildListedCard(_underConstruction[i], colors, 'Under Construction', Colors.orange),
      ),
    );
  }

  Widget _buildListedCard(
      Map<String, dynamic> prop, ColorScheme colors, String label, Color color) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(label,
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: color)),
                ),
                const Spacer(),
                Text(prop['type'] as String? ?? '',
                    style: const TextStyle(fontSize: 11, color: Colors.grey)),
              ],
            ),
            const SizedBox(height: 8),
            Text(prop['name'] as String? ?? '',
                style: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 4),
            Text('${prop['city']}, ${prop['state']}',
                style: const TextStyle(color: Colors.grey, fontSize: 13)),
            const SizedBox(height: 4),
            Text('Owner: ${prop['owner_name']}',
                style: const TextStyle(fontSize: 12)),
            if (prop['notes'] != null && (prop['notes'] as String).isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(prop['notes'] as String,
                  style: const TextStyle(fontSize: 12),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis),
            ],
          ],
        ),
      ),
    );
  }

  Widget _emptyState(String message, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(message, style: TextStyle(color: Colors.grey[600], fontSize: 16)),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: _loadData,
            icon: const Icon(Icons.refresh),
            label: const Text('Refresh'),
          ),
        ],
      ),
    );
  }
}
