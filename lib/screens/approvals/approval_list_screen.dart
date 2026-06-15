import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/approval_provider.dart';
import '../../models/approval.dart';
import 'approval_detail_screen.dart';

class ApprovalListScreen extends StatefulWidget {
  const ApprovalListScreen({super.key});

  @override
  State<ApprovalListScreen> createState() => _ApprovalListScreenState();
}

class _ApprovalListScreenState extends State<ApprovalListScreen> {
  String _filter = 'All';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ApprovalProvider>().loadApprovals();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ApprovalProvider>();

    final approvals = _filter == 'All'
        ? provider.approvals
        : _filter == 'Pending'
            ? provider.pendingApprovals
            : provider.approvals.where((a) => a.status == _filter).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Approvals')),
      body: Column(
        children: [
          _buildFilterBar(),
          Expanded(
            child: provider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : _buildList(approvals, provider),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar() {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Row(
        children: ['All', 'Pending', 'Approved', 'Rejected'].map((f) {
          final selected = _filter == f;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: FilterChip(
              label: Text(f, style: const TextStyle(fontSize: 12)),
              selected: selected,
              onSelected: (_) => setState(() => _filter = f),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildList(List<Approval> approvals, ApprovalProvider provider) {
    if (approvals.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.task_alt, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text('No approvals found', style: Theme.of(context).textTheme.titleMedium),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => provider.loadApprovals(),
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: approvals.length,
        itemBuilder: (context, index) {
          final approval = approvals[index];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: _statusColor(approval.status).withValues(alpha: 0.1),
                child: Icon(_statusIcon(approval.status),
                    color: _statusColor(approval.status), size: 20),
              ),
              title: Text(approval.title, maxLines: 1, overflow: TextOverflow.ellipsis),
              subtitle: Text(
                '${approval.referenceType} \u2022 ${approval.status}',
                style: const TextStyle(fontSize: 12),
              ),
              trailing: approval.amount != null
                  ? Text('\$${approval.amount!.toStringAsFixed(2)}',
                      style: const TextStyle(fontWeight: FontWeight.bold))
                  : null,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ApprovalDetailScreen(approvalId: approval.id!),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'Approved': return Colors.green;
      case 'Rejected': return Colors.red;
      default: return Colors.orange;
    }
  }

  IconData _statusIcon(String status) {
    switch (status) {
      case 'Approved': return Icons.check_circle;
      case 'Rejected': return Icons.cancel;
      default: return Icons.schedule;
    }
  }
}
