import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../providers/auth_provider.dart';
import '../../services/firestore_service.dart';

class MaintenanceBoardScreen extends StatefulWidget {
  const MaintenanceBoardScreen({super.key});

  @override
  State<MaintenanceBoardScreen> createState() =>
      _MaintenanceBoardScreenState();
}

class _MaintenanceBoardScreenState extends State<MaintenanceBoardScreen> {
  final _firestore = FirestoreService.instance;

  Future<void> _updateStatus(String ticketId, String newStatus) async {
    await _firestore.updateMaintenanceTicket(ticketId, {'status': newStatus});
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final uid = auth.user?.uid ?? '';

    return Scaffold(
      appBar: AppBar(title: const Text('Maintenance Board')),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore.maintenanceByCaretakerStream(uid),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final all = snapshot.data!.docs;
          final open = all.where((d) =>
              (d.data() as Map<String, dynamic>)['status'] == 'open');
          final inProgress = all.where((d) =>
              (d.data() as Map<String, dynamic>)['status'] == 'in_progress');
          final resolved = all.where((d) =>
              (d.data() as Map<String, dynamic>)['status'] == 'resolved');

          return Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                color: Theme.of(context).colorScheme.surfaceVariant,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _statusBadge('Open', open.length, Colors.red),
                    _statusBadge('In Progress', inProgress.length, Colors.orange),
                    _statusBadge('Resolved', resolved.length, Colors.green),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    if (open.isNotEmpty) ...[
                      Text('Open (${open.length})',
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      ...open.map((d) => _ticketCard(d)),
                    ],
                    if (inProgress.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Text('In Progress (${inProgress.length})',
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      ...inProgress.map((d) => _ticketCard(d)),
                    ],
                    if (resolved.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Text('Resolved (${resolved.length})',
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      ...resolved.map((d) => _ticketCard(d)),
                    ],
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _statusBadge(String label, int count, Color color) {
    return Column(
      children: [
        Text(count.toString(),
            style: TextStyle(
                fontSize: 28, fontWeight: FontWeight.bold, color: color)),
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
      ],
    );
  }

  Widget _ticketCard(QueryDocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final status = data['status'] as String? ?? 'open';

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(
          status == 'open'
              ? Icons.bug_report
              : status == 'in_progress'
                  ? Icons.engineering
                  : Icons.check_circle,
          color: status == 'open'
              ? Colors.red
              : status == 'in_progress'
                  ? Colors.orange
                  : Colors.green,
        ),
        title: Text(data['issue'] as String? ?? '',
            style: const TextStyle(fontSize: 14)),
        subtitle: Text('Unit: ${data['unitId'] ?? ''}',
            style: const TextStyle(fontSize: 11)),
        trailing: PopupMenuButton<String>(
          onSelected: (s) => _updateStatus(doc.id, s),
          itemBuilder: (_) => [
            if (status != 'open')
              const PopupMenuItem(
                  value: 'open', child: Text('Move to Open')),
            if (status != 'in_progress')
              const PopupMenuItem(
                  value: 'in_progress', child: Text('Move to In Progress')),
            if (status != 'resolved')
              const PopupMenuItem(
                  value: 'resolved', child: Text('Mark Resolved')),
          ],
          child: const Icon(Icons.more_vert),
        ),
      ),
    );
  }
}
