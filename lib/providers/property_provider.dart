import 'package:flutter/foundation.dart';
import '../database/database_helper.dart';
import '../models/property.dart';
import '../models/unit.dart';

class PropertyProvider extends ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper.instance;
  List<Property> _properties = [];
  List<Unit> _units = [];
  Map<int, String> _ownerNames = {};
  bool _isLoading = false;

  List<Property> get properties => _properties;
  List<Unit> get units => _units;
  Map<int, String> get ownerNames => _ownerNames;
  bool get isLoading => _isLoading;

  Future<void> loadProperties() async {
    _isLoading = true;
    notifyListeners();
    final maps = await _db.queryAll('properties');
    _properties = maps.map((m) => Property.fromMap(m)).toList();
    await _loadOwnerNames();
    _isLoading = false;
    notifyListeners();
  }

  Future<void> _loadOwnerNames() async {
    _ownerNames = {};
    final ownerMaps = await _db.queryAll('owners');
    for (final m in ownerMaps) {
      _ownerNames[m['id'] as int] = m['name'] as String;
    }
  }

  Future<void> loadUnitsByProperty(int propertyId) async {
    final maps = await _db.getUnitsByProperty(propertyId);
    _units = maps.map((m) => Unit.fromMap(m)).toList();
    notifyListeners();
  }

  Future<int> addProperty(Property property) async {
    final id = await _db.insert('properties', property.toMap());
    await loadProperties();
    return id;
  }

  Future<void> updateProperty(Property property) async {
    await _db.update('properties', property.toMap(), property.id!);
    await loadProperties();
  }

  Future<void> deleteProperty(int id) async {
    await _db.delete('properties', id);
    await loadProperties();
  }

  Future<void> addUnit(Unit unit) async {
    await _db.insert('units', unit.toMap());
    await loadUnitsByProperty(unit.propertyId);
  }

  Future<void> updateUnit(Unit unit) async {
    await _db.update('units', unit.toMap(), unit.id!);
    await loadUnitsByProperty(unit.propertyId);
  }

  Future<void> deleteUnit(int id, int propertyId) async {
    await _db.delete('units', id);
    await loadUnitsByProperty(propertyId);
  }

  Future<List<Property>> searchProperties(String query) async {
    final maps = await _db.searchProperties(query);
    return maps.map((m) => Property.fromMap(m)).toList();
  }

  Property? getPropertyById(int id) {
    try {
      return _properties.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  String getOwnerName(int ownerId) {
    return _ownerNames[ownerId] ?? 'Unknown Owner';
  }

  int getOccupiedUnits(int propertyId) {
    return _units.where((u) => u.isOccupied).length;
  }
}
