import 'package:flutter/foundation.dart';
import '../database/database_helper.dart';
import '../models/approval.dart';

class ApprovalProvider extends ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper.instance;
  List<Approval> _approvals = [];
  List<Approval> _pendingApprovals = [];
  bool _isLoading = false;

  List<Approval> get approvals => _approvals;
  List<Approval> get pendingApprovals => _pendingApprovals;
  bool get isLoading => _isLoading;

  Future<void> loadApprovals() async {
    _isLoading = true;
    notifyListeners();
    final maps = await _db.getAllApprovals();
    _approvals = maps.map((m) => Approval.fromMap(m)).toList();
    final pendingMaps = await _db.getPendingApprovals();
    _pendingApprovals =
        pendingMaps.map((m) => Approval.fromMap(m)).toList();
    _isLoading = false;
    notifyListeners();
  }

  Future<void> addApproval(Approval approval) async {
    await _db.insert('approvals', approval.toMap());
    await loadApprovals();
  }

  Future<void> reviewApproval(
      int id, String status, String reviewedBy, String reviewNotes) async {
    final values = {
      'status': status,
      'reviewed_by': reviewedBy,
      'review_notes': reviewNotes,
      'reviewed_at': DateTime.now().toIso8601String(),
    };
    await _db.update('approvals', values, id);
    await loadApprovals();
  }

  Future<void> deleteApproval(int id) async {
    await _db.delete('approvals', id);
    await loadApprovals();
  }

  int get pendingCount => _pendingApprovals.length;
}
