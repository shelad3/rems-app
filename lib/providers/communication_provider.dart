import 'package:flutter/foundation.dart';
import '../database/database_helper.dart';
import '../models/communication_log.dart';

class CommunicationProvider extends ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper.instance;
  List<CommunicationLog> _logs = [];
  bool _isLoading = false;

  List<CommunicationLog> get logs => _logs;
  bool get isLoading => _isLoading;

  Future<void> loadAllLogs() async {
    _isLoading = true;
    notifyListeners();
    final maps = await _db.getAllCommunications();
    _logs = maps.map((m) => CommunicationLog.fromMap(m)).toList();
    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadLogsByTarget({
    int? propertyId,
    int? tenantId,
    int? ownerId,
  }) async {
    _isLoading = true;
    notifyListeners();
    final maps = await _db.getCommunicationsByTarget(
      propertyId: propertyId,
      tenantId: tenantId,
      ownerId: ownerId,
    );
    _logs = maps.map((m) => CommunicationLog.fromMap(m)).toList();
    _isLoading = false;
    notifyListeners();
  }

  Future<void> addLog(CommunicationLog log) async {
    await _db.insert('communication_logs', log.toMap());
    await loadAllLogs();
  }

  Future<void> deleteLog(int id) async {
    await _db.delete('communication_logs', id);
    await loadAllLogs();
  }
}
