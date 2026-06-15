import 'package:flutter/foundation.dart';
import '../database/database_helper.dart';
import '../models/lease.dart';

class LeaseProvider extends ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper.instance;
  List<Lease> _leases = [];
  List<Map<String, dynamic>> _activeLeases = [];
  bool _isLoading = false;

  List<Lease> get leases => _leases;
  List<Map<String, dynamic>> get activeLeases => _activeLeases;
  bool get isLoading => _isLoading;

  Future<void> loadLeases() async {
    _isLoading = true;
    notifyListeners();
    final maps = await _db.queryAll('leases');
    _leases = maps.map((m) => Lease.fromMap(m)).toList();
    _activeLeases = await _db.getActiveLeasesWithDetails();
    _isLoading = false;
    notifyListeners();
  }

  Future<int> addLease(Lease lease) async {
    final id = await _db.insert('leases', lease.toMap());
    await loadLeases();
    return id;
  }

  Future<void> updateLease(Lease lease) async {
    await _db.update('leases', lease.toMap(), lease.id!);
    await loadLeases();
  }

  Future<void> deleteLease(int id) async {
    await _db.delete('leases', id);
    await loadLeases();
  }

  List<Lease> getLeasesByTenant(int tenantId) {
    return _leases.where((l) => l.tenantId == tenantId).toList();
  }

  List<Lease> getLeasesByUnit(int unitId) {
    return _leases.where((l) => l.unitId == unitId).toList();
  }

  Lease? getActiveLeaseForUnit(int unitId) {
    try {
      return _leases.firstWhere(
          (l) => l.unitId == unitId && l.isActive);
    } catch (_) {
      return null;
    }
  }
}
