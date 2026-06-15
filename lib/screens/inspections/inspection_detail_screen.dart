import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/inspection_provider.dart';

class InspectionDetailScreen extends StatefulWidget {
  final int inspectionId;
  const InspectionDetailScreen({super.key, required this.inspectionId});

  @override
  State<InspectionDetailScreen> createState() =>
      _InspectionDetailScreenState();
}

class _InspectionDetailScreenState extends State<InspectionDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context
          .read<InspectionProvider>()
          .loadInspectionItems(widget.inspectionId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<InspectionProvider>();
    final inspection = provider.inspections
        .where((i) => i.id == widget.inspectionId)
        .firstOrNull;

    if (inspection == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Inspection')),
        body: const Center(child: Text('Inspection not found')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(inspection.title)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(inspection.title,
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge
                          ?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  _row('Type', inspection.type),
                  _row('Condition', inspection.overallCondition),
                  _row('Date',
                      DateFormat.yMMMd().format(inspection.inspectionDate)),
                  if (inspection.notes.isNotEmpty)
                    _row('Notes', inspection.notes),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text('Room-by-Room Results',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          if (provider.inspectionItems.isEmpty)
            const Center(child: Padding(
              padding: EdgeInsets.all(24),
              child: Text('No room data recorded'),
            ))
          else
            ...provider.inspectionItems.map((item) => Card(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: _conditionColor(item.condition)
                          .withValues(alpha: 0.1),
                      child: Icon(Icons.check,
                          color: _conditionColor(item.condition), size: 18),
                    ),
                    title: Text(item.roomName),
                    subtitle: Text(
                        '${item.category} \u2022 ${item.condition}'),
                    trailing: item.photoPath != null
                        ? const Icon(Icons.image, size: 18)
                        : null,
                  ),
                )),
        ],
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(label,
                style: const TextStyle(
                    fontWeight: FontWeight.w500, color: Colors.grey)),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Color _conditionColor(String condition) {
    switch (condition) {
      case 'Excellent':
        return Colors.green;
      case 'Good':
        return Colors.blue;
      case 'Fair':
        return Colors.orange;
      case 'Poor':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
