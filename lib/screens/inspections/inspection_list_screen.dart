import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/inspection_provider.dart';
import '../../providers/property_provider.dart';
import '../../models/inspection.dart';
import 'add_inspection_screen.dart';
import 'inspection_detail_screen.dart';

class InspectionListScreen extends StatefulWidget {
  final int? propertyId;
  const InspectionListScreen({super.key, this.propertyId});

  @override
  State<InspectionListScreen> createState() => _InspectionListScreenState();
}

class _InspectionListScreenState extends State<InspectionListScreen> {
  int? _selectedPropertyId;

  @override
  void initState() {
    super.initState();
    _selectedPropertyId = widget.propertyId;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PropertyProvider>().loadProperties();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<InspectionProvider>();
    final properties = context.watch<PropertyProvider>().properties;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Inspections'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AddInspectionScreen()),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: DropdownButtonFormField<int>(
              value: _selectedPropertyId,
              decoration: const InputDecoration(
                labelText: 'Filter by Property',
                border: OutlineInputBorder(),
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              items: [
                const DropdownMenuItem(
                    value: null, child: Text('All Properties')),
                ...properties.map((p) =>
                    DropdownMenuItem(value: p.id, child: Text(p.name))),
              ],
              onChanged: (v) {
                setState(() => _selectedPropertyId = v);
                if (v != null) {
                  provider.loadInspectionsByProperty(v);
                } else {
                  provider.loadInspectionsByProperty(0);
                }
              },
            ),
          ),
          Expanded(
            child: provider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : _buildList(provider),
          ),
        ],
      ),
    );
  }

  Widget _buildList(InspectionProvider provider) {
    final inspections = _selectedPropertyId != null
        ? provider.inspections
        : <Inspection>[];

    if (inspections.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text('Select a property to view inspections',
                style: Theme.of(context).textTheme.titleMedium),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => provider.loadInspectionsByProperty(_selectedPropertyId!),
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: inspections.length,
        itemBuilder: (context, index) {
          final insp = inspections[index];
          return Dismissible(
            key: ValueKey(insp.id),
            direction: DismissDirection.endToStart,
            background: Container(
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 24),
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.delete, color: Colors.white),
            ),
            confirmDismiss: (_) async {
              HapticFeedback.mediumImpact();
              final ok = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Delete Inspection'),
                  content: Text('Delete "${insp.title}"?'),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text('Cancel')),
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      style: TextButton.styleFrom(foregroundColor: Colors.red),
                      child: const Text('Delete'),
                    ),
                  ],
                ),
              );
              if (ok == true) {
                provider.deleteInspection(insp.id!, insp.propertyId);
              }
              return false;
            },
            child: Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: _conditionColor(insp.overallCondition)
                      .withValues(alpha: 0.1),
                  child: Icon(Icons.search,
                      color: _conditionColor(insp.overallCondition),
                      size: 20),
                ),
                title: Text(insp.title),
                subtitle: Text(
                  '${insp.type} \u2022 ${insp.overallCondition} \u2022 ${DateFormat.yMMMd().format(insp.inspectionDate)}',
                  style: const TextStyle(fontSize: 12),
                ),
                trailing: Chip(
                  label: Text(insp.overallCondition,
                      style: const TextStyle(fontSize: 11)),
                  backgroundColor: _conditionColor(insp.overallCondition)
                      .withValues(alpha: 0.1),
                  side: BorderSide.none,
                  padding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                ),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        InspectionDetailScreen(inspectionId: insp.id!),
                  ),
                ),
              ),
            ),
          );
        },
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
