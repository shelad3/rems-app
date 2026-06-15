import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../database/database_helper.dart';
import '../models/maintenance_request.dart';
import '../services/firestore_service.dart';

class MaintenanceProvider extends ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper.instance;
  final FirestoreService _firestore = FirestoreService.instance;
  List<MaintenanceRequest> _requests = [];
  bool _isLoading = false;

  List<MaintenanceRequest> get requests => _requests;
  bool get isLoading => _isLoading;

  Stream<QuerySnapshot> get maintenanceStream =>
      _firestore.maintenanceRef.snapshots();

  Future<void> loadRequests() async {
    _isLoading = true;
    notifyListeners();
    final maps = await _db.queryAll('maintenance_requests');
    _requests = maps.map((m) => MaintenanceRequest.fromMap(m)).toList();
    _isLoading = false;
    notifyListeners();
  }

  Future<int> addRequest(MaintenanceRequest request) async {
    final id = await _db.insert('maintenance_requests', request.toMap());
    try {
      await _firestore.addMaintenanceTicket({
        ...request.toFirestoreMap(),
        'oldRequestId': id,
      });
    } catch (e) {
      debugPrint('Firestore addMaintenance error: $e');
    }
    await loadRequests();
    return id;
  }

  Future<void> updateRequest(MaintenanceRequest request) async {
    await _db.update('maintenance_requests', request.toMap(), request.id!);
    try {
      final docs = await _firestore.maintenanceRef
          .where('oldRequestId', isEqualTo: request.id)
          .get();
      for (final d in docs.docs) {
        await _firestore.updateMaintenanceTicket(
            d.id, request.toFirestoreMap());
      }
    } catch (e) {
      debugPrint('Firestore updateMaintenance error: $e');
    }
    await loadRequests();
  }

  Future<void> deleteRequest(int id) async {
    await _db.delete('maintenance_requests', id);
    try {
      final docs = await _firestore.maintenanceRef
          .where('oldRequestId', isEqualTo: id)
          .get();
      for (final d in docs.docs) {
        await d.reference.delete();
      }
    } catch (e) {
      debugPrint('Firestore deleteMaintenance error: $e');
    }
    await loadRequests();
  }

  List<MaintenanceRequest> getRequestsByUnit(int unitId) {
    return _requests.where((r) => r.unitId == unitId).toList();
  }

  List<MaintenanceRequest> getRequestsByTenant(int tenantId) {
    return _requests.where((r) => r.tenantId == tenantId).toList();
  }

  List<MaintenanceRequest> getPendingRequests() {
    return _requests.where((r) => r.status != 'Completed').toList();
  }

  List<MaintenanceRequest> getRequestsByPriority(String priority) {
    return _requests.where((r) => r.priority == priority).toList();
  }

  Future<List<Map<String, dynamic>>>
      getRequestsByProperty(int propertyId) async {
    return await _db.getMaintenanceRequestsByProperty(propertyId);
  }
}
