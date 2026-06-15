import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../providers/auth_provider.dart';
import '../../services/firestore_service.dart';
import 'application_review_screen.dart';
import 'maintenance_board_screen.dart';

class CaretakerTaskHub extends StatelessWidget {
  const CaretakerTaskHub({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final uid = auth.user?.uid ?? '';
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Task Hub')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirestoreService.instance.pendingApplicationsStream(uid),
        builder: (context, appSnap) {
          final pendingApps = appSnap.data?.docs.length ?? 0;

          return StreamBuilder<QuerySnapshot>(
            stream: FirestoreService.instance.maintenanceByCaretakerStream(uid),
            builder: (context, maintSnap) {
              final maintDocs = maintSnap.data?.docs ?? [];
              final open = maintDocs.where((d) =>
                      (d.data() as Map)['status'] == 'open')
                  .length;

              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Text('Overview',
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _statCard(Icons.pending_actions,
                            'Pending\nApplications', pendingApps.toString(),
                            Colors.orange, colorScheme),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _statCard(Icons.build, 'Open\nMaintenance',
                            open.toString(), Colors.red, colorScheme),
                      ),
                      Expanded(
                        child: _statCard(Icons.check_circle,
                            'My\nUnits', '-', Colors.green, colorScheme),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: FilledButton.icon(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const ApplicationReviewScreen()),
                      ),
                      icon: const Icon(Icons.pending_actions),
                      label: Text(
                          'Review Applications ($pendingApps pending)',
                          style: const TextStyle(fontSize: 15)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: FilledButton.tonalIcon(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const MaintenanceBoardScreen()),
                      ),
                      icon: const Icon(Icons.build),
                      label: const Text('Manage Maintenance',
                          style: TextStyle(fontSize: 15)),
                    ),
                  ),
                  const SizedBox(height: 24),
                  if (maintDocs.isNotEmpty) ...[
                    Text('Recent Tickets',
                        style: theme.textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    ...maintDocs.take(5).map((d) {
                      final data = d.data() as Map<String, dynamic>;
                      return ListTile(
                        dense: true,
                        leading: Icon(
                          data['status'] == 'open'
                              ? Icons.bug_report
                              : data['status'] == 'in_progress'
                                  ? Icons.engineering
                                  : Icons.check_circle,
                          color: data['status'] == 'open'
                              ? Colors.red
                              : data['status'] == 'in_progress'
                                  ? Colors.orange
                                  : Colors.green,
                        ),
                        title: Text(data['issue'] as String? ?? '',
                            style: const TextStyle(fontSize: 14)),
                        subtitle: Text('Status: ${data['status']}',
                            style: const TextStyle(fontSize: 11)),
                      );
                    }),
                  ],
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _statCard(IconData icon, String label, String value, Color color,
      ColorScheme colors) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 4),
            Text(value,
                style: TextStyle(
                    fontSize: 24, fontWeight: FontWeight.bold, color: color)),
            Text(label,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 10, color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}
