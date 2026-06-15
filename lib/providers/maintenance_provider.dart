import 'package:flutter/foundation.dart';
import '../database/database_helper.dart';
import '../models/maintenance_request.dart';

class MaintenanceProvider extends ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper.instance;
  List<MaintenanceRequest> _requests = [];
  bool _isLoading = false;

  List<MaintenanceRequest> get requests => _requests;
  bool get isLoading => _isLoading;

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
    await loadRequests();
    return id;
  }

  Future<void> updateRequest(MaintenanceRequest request) async {
    await _db.update('maintenance_requests', request.toMap(), request.id!);
    await loadRequests();
  }

  Future<void> deleteRequest(int id) async {
    await _db.delete('maintenance_requests', id);
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
