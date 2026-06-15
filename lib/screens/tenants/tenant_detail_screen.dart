import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/tenant.dart';
import '../../providers/tenant_provider.dart';
import '../../providers/lease_provider.dart';
import '../../providers/payment_provider.dart';

class TenantDetailScreen extends StatefulWidget {
  final int tenantId;

  const TenantDetailScreen({super.key, required this.tenantId});

  @override
  State<TenantDetailScreen> createState() => _TenantDetailScreenState();
}

class _TenantDetailScreenState extends State<TenantDetailScreen> {
  Tenant? _tenant;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadTenant();
  }

  void _loadTenant() {
    final provider = context.read<TenantProvider>();
    _tenant = provider.getTenantById(widget.tenantId);
    setState(() => _loading = false);
    context.read<LeaseProvider>().loadLeases();
    context.read<PaymentProvider>().loadPayments();
  }

  @override
  Widget build(BuildContext context) {
    final leaseProvider = context.watch<LeaseProvider>();
    final paymentProvider = context.watch<PaymentProvider>();
    final currencyFormat = NumberFormat.currency(symbol: '\$');
    final dateFormat = DateFormat('MMM dd, yyyy');

    if (_loading || _tenant == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final tenant = _tenant!;
    final tenantLeases = leaseProvider.getLeasesByTenant(widget.tenantId);
    final activeLease = tenantLeases.where((l) => l.isActive).toList();
    final payments = paymentProvider.getPaymentsByTenant(widget.tenantId);
    final totalPaid = payments
        .where((p) => p.status == 'Paid')
        .fold<double>(0, (sum, p) => sum + p.amount);

    return Scaffold(
      appBar: AppBar(
        title: Text(tenant.name),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 32,
                      backgroundColor:
                          Theme.of(context).primaryColor.withValues(alpha: 0.1),
                      child: Text(
                        tenant.name.isNotEmpty
                            ? tenant.name[0].toUpperCase()
                            : '?',
                        style: TextStyle(
                          color: Theme.of(context).primaryColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 24,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(tenant.name,
                              style: const TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold)),
                          Text(tenant.email,
                              style: TextStyle(color: Colors.grey[600])),
                          Text(tenant.phone,
                              style: TextStyle(color: Colors.grey[600])),
                        ],
                      ),
                    ),
                    Column(
                      children: [
                        Text(
                          currencyFormat.format(totalPaid),
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 18),
                        ),
                        Text('Total Paid',
                            style: TextStyle(
                                fontSize: 12, color: Colors.grey[600])),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            if (tenant.emergencyContact.isNotEmpty) ...[
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Emergency Contact',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 8),
                      Text('Name: ${tenant.emergencyContact}'),
                      Text('Phone: ${tenant.emergencyPhone}'),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 16),
            Text('Active Leases',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    )),
            const SizedBox(height: 8),
            if (activeLease.isEmpty)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('No active leases'),
                ),
              )
            else
              ...activeLease.map((lease) => Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: const Icon(Icons.description,
                          color: Colors.blue),
                      title: Text(
                          '\$${lease.rentAmount.toStringAsFixed(0)}/mo'),
                      subtitle: Text(
                        '${dateFormat.format(lease.startDate)} - ${dateFormat.format(lease.endDate)}',
                      ),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: lease.endDate.isBefore(DateTime.now())
                              ? Colors.red.withValues(alpha: 0.1)
                              : Colors.green.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          lease.endDate.isBefore(DateTime.now())
                              ? 'Expired'
                              : 'Active',
                          style: TextStyle(
                            fontSize: 11,
                            color: lease.endDate.isBefore(DateTime.now())
                                ? Colors.red
                                : Colors.green,
                          ),
                        ),
                      ),
                    ),
                  )),
            const SizedBox(height: 16),
            Text('Payment History',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    )),
            const SizedBox(height: 8),
            if (payments.isEmpty)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('No payments recorded'),
                ),
              )
            else
              ...payments.take(5).map((payment) => Card(
                    margin: const EdgeInsets.only(bottom: 4),
                    child: ListTile(
                      leading: Icon(
                        payment.status == 'Paid'
                            ? Icons.check_circle
                            : Icons.schedule,
                        color: payment.status == 'Paid'
                            ? Colors.green
                            : Colors.orange,
                      ),
                      title: Text(
                          currencyFormat.format(payment.amount)),
                      subtitle: Text(
                          '${payment.paymentType} • ${dateFormat.format(payment.paymentDate)}'),
                      trailing: Text(payment.status,
                          style: TextStyle(
                            color: payment.status == 'Paid'
                                ? Colors.green
                                : Colors.orange,
                          )),
                    ),
                  )),
          ],
        ),
      ),
    );
  }
}
