import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../database/database_helper.dart';
import '../models/property.dart';
import '../models/unit.dart';
import '../services/firestore_service.dart';

class PropertyProvider extends ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper.instance;
  final FirestoreService _firestore = FirestoreService.instance;
  List<Property> _properties = [];
  List<Unit> _units = [];
  Map<int, String> _ownerNames = {};
  bool _isLoading = false;

  List<Property> get properties => _properties;
  List<Unit> get units => _units;
  Map<int, String> get ownerNames => _ownerNames;
  bool get isLoading => _isLoading;

  Stream<QuerySnapshot> get propertiesStream => _firestore.propertiesStream();
  Stream<QuerySnapshot> get allUnitsStream => _firestore.allUnitsStream();

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
    try {
      await _firestore.addProperty({
        ...property.toFirestoreMap(),
        'oldPropertyId': id,
      });
    } catch (e) {
      debugPrint('Firestore addProperty error: $e');
    }
    await loadProperties();
    return id;
  }

  Future<void> updateProperty(Property property) async {
    await _db.update('properties', property.toMap(), property.id!);
    try {
      final docs = await _firestore.propertiesRef
          .where('oldPropertyId', isEqualTo: property.id)
          .get();
      for (final d in docs.docs) {
        await _firestore.updateProperty(d.id, property.toFirestoreMap());
      }
    } catch (e) {
      debugPrint('Firestore updateProperty error: $e');
    }
    await loadProperties();
  }

  Future<void> deleteProperty(int id) async {
    await _db.delete('properties', id);
    try {
      final docs = await _firestore.propertiesRef
          .where('oldPropertyId', isEqualTo: id)
          .get();
      for (final d in docs.docs) {
        await _firestore.deleteProperty(d.id);
      }
    } catch (e) {
      debugPrint('Firestore deleteProperty error: $e');
    }
    await loadProperties();
  }

  Future<void> addUnit(Unit unit) async {
    final id = await _db.insert('units', unit.toMap());
    try {
      await _firestore.addUnit({
        ...unit.toFirestoreMap(),
        'oldUnitId': id,
      });
    } catch (e) {
      debugPrint('Firestore addUnit error: $e');
    }
    await loadUnitsByProperty(unit.propertyId);
  }

  Future<void> updateUnit(Unit unit) async {
    await _db.update('units', unit.toMap(), unit.id!);
    try {
      final docs = await _firestore.unitsRef
          .where('oldUnitId', isEqualTo: unit.id)
          .get();
      for (final d in docs.docs) {
        await _firestore.unitsRef.doc(d.id).update(unit.toFirestoreMap());
      }
    } catch (e) {
      debugPrint('Firestore updateUnit error: $e');
    }
    await loadUnitsByProperty(unit.propertyId);
  }

  Future<void> deleteUnit(int id, int propertyId) async {
    await _db.delete('units', id);
    try {
      final docs = await _firestore.unitsRef
          .where('oldUnitId', isEqualTo: id)
          .get();
      for (final d in docs.docs) {
        await _firestore.unitsRef.doc(d.id).delete();
      }
    } catch (e) {
      debugPrint('Firestore deleteUnit error: $e');
    }
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
