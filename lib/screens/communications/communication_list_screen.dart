import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/communication_provider.dart';
import '../../models/communication_log.dart';
import 'add_communication_screen.dart';

class CommunicationListScreen extends StatefulWidget {
  const CommunicationListScreen({super.key});

  @override
  State<CommunicationListScreen> createState() => _CommunicationListScreenState();
}

class _CommunicationListScreenState extends State<CommunicationListScreen> {
  String _filterType = 'All';
  String _filterDirection = 'All';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CommunicationProvider>().loadAllLogs();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CommunicationProvider>();

    var logs = provider.logs;
    if (_filterType != 'All') {
      logs = logs.where((l) => l.type == _filterType).toList();
    }
    if (_filterDirection != 'All') {
      logs = logs.where((l) => l.direction == _filterDirection).toList();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Communications'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => Navigator.push(
              context, MaterialPageRoute(builder: (_) => const AddCommunicationScreen())),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildFilters(),
          Expanded(
            child: provider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : _buildList(provider, logs),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: DropdownButtonFormField<String>(
              value: _filterType,
              decoration: const InputDecoration(
                labelText: 'Type', border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8), isDense: true,
              ),
              items: ['All', 'Phone', 'Email', 'SMS', 'In-person', 'Mail']
                  .map((t) => DropdownMenuItem(value: t, child: Text(t, style: const TextStyle(fontSize: 13))))
                  .toList(),
              onChanged: (v) => setState(() => _filterType = v!),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: DropdownButtonFormField<String>(
              value: _filterDirection,
              decoration: const InputDecoration(
                labelText: 'Direction', border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8), isDense: true,
              ),
              items: ['All', 'Inbound', 'Outbound']
                  .map((d) => DropdownMenuItem(value: d, child: Text(d, style: const TextStyle(fontSize: 13))))
                  .toList(),
              onChanged: (v) => setState(() => _filterDirection = v!),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildList(CommunicationProvider provider, List<CommunicationLog> logs) {
    if (logs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.chat_outlined, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text('No communications logged', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: () => Navigator.push(
                context, MaterialPageRoute(builder: (_) => const AddCommunicationScreen())),
              icon: const Icon(Icons.add),
              label: const Text('Log Communication'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => provider.loadAllLogs(),
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: logs.length,
        itemBuilder: (context, index) {
          final log = logs[index];
          return Dismissible(
            key: ValueKey(log.id),
            direction: DismissDirection.endToStart,
            background: Container(
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 24),
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(12)),
              child: const Icon(Icons.delete, color: Colors.white),
            ),
            confirmDismiss: (_) async {
              HapticFeedback.mediumImpact();
              final ok = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Delete'),
                  content: const Text('Delete this log?'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      style: TextButton.styleFrom(foregroundColor: Colors.red),
                      child: const Text('Delete'),
                    ),
                  ],
                ),
              );
              if (ok == true) provider.deleteLog(log.id!);
              return false;
            },
            child: Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: _typeColor(log.type).withValues(alpha: 0.1),
                  child: Icon(_typeIcon(log.type), color: _typeColor(log.type), size: 20),
                ),
                title: Text(log.subject.isEmpty ? log.type : log.subject,
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                subtitle: Text(
                  '${log.direction} \u2022 ${DateFormat.yMMMd().add_jm().format(log.communicationDate)}',
                  style: const TextStyle(fontSize: 12),
                ),
                trailing: Chip(
                  label: Text(log.type, style: const TextStyle(fontSize: 10)),
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                ),
                onTap: () => _showDetails(log),
              ),
            ),
          );
        },
      ),
    );
  }

  void _showDetails(CommunicationLog log) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(log.subject.isEmpty ? log.type : log.subject,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            _row('Type', log.type),
            _row('Direction', log.direction),
            _row('Date', DateFormat.yMMMd().add_jm().format(log.communicationDate)),
            if (log.notes.isNotEmpty) ...[
              const SizedBox(height: 8),
              const Text('Notes:', style: TextStyle(fontWeight: FontWeight.w500)),
              Text(log.notes),
            ],
          ],
        ),
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(children: [
        SizedBox(width: 80, child: Text(label, style: const TextStyle(fontWeight: FontWeight.w500, color: Colors.grey))),
        Expanded(child: Text(value)),
      ]),
    );
  }

  Color _typeColor(String type) {
    switch (type) {
      case 'Phone': return Colors.blue;
      case 'Email': return Colors.red;
      case 'SMS': return Colors.green;
      case 'In-person': return Colors.purple;
      case 'Mail': return Colors.orange;
      default: return Colors.grey;
    }
  }

  IconData _typeIcon(String type) {
    switch (type) {
      case 'Phone': return Icons.phone;
      case 'Email': return Icons.email;
      case 'SMS': return Icons.sms;
      case 'In-person': return Icons.person;
      case 'Mail': return Icons.mail;
      default: return Icons.chat;
    }
  }
}
