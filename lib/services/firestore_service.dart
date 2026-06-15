import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  static final FirestoreService instance = FirestoreService._();
  FirestoreService._();

  final FirebaseFirestore db = FirebaseFirestore.instance;

  // ─── Users ───────────────────────────────────────────────
  CollectionReference get usersRef => db.collection('users');

  Future<void> upsertUser(String uid, Map<String, dynamic> data) =>
      usersRef.doc(uid).set(data, SetOptions(merge: true));

  Future<Map<String, dynamic>?> getUser(String uid) async {
    final doc = await usersRef.doc(uid).get();
    if (!doc.exists) return null;
    return doc.data() as Map<String, dynamic>?;
  }

  Stream<DocumentSnapshot> userStream(String uid) => usersRef.doc(uid).snapshots();

  Future<void> updateUser(String uid, Map<String, dynamic> data) =>
      usersRef.doc(uid).update(data);

  // ─── Properties ──────────────────────────────────────────
  CollectionReference get propertiesRef => db.collection('properties');

  Future<String> addProperty(Map<String, dynamic> data) =>
      propertiesRef.add(data).then((ref) => ref.id);

  Future<void> updateProperty(String id, Map<String, dynamic> data) =>
      propertiesRef.doc(id).update(data);

  Future<void> deleteProperty(String id) => propertiesRef.doc(id).delete();

  Stream<QuerySnapshot> propertiesStream() => propertiesRef.snapshots();

  Stream<QuerySnapshot> propertiesByOwnerStream(String ownerId) =>
      propertiesRef.where('ownerId', isEqualTo: ownerId).snapshots();

  Future<Map<String, dynamic>?> getProperty(String id) async {
    final doc = await propertiesRef.doc(id).get();
    if (!doc.exists) return null;
    return doc.data() as Map<String, dynamic>?;
  }

  // ─── Units ───────────────────────────────────────────────
  CollectionReference get unitsRef => db.collection('units');

  Future<String> addUnit(Map<String, dynamic> data) =>
      unitsRef.add(data).then((ref) => ref.id);

  Future<void> updateUnit(String id, Map<String, dynamic> data) =>
      unitsRef.doc(id).update(data);

  Stream<QuerySnapshot> unitsByPropertyStream(String propertyId) =>
      unitsRef.where('propertyId', isEqualTo: propertyId).snapshots();

  Stream<QuerySnapshot> vacantUnitsStream() =>
      unitsRef.where('status', isEqualTo: 'vacant').snapshots();

  Stream<QuerySnapshot> unitsByCaretakerStream(String caretakerId) =>
      unitsRef.where('caretakerId', isEqualTo: caretakerId).snapshots();

  Stream<QuerySnapshot> allUnitsStream() => unitsRef.snapshots();

  Future<Map<String, dynamic>?> getUnit(String id) async {
    final doc = await unitsRef.doc(id).get();
    if (!doc.exists) return null;
    return doc.data() as Map<String, dynamic>?;
  }

  // ─── Applications ────────────────────────────────────────
  CollectionReference get applicationsRef => db.collection('applications');

  Future<String> addApplication(Map<String, dynamic> data) =>
      applicationsRef.add(data).then((ref) => ref.id);

  Future<void> updateApplication(String id, Map<String, dynamic> data) =>
      applicationsRef.doc(id).update(data);

  Stream<QuerySnapshot> pendingApplicationsStream(String caretakerId) =>
      applicationsRef
          .where('caretakerId', isEqualTo: caretakerId)
          .where('status', isEqualTo: 'pending')
          .orderBy('createdAt', descending: true)
          .snapshots();

  Stream<QuerySnapshot> pendingAndCounteredStream(String caretakerId) =>
      applicationsRef
          .where('caretakerId', isEqualTo: caretakerId)
          .where(Filter.or(
            Filter('status', isEqualTo: 'pending'),
            Filter('status', isEqualTo: 'countered'),
          ))
          .orderBy('createdAt', descending: true)
          .snapshots();

  Stream<QuerySnapshot> tenantApplicationsStream(String tenantId) =>
      applicationsRef
          .where('tenantId', isEqualTo: tenantId)
          .orderBy('createdAt', descending: true)
          .snapshots();

  // ─── Maintenance ─────────────────────────────────────────
  CollectionReference get maintenanceRef => db.collection('maintenance');

  Future<String> addMaintenanceTicket(Map<String, dynamic> data) =>
      maintenanceRef.add(data).then((ref) => ref.id);

  Future<void> updateMaintenanceTicket(String id, Map<String, dynamic> data) =>
      maintenanceRef.doc(id).update(data);

  Stream<QuerySnapshot> maintenanceByCaretakerStream(String caretakerId) =>
      maintenanceRef
          .where('caretakerId', isEqualTo: caretakerId)
          .orderBy('createdAt', descending: true)
          .snapshots();

  Stream<QuerySnapshot> tenantMaintenanceStream(String tenantId) =>
      maintenanceRef
          .where('tenantId', isEqualTo: tenantId)
          .orderBy('createdAt', descending: true)
          .snapshots();

  Stream<QuerySnapshot> allMaintenanceStream() =>
      maintenanceRef.orderBy('createdAt', descending: true).snapshots();

  // ─── Leases ──────────────────────────────────────────────
  CollectionReference get leasesRef => db.collection('leases');

  Future<String> addLease(Map<String, dynamic> data) =>
      leasesRef.add(data).then((ref) => ref.id);

  Future<void> updateLease(String id, Map<String, dynamic> data) =>
      leasesRef.doc(id).update(data);

  Stream<QuerySnapshot> activeLeasesStream() =>
      leasesRef.where('isActive', isEqualTo: true).snapshots();

  Stream<DocumentSnapshot> tenantLeaseStream(String tenantId) =>
      leasesRef.doc(tenantId).snapshots();

  Future<Map<String, dynamic>?> getLeaseByTenant(String tenantId) async {
    final snaps = await leasesRef
        .where('tenantId', isEqualTo: tenantId)
        .where('isActive', isEqualTo: true)
        .limit(1)
        .get();
    if (snaps.docs.isEmpty) return null;
    return snaps.docs.first.data() as Map<String, dynamic>?;
  }
}
