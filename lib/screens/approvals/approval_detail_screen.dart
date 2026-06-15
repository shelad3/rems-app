import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/approval_provider.dart';

class ApprovalDetailScreen extends StatefulWidget {
  final int approvalId;
  const ApprovalDetailScreen({super.key, required this.approvalId});

  @override
  State<ApprovalDetailScreen> createState() => _ApprovalDetailScreenState();
}

class _ApprovalDetailScreenState extends State<ApprovalDetailScreen> {
  final _notesController = TextEditingController();

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ApprovalProvider>();
    final approval = provider.approvals.where((a) => a.id == widget.approvalId).firstOrNull;

    if (approval == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Approval')),
        body: const Center(child: Text('Not found')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(approval.title)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(approval.title,
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                      ),
                      Chip(
                        label: Text(approval.status, style: const TextStyle(fontSize: 11)),
                        backgroundColor: _statusColor(approval.status).withValues(alpha: 0.1),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _row('Type', approval.referenceType),
                  _row('Requested by', approval.requestedByName ?? approval.requestedBy),
                  if (approval.amount != null) _row('Amount', '\$${approval.amount!.toStringAsFixed(2)}'),
                  _row('Created', DateFormat.yMMMd().format(approval.createdAt)),
                  if (approval.description.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    const Text('Description', style: TextStyle(fontWeight: FontWeight.w500)),
                    Text(approval.description),
                  ],
                ],
              ),
            ),
          ),
          if (approval.status == 'Pending') ...[
            const SizedBox(height: 16),
            Text('Review Decision', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Review Notes',
                border: OutlineInputBorder(),
                hintText: 'Add notes about your decision...',
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _review(approval.id!, 'Rejected'),
                    icon: const Icon(Icons.close),
                    label: const Text('Reject'),
                    style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => _review(approval.id!, 'Approved'),
                    icon: const Icon(Icons.check),
                    label: const Text('Approve'),
                  ),
                ),
              ],
            ),
          ],
          if (approval.status != 'Pending' && approval.reviewNotes != null) ...[
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Review Notes', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(approval.reviewNotes!),
                    if (approval.reviewedBy != null) ...[
                      const SizedBox(height: 8),
                      Text('Reviewed by ${approval.reviewedBy}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _review(int id, String status) async {
    await context.read<ApprovalProvider>().reviewApproval(
      id, status, 'Manager', _notesController.text.trim(),
    );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Request $status')),
      );
      Navigator.pop(context);
    }
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(children: [
        SizedBox(width: 100, child: Text(label, style: const TextStyle(fontWeight: FontWeight.w500, color: Colors.grey))),
        Expanded(child: Text(value)),
      ]),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'Approved': return Colors.green;
      case 'Rejected': return Colors.red;
      default: return Colors.orange;
    }
  }
}
