import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/lease_provider.dart';

import '../../providers/tenant_provider.dart';
import 'add_edit_lease_screen.dart';

class LeaseListScreen extends StatefulWidget {
  const LeaseListScreen({super.key});

  @override
  State<LeaseListScreen> createState() => _LeaseListScreenState();
}

class _LeaseListScreenState extends State<LeaseListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<LeaseProvider>().loadLeases();
      context.read<TenantProvider>().loadTenants();
    });
  }

  @override
  Widget build(BuildContext context) {
    final leaseProvider = context.watch<LeaseProvider>();
    final currencyFormat = NumberFormat.currency(symbol: '\$');
    final dateFormat = DateFormat('MMM dd, yyyy');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Leases'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AddEditLeaseScreen()),
            ),
          ),
        ],
      ),
      body: leaseProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : leaseProvider.leases.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.description_outlined,
                          size: 64, color: Colors.grey[300]),
                      const SizedBox(height: 16),
                      Text('No leases yet',
                          style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 8),
                      ElevatedButton.icon(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const AddEditLeaseScreen()),
                        ),
                        icon: const Icon(Icons.add),
                        label: const Text('Create Lease'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: () => leaseProvider.loadLeases(),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: leaseProvider.leases.length,
                    itemBuilder: (context, index) {
                      final lease = leaseProvider.leases[index];
                      final tenant = context
                          .read<TenantProvider>()
                          .getTenantById(lease.tenantId);
                      final isExpired =
                          lease.endDate.isBefore(DateTime.now());
                      final tenantName = tenant?.name ?? 'Tenant #${lease.tenantId}';

                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: lease.isActive
                                  ? Colors.green.withValues(alpha: 0.1)
                                  : Colors.grey.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.description,
                              color: lease.isActive
                                  ? Colors.green
                                  : Colors.grey,
                            ),
                          ),
                          title: Text(tenantName,
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text(
                            '${dateFormat.format(lease.startDate)} - ${dateFormat.format(lease.endDate)}',
                          ),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                currencyFormat.format(lease.rentAmount),
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: isExpired
                                      ? Colors.red.withValues(alpha: 0.1)
                                      : Colors.green.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  isExpired ? 'Expired' : 'Active',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: isExpired
                                        ? Colors.red
                                        : Colors.green,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          onTap: () {},
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
