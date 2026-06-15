import 'package:flutter/foundation.dart';
import '../database/database_helper.dart';
import '../models/owner.dart';

class OwnerProvider extends ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper.instance;
  List<Owner> _owners = [];
  bool _isLoading = false;

  List<Owner> get owners => _owners;
  bool get isLoading => _isLoading;

  Future<void> loadOwners() async {
    _isLoading = true;
    notifyListeners();
    final maps = await _db.queryAll('owners');
    _owners = maps.map((m) => Owner.fromMap(m)).toList();
    _isLoading = false;
    notifyListeners();
  }

  Future<int> addOwner(Owner owner) async {
    final id = await _db.insert('owners', owner.toMap());
    await loadOwners();
    return id;
  }

  Future<void> updateOwner(Owner owner) async {
    await _db.update('owners', owner.toMap(), owner.id!);
    await loadOwners();
  }

  Future<void> deleteOwner(int id) async {
    await _db.delete('owners', id);
    await loadOwners();
  }

  Owner? getOwnerById(int id) {
    try {
      return _owners.firstWhere((o) => o.id == id);
    } catch (_) {
      return null;
    }
  }
}
