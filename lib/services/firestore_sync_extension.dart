import '../database/database_helper.dart';
import 'firestore_service.dart';

extension DataSyncExtension on FirestoreService {
  Future<void> syncAllFromSqlite() async {
    final sqlite = DatabaseHelper.instance;

    final properties = await sqlite.queryAll('properties');
    final units = await sqlite.queryAll('units');
    final owners = await sqlite.queryAll('owners');
    final tenants = await sqlite.queryAll('tenants');
    final leases = await sqlite.queryAll('leases');
    final maintenance = await sqlite.queryAll('maintenance_requests');

    final ownerMap = <int, String>{};
    final propertyMap = <int, String>{};
    final unitMap = <int, String>{};
    final tenantMap = <int, String>{};

    for (final o in owners) {
      final oid = o['id'] as int;
      final ref = await db.collection('owners').add({
        'name': o['name'] as String? ?? '',
        'email': o['email'] as String? ?? '',
        'phone': o['phone'] as String? ?? '',
        'address': o['address'] as String? ?? '',
        'notes': o['notes'] as String? ?? '',
        'looking_for': o['looking_for'] as String? ?? '',
        'migratedFromSqlite': true,
        'oldId': oid,
      });
      ownerMap[oid] = ref.id;
    }

    for (final p in properties) {
      final pid = p['id'] as int;
      final ownerId = p['owner_id'] as int?;
      final ref = await propertiesRef.add({
        'name': p['name'] as String? ?? '',
        'location': '${p['city'] ?? ''}, ${p['state'] ?? ''}',
        'ownerId': ownerId != null ? (ownerMap[ownerId] ?? '') : '',
        'landlordId': '',
        'images': [],
        'status': p['status'] as String? ?? 'rental',
        'type': p['type'] as String? ?? 'Residential',
        'notes': p['notes'] as String? ?? '',
        'migratedFromSqlite': true,
        'oldId': pid,
      });
      propertyMap[pid] = ref.id;
    }

    for (final u in units) {
      final uidVal = u['id'] as int;
      final propId = u['property_id'] as int?;
      final ref = await unitsRef.add({
        'propertyId': propId != null ? (propertyMap[propId] ?? '') : '',
        'unitNumber': u['unit_number'] as String? ?? '',
        'rentAmount': (u['rent_amount'] as num?)?.toDouble() ?? 0,
        'caretakerId': '',
        'status': (u['is_occupied'] as int?) == 1 ? 'occupied' : 'vacant',
        'location': '',
        'description': u['notes'] as String? ?? '',
        'migratedFromSqlite': true,
        'oldId': uidVal,
      });
      unitMap[uidVal] = ref.id;
    }

    for (final t in tenants) {
      final tid = t['id'] as int;
      final ref = await db.collection('tenants').add({
        'name': t['name'] as String? ?? '',
        'phone': t['phone'] as String? ?? '',
        'email': t['email'] as String? ?? '',
        'migratedFromSqlite': true,
        'oldId': tid,
      });
      tenantMap[tid] = ref.id;
    }

    for (final l in leases) {
      final unitId = l['unit_id'] as int?;
      final tenantId = l['tenant_id'] as int?;
      await leasesRef.add({
        'unitId': unitId != null ? (unitMap[unitId] ?? '') : '',
        'tenantId': tenantId != null ? (tenantMap[tenantId] ?? '') : '',
        'rentAmount': (l['rent_amount'] as num?)?.toDouble() ?? 0,
        'deposit': (l['security_deposit'] as num?)?.toDouble() ?? 0,
        'startDate': l['start_date'] as String? ?? '',
        'endDate': l['end_date'] as String? ?? '',
        'isActive': (l['is_active'] as int?) == 1,
        'notes': l['notes'] as String? ?? '',
        'migratedFromSqlite': true,
      });
    }

    for (final m in maintenance) {
      final unitId = m['unit_id'] as int?;
      final tenantId = m['tenant_id'] as int?;
      await maintenanceRef.add({
        'unitId': unitId != null ? (unitMap[unitId] ?? '') : '',
        'tenantId': tenantId != null ? (tenantMap[tenantId] ?? '') : '',
        'issue': m['title'] as String? ?? m['description'] as String? ?? '',
        'status': _mapMaintenanceStatus(m['status'] as String? ?? ''),
        'createdAt': m['created_at'] as String? ?? '',
        'migratedFromSqlite': true,
      });
    }
  }

  String _mapMaintenanceStatus(String old) {
    switch (old.toLowerCase()) {
      case 'pending': return 'open';
      case 'in progress':
      case 'in_progress':
      case 'ongoing': return 'in_progress';
      case 'resolved':
      case 'completed': return 'resolved';
      default: return 'open';
    }
  }
}
