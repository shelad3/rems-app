import 'package:flutter/foundation.dart';
import '../database/database_helper.dart';
import '../models/inspection.dart';

class InspectionProvider extends ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper.instance;
  List<Inspection> _inspections = [];
  List<InspectionItem> _inspectionItems = [];
  bool _isLoading = false;

  List<Inspection> get inspections => _inspections;
  List<InspectionItem> get inspectionItems => _inspectionItems;
  bool get isLoading => _isLoading;

  Future<void> loadInspectionsByProperty(int propertyId) async {
    _isLoading = true;
    notifyListeners();
    final maps = await _db.getInspectionsByProperty(propertyId);
    _inspections = maps.map((m) => Inspection.fromMap(m)).toList();
    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadInspectionItems(int inspectionId) async {
    final maps = await _db.getInspectionItems(inspectionId);
    _inspectionItems = maps.map((m) => InspectionItem.fromMap(m)).toList();
    notifyListeners();
  }

  Future<int> addInspection(Inspection inspection) async {
    final id = await _db.insert('inspections', inspection.toMap());
    await loadInspectionsByProperty(inspection.propertyId);
    return id;
  }

  Future<void> updateInspection(Inspection inspection) async {
    await _db.update('inspections', inspection.toMap(), inspection.id!);
    await loadInspectionsByProperty(inspection.propertyId);
  }

  Future<void> deleteInspection(int id, int propertyId) async {
    await _db.delete('inspections', id);
    await loadInspectionsByProperty(propertyId);
  }

  Future<void> addInspectionItem(InspectionItem item) async {
    await _db.insert('inspection_items', item.toMap());
    await loadInspectionItems(item.inspectionId);
  }

  Future<void> deleteInspectionItem(int id, int inspectionId) async {
    await _db.delete('inspection_items', id);
    await loadInspectionItems(inspectionId);
  }
}
