import 'package:flutter/foundation.dart';
import '../database/database_helper.dart';
import '../models/document.dart';

class DocumentProvider extends ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper.instance;
  List<Document> _documents = [];
  bool _isLoading = false;

  List<Document> get documents => _documents;
  bool get isLoading => _isLoading;

  Future<void> loadDocuments({
    int? propertyId,
    int? unitId,
    int? tenantId,
  }) async {
    _isLoading = true;
    notifyListeners();
    if (propertyId == null && unitId == null && tenantId == null) {
      final maps = await _db.queryAll('documents');
      _documents = maps.map((m) => Document.fromMap(m)).toList();
    } else {
      final maps = await _db.getDocumentsByTarget(
        propertyId: propertyId,
        unitId: unitId,
        tenantId: tenantId,
      );
      _documents = maps.map((m) => Document.fromMap(m)).toList();
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> addDocument(Document document) async {
    await _db.insert('documents', document.toMap());
    await loadDocuments();
  }

  Future<void> deleteDocument(int id) async {
    await _db.delete('documents', id);
    await loadDocuments();
  }

  List<Document> getDocumentsByCategory(String category) {
    return _documents.where((d) => d.category == category).toList();
  }
}
