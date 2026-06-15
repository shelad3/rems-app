import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/maintenance_provider.dart';
import '../../providers/property_provider.dart';
import '../../widgets/maintenance_tile.dart';
import 'add_maintenance_screen.dart';

class MaintenanceListScreen extends StatefulWidget {
  const MaintenanceListScreen({super.key});

  @override
  State<MaintenanceListScreen> createState() => _MaintenanceListScreenState();
}

class _MaintenanceListScreenState extends State<MaintenanceListScreen> {
  String _filterStatus = 'All';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MaintenanceProvider>().loadRequests();
      context.read<PropertyProvider>().loadProperties();
    });
  }

  @override
  Widget build(BuildContext context) {
    final maintenanceProvider = context.watch<MaintenanceProvider>();

    final filteredRequests = _filterStatus == 'All'
        ? maintenanceProvider.requests
        : maintenanceProvider.requests
            .where((r) => r.status == _filterStatus)
            .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Maintenance'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => const AddMaintenanceScreen()),
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _buildFilterChip('All', Icons.all_inclusive),
                const SizedBox(width: 8),
                _buildFilterChip('Pending', Icons.schedule),
                const SizedBox(width: 8),
                _buildFilterChip('In Progress', Icons.build),
                const SizedBox(width: 8),
                _buildFilterChip('Completed', Icons.check_circle),
              ],
            ),
          ),
        ),
      ),
      body: maintenanceProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : filteredRequests.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.build_outlined,
                          size: 64, color: Colors.grey[300]),
                      const SizedBox(height: 16),
                      Text(
                          _filterStatus == 'All'
                              ? 'No maintenance requests'
                              : 'No $_filterStatus requests',
                          style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 8),
                      ElevatedButton.icon(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) =>
                                  const AddMaintenanceScreen()),
                        ),
                        icon: const Icon(Icons.add),
                        label: const Text('Add Request'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: () => maintenanceProvider.loadRequests(),
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: filteredRequests.length,
                    itemBuilder: (context, index) {
                      final request = filteredRequests[index];
                      return MaintenanceTile(
                        title: request.title,
                        tenantName: 'Tenant #${request.tenantId}',
                        unitNumber: 'Unit #${request.unitId}',
                        priority: request.priority,
                        status: request.status,
                        createdAt: request.createdAt,
                        onTap: () => _showRequestDetail(context, request),
                      );
                    },
                  ),
                ),
    );
  }

  Widget _buildFilterChip(String label, IconData icon) {
    final isSelected = _filterStatus == label;
    return FilterChip(
      label: Text(label, style: const TextStyle(fontSize: 11)),
      selected: isSelected,
      onSelected: (_) => setState(() => _filterStatus = label),
      selectedColor:
          Theme.of(context).primaryColor.withValues(alpha: 0.2),
      avatar: Icon(icon, size: 14),
      visualDensity: VisualDensity.compact,
    );
  }

  void _showRequestDetail(BuildContext context, dynamic request) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(request.title,
                style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildInfo('Priority', request.priority),
                const SizedBox(width: 16),
                _buildInfo('Status', request.status),
              ],
            ),
            const SizedBox(height: 12),
            Text(request.description),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                if (request.status != 'Completed')
                  ElevatedButton.icon(
                    onPressed: () {
                      final updated = request.copyWith(
                        status: request.status == 'Pending'
                            ? 'In Progress'
                            : 'Completed',
                        resolvedAt: DateTime.now(),
                      );
                      context
                          .read<MaintenanceProvider>()
                          .updateRequest(updated);
                      Navigator.pop(context);
                    },
                    icon: Icon(
                      request.status == 'Pending'
                          ? Icons.play_arrow
                          : Icons.check,
                    ),
                    label: Text(
                      request.status == 'Pending'
                          ? 'Start'
                          : 'Complete',
                    ),
                  ),
                TextButton(
                  onPressed: () {
                    context
                        .read<MaintenanceProvider>()
                        .deleteRequest(request.id!);
                    Navigator.pop(context);
                  },
                  child: const Text('Delete',
                      style: TextStyle(color: Colors.red)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfo(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(fontSize: 12, color: Colors.grey[600])),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.grey.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
        ),
      ],
    );
  }
}
