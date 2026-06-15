import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../providers/auth_provider.dart';
import '../../services/firestore_service.dart';
import '../chat/chat_screen.dart';

class ApplicationReviewScreen extends StatefulWidget {
  const ApplicationReviewScreen({super.key});

  @override
  State<ApplicationReviewScreen> createState() =>
      _ApplicationReviewScreenState();
}

class _ApplicationReviewScreenState extends State<ApplicationReviewScreen> {
  final _firestore = FirestoreService.instance;
  final _fmt = NumberFormat.currency(symbol: 'KES ');

  Future<void> _approve(String appId, String unitId) async {
    await _firestore.updateApplication(appId, {
      'status': 'approved',
      'reviewedAt': DateTime.now().toIso8601String(),
    });
    await _firestore.updateUnit(unitId, {'status': 'occupied'});
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Application approved')),
      );
    }
  }

  void _showCounterDialog(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final rentCtrl = TextEditingController(
      text: (data['proposedRent'] as num?)?.toStringAsFixed(0) ?? '',
    );
    final depositCtrl = TextEditingController(
      text: (data['proposedDeposit'] as num?)?.toStringAsFixed(0) ?? '',
    );
    final notesCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Counter Offer'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: rentCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Rent (KES)',
                prefixText: 'KES ',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: depositCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Deposit (KES)',
                prefixText: 'KES ',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: notesCtrl,
              maxLines: 2,
              decoration: const InputDecoration(labelText: 'Notes (optional)'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              await _firestore.updateApplication(doc.id, {
                'status': 'countered',
                'caretakerCounterRent': double.tryParse(rentCtrl.text) ?? 0,
                'caretakerCounterDeposit': double.tryParse(depositCtrl.text) ?? 0,
                'caretakerNotes': notesCtrl.text,
                'reviewedAt': DateTime.now().toIso8601String(),
              });
              if (ctx.mounted) Navigator.pop(ctx);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Counter offer sent')),
                );
              }
            },
            child: const Text('Send Counter'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final uid = auth.user?.uid ?? '';
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Review Applications')),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore.pendingAndCounteredStream(uid),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final apps = snapshot.data!.docs;

          if (apps.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle_outline, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text('No pending or countered applications',
                      style: TextStyle(color: Colors.grey[600], fontSize: 16)),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: apps.length,
            itemBuilder: (_, i) {
              final doc = apps[i];
              final data = doc.data() as Map<String, dynamic>;
              final status = data['status'] as String? ?? 'pending';
              final proposedRent = (data['proposedRent'] as num?)?.toDouble() ?? 0;
              final proposedDeposit = (data['proposedDeposit'] as num?)?.toDouble() ?? 0;
              final countered = status == 'countered';

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: colorScheme.primary,
                            child: Text(
                              (data['tenantName'] as String? ?? 'T')[0].toUpperCase(),
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(data['tenantName'] as String? ?? '',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                Text('Unit: ${data['unitId'] ?? ''}',
                                    style: const TextStyle(fontSize: 12, color: Colors.grey)),
                              ],
                            ),
                          ),
                          Chip(
                            label: Text(status, style: const TextStyle(fontSize: 11)),
                            backgroundColor: countered
                                ? Colors.purple.withValues(alpha: 0.1)
                                : Colors.orange.withValues(alpha: 0.1),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // ─── Terms ────────────────────────────────
                      Row(children: [
                        Icon(Icons.monetization_on, size: 16, color: Colors.green[700]),
                        const SizedBox(width: 4),
                        Text('Proposed: ', style: TextStyle(fontSize: 13, color: Colors.grey[600])),
                        Text(_fmt.format(proposedRent) + '/mo',
                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                      ]),
                      Row(children: [
                        Icon(Icons.savings, size: 16, color: Colors.blue[700]),
                        const SizedBox(width: 4),
                        Text('Deposit: ', style: TextStyle(fontSize: 13, color: Colors.grey[600])),
                        Text(_fmt.format(proposedDeposit),
                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                      ]),
                      if (data['proposedDuration'] != null)
                        Row(children: [
                          Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                          const SizedBox(width: 4),
                          Text('Duration: ', style: TextStyle(fontSize: 13, color: Colors.grey[600])),
                          Text(data['proposedDuration'] as String,
                              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                        ]),
                      // ─── Counter terms ────────────────────────
                      if (countered && data['caretakerCounterRent'] != null) ...[
                        const Divider(height: 20),
                        Row(children: [
                          Icon(Icons.swap_horiz, size: 16, color: Colors.purple[700]),
                          const SizedBox(width: 4),
                          Text('Counter: ', style: TextStyle(fontSize: 13, color: Colors.purple[700])),
                          Text(_fmt.format((data['caretakerCounterRent'] as num).toDouble()) + '/mo',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.purple[700])),
                        ]),
                      ],
                      const SizedBox(height: 16),
                      // ─── Chat ──────────────────────────────────
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton.icon(
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ChatScreen(
                                unitId: data['unitId'] as String? ?? '',
                                currentUserId: uid,
                                otherUserId: data['tenantId'] as String? ?? '',
                                otherUserName: data['tenantName'] as String? ?? 'Tenant',
                              ),
                            ),
                          ),
                          icon: const Icon(Icons.chat, size: 16),
                          label: const Text('Chat with Tenant'),
                        ),
                      ),
                      const SizedBox(height: 8),
                      // ─── Actions ──────────────────────────────
                      Row(children: [
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: () => _approve(doc.id, data['unitId'] as String),
                            icon: const Icon(Icons.check, size: 18),
                            label: const Text('Approve'),
                            style: FilledButton.styleFrom(backgroundColor: Colors.green),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: () => _showCounterDialog(doc),
                            icon: const Icon(Icons.swap_horiz, size: 18),
                            label: const Text('Counter'),
                            style: FilledButton.styleFrom(backgroundColor: Colors.purple),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () async {
                              await _firestore.updateApplication(doc.id, {
                                'status': 'rejected',
                                'reviewedAt': DateTime.now().toIso8601String(),
                              });
                            },
                            icon: const Icon(Icons.close, size: 18),
                            label: const Text('Reject'),
                            style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.red, side: const BorderSide(color: Colors.red)),
                          ),
                        ),
                      ]),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
