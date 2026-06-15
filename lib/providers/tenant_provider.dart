import 'package:flutter/foundation.dart';
import '../database/database_helper.dart';
import '../models/tenant.dart';

class TenantProvider extends ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper.instance;
  List<Tenant> _tenants = [];
  bool _isLoading = false;

  List<Tenant> get tenants => _tenants;
  bool get isLoading => _isLoading;

  Future<void> loadTenants() async {
    _isLoading = true;
    notifyListeners();
    final maps = await _db.queryAll('tenants');
    _tenants = maps.map((m) => Tenant.fromMap(m)).toList();
    _isLoading = false;
    notifyListeners();
  }

  Future<int> addTenant(Tenant tenant) async {
    final id = await _db.insert('tenants', tenant.toMap());
    await loadTenants();
    return id;
  }

  Future<void> updateTenant(Tenant tenant) async {
    await _db.update('tenants', tenant.toMap(), tenant.id!);
    await loadTenants();
  }

  Future<void> deleteTenant(int id) async {
    await _db.delete('tenants', id);
    await loadTenants();
  }

  Future<List<Tenant>> searchTenants(String query) async {
    final maps = await _db.searchTenants(query);
    return maps.map((m) => Tenant.fromMap(m)).toList();
  }

  Tenant? getTenantById(int id) {
    try {
      return _tenants.firstWhere((t) => t.id == id);
    } catch (_) {
      return null;
    }
  }
}
