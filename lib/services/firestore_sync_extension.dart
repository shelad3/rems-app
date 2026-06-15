import 'package:flutter/foundation.dart';
import '../database/database_helper.dart';
import 'firestore_service.dart';

extension DataSyncExtension on FirestoreService {
  /// Uploads ALL local SQLite records to Firestore using [oldId] as the doc ID.
  /// Idempotent: same record always maps to the same Firestore doc.
  Future<void> syncAllFromSqlite() async {
    final sqlite = DatabaseHelper.instance;

    final properties = await sqlite.queryAll('properties');
    final units = await sqlite.queryAll('units');
    final owners = await sqlite.queryAll('owners');
    final tenants = await sqlite.queryAll('tenants');
    final leases = await sqlite.queryAll('leases');
    final maintenance = await sqlite.queryAll('maintenance_requests');

    for (final o in owners) {
      final oid = o['id'] as int;
      await db.collection('owners').doc(oid.toString()).set({
        'name': o['name'] as String? ?? '',
        'email': o['email'] as String? ?? '',
        'phone': o['phone'] as String? ?? '',
        'address': o['address'] as String? ?? '',
        'notes': o['notes'] as String? ?? '',
        'lookingFor': o['looking_for'] as String? ?? '',
        'oldOwnerId': oid,
        'createdAt': o['created_at'] as String? ?? DateTime.now().toIso8601String(),
      });
    }

    for (final p in properties) {
      final pid = p['id'] as int;
      final ownerId = p['owner_id'] as int?;
      await propertiesRef.doc(pid.toString()).set({
        'name': p['name'] as String? ?? '',
        'location': '${p['city'] ?? ''}, ${p['state'] ?? ''}',
        'ownerId': ownerId?.toString() ?? '',
        'landlordId': '',
        'images': <String>[],
        'status': p['status'] as String? ?? 'rental',
        'type': p['type'] as String? ?? 'Residential',
        'notes': p['notes'] as String? ?? '',
        'oldPropertyId': pid,
        'createdAt': p['created_at'] as String? ?? DateTime.now().toIso8601String(),
      });
    }

    for (final u in units) {
      final uidVal = u['id'] as int;
      final propId = u['property_id'] as int?;
      await unitsRef.doc(uidVal.toString()).set({
        'propertyId': propId?.toString() ?? '',
        'unitNumber': u['unit_number'] as String? ?? '',
        'rentAmount': (u['rent_amount'] as num?)?.toDouble() ?? 0,
        'caretakerId': '',
        'status': (u['is_occupied'] as int?) == 1 ? 'occupied' : 'vacant',
        'location': '',
        'description': u['notes'] as String? ?? '',
        'bedrooms': u['bedrooms'] as int? ?? 1,
        'bathrooms': u['bathrooms'] as int? ?? 1,
        'squareFeet': (u['square_feet'] as num?)?.toDouble() ?? 0,
        'securityDeposit': (u['security_deposit'] as num?)?.toDouble() ?? 0,
        'oldUnitId': uidVal,
        'createdAt': u['created_at'] as String? ?? DateTime.now().toIso8601String(),
      });
    }

    for (final t in tenants) {
      final tid = t['id'] as int;
      await db.collection('tenants').doc(tid.toString()).set({
        'name': t['name'] as String? ?? '',
        'phone': t['phone'] as String? ?? '',
        'email': t['email'] as String? ?? '',
        'emergencyContact': t['emergency_contact'] as String? ?? '',
        'emergencyPhone': t['emergency_phone'] as String? ?? '',
        'idNumber': t['id_number'] as String? ?? '',
        'notes': t['notes'] as String? ?? '',
        'oldTenantId': tid,
        'createdAt': t['created_at'] as String? ?? DateTime.now().toIso8601String(),
      });
    }

    for (final l in leases) {
      final lid = l['id'] as int;
      await leasesRef.doc(lid.toString()).set({
        'unitId': (l['unit_id'] as int?)?.toString() ?? '',
        'tenantId': (l['tenant_id'] as int?)?.toString() ?? '',
        'rentAmount': (l['rent_amount'] as num?)?.toDouble() ?? 0,
        'deposit': (l['security_deposit'] as num?)?.toDouble() ?? 0,
        'startDate': l['start_date'] as String? ?? '',
        'endDate': l['end_date'] as String? ?? '',
        'isActive': (l['is_active'] as int?) == 1,
        'notes': l['notes'] as String? ?? '',
        'oldLeaseId': lid,
        'createdAt': l['created_at'] as String? ?? DateTime.now().toIso8601String(),
      });
    }

    for (final m in maintenance) {
      final mid = m['id'] as int;
      await maintenanceRef.doc(mid.toString()).set({
        'unitId': (m['unit_id'] as int?)?.toString() ?? '',
        'tenantId': (m['tenant_id'] as int?)?.toString() ?? '',
        'issue': m['title'] as String? ?? m['description'] as String? ?? '',
        'description': m['description'] as String? ?? '',
        'priority': m['priority'] as String? ?? 'Medium',
        'status': _mapMaintenanceStatus(m['status'] as String? ?? ''),
        'oldRequestId': mid,
        'createdAt': m['created_at'] as String? ?? DateTime.now().toIso8601String(),
      });
    }
  }

  Future<void> downloadFromFirestore() async {
    final sqlite = DatabaseHelper.instance;

    try {
      final ownersSnap = await db.collection('owners').get();
      for (final doc in ownersSnap.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final oldId = data['oldId'] as int? ?? data['oldOwnerId'] as int? ?? int.tryParse(doc.id);
        if (oldId == null) continue;
        final existing = await sqlite.queryById('owners', oldId);
        if (existing != null) continue;
        await sqlite.insert('owners', {
          'name': data['name'] as String? ?? '',
          'email': data['email'] as String? ?? '',
          'phone': data['phone'] as String? ?? '',
          'address': data['address'] as String? ?? '',
          'notes': data['notes'] as String? ?? '',
          'looking_for': data['lookingFor'] as String? ?? data['looking_for'] as String? ?? '',
          'created_at': data['createdAt'] as String? ?? DateTime.now().toIso8601String(),
        });
      }
    } catch (e) {
      debugPrint('Download owners error: $e');
    }

    try {
      final propsSnap = await propertiesRef.get();
      for (final doc in propsSnap.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final oldId = data['oldId'] as int? ?? data['oldPropertyId'] as int? ?? int.tryParse(doc.id);
        if (oldId == null) continue;
        final existing = await sqlite.queryById('properties', oldId);
        if (existing != null) continue;
        final location = (data['location'] as String? ?? '').split(', ');
        await sqlite.insert('properties', {
          'owner_id': 0,
          'name': data['name'] as String? ?? '',
          'address': location.isNotEmpty ? location[0] : '',
          'city': location.length > 1 ? location[1] : '',
          'state': location.length > 2 ? location[2] : '',
          'zip': '',
          'type': data['type'] as String? ?? 'Residential',
          'total_units': 0,
          'notes': data['notes'] as String? ?? '',
          'status': data['status'] as String? ?? 'rental',
          'created_at': data['createdAt'] as String? ?? DateTime.now().toIso8601String(),
        });
      }
    } catch (e) {
      debugPrint('Download properties error: $e');
    }

    try {
      final unitsSnap = await unitsRef.get();
      for (final doc in unitsSnap.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final oldId = data['oldId'] as int? ?? data['oldUnitId'] as int? ?? int.tryParse(doc.id);
        if (oldId == null) continue;
        final existing = await sqlite.queryById('units', oldId);
        if (existing != null) continue;
        await sqlite.insert('units', {
          'property_id': int.tryParse(data['propertyId'] as String? ?? '') ?? 0,
          'unit_number': data['unitNumber'] as String? ?? '',
          'bedrooms': data['bedrooms'] as int? ?? 1,
          'bathrooms': data['bathrooms'] as int? ?? 1,
          'square_feet': (data['squareFeet'] as num?)?.toDouble() ?? 0,
          'rent_amount': (data['rentAmount'] as num?)?.toDouble() ?? 0,
          'security_deposit': (data['securityDeposit'] as num?)?.toDouble() ?? 0,
          'is_occupied': data['status'] == 'occupied' ? 1 : 0,
          'notes': data['description'] as String? ?? '',
          'created_at': data['createdAt'] as String? ?? DateTime.now().toIso8601String(),
        });
      }
    } catch (e) {
      debugPrint('Download units error: $e');
    }

    try {
      final tenantsSnap = await db.collection('tenants').get();
      for (final doc in tenantsSnap.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final oldId = data['oldId'] as int? ?? data['oldTenantId'] as int? ?? int.tryParse(doc.id);
        if (oldId == null) continue;
        final existing = await sqlite.queryById('tenants', oldId);
        if (existing != null) continue;
        await sqlite.insert('tenants', {
          'name': data['name'] as String? ?? '',
          'email': data['email'] as String? ?? '',
          'phone': data['phone'] as String? ?? '',
          'emergency_contact': data['emergencyContact'] as String? ?? '',
          'emergency_phone': data['emergencyPhone'] as String? ?? '',
          'id_number': data['idNumber'] as String? ?? '',
          'notes': data['notes'] as String? ?? '',
          'created_at': data['createdAt'] as String? ?? DateTime.now().toIso8601String(),
        });
      }
    } catch (e) {
      debugPrint('Download tenants error: $e');
    }

    try {
      final leasesSnap = await leasesRef.get();
      for (final doc in leasesSnap.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final oldId = data['oldLeaseId'] as int? ?? int.tryParse(doc.id);
        if (oldId == null) continue;
        final existing = await sqlite.queryById('leases', oldId);
        if (existing != null) continue;
        await sqlite.insert('leases', {
          'unit_id': data['unitId'],
          'tenant_id': data['tenantId'],
          'start_date': data['startDate'] as String? ?? '',
          'end_date': data['endDate'] as String? ?? '',
          'rent_amount': (data['rentAmount'] as num?)?.toDouble() ?? 0,
          'security_deposit': (data['deposit'] as num?)?.toDouble() ?? 0,
          'is_active': data['isActive'] == true ? 1 : 0,
          'notes': data['notes'] as String? ?? '',
          'created_at': data['createdAt'] as String? ?? DateTime.now().toIso8601String(),
        });
      }
    } catch (e) {
      debugPrint('Download leases error: $e');
    }

    try {
      final maintSnap = await maintenanceRef.get();
      for (final doc in maintSnap.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final oldId = data['oldRequestId'] as int? ?? int.tryParse(doc.id);
        if (oldId == null) continue;
        final existing = await sqlite.queryById('maintenance_requests', oldId);
        if (existing != null) continue;
        await sqlite.insert('maintenance_requests', {
          'unit_id': data['unitId'],
          'tenant_id': data['tenantId'],
          'title': data['issue'] as String? ?? '',
          'description': data['description'] as String? ?? '',
          'priority': data['priority'] as String? ?? 'Medium',
          'status': _reverseMapMaintenanceStatus(data['status'] as String? ?? ''),
          'created_at': data['createdAt'] as String? ?? DateTime.now().toIso8601String(),
        });
      }
    } catch (e) {
      debugPrint('Download maintenance error: $e');
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

  String _reverseMapMaintenanceStatus(String firestoreStatus) {
    switch (firestoreStatus.toLowerCase()) {
      case 'open': return 'Pending';
      case 'in_progress':
      case 'ongoing': return 'In Progress';
      case 'resolved':
      case 'completed': return 'Resolved';
      default: return 'Pending';
    }
  }
}
