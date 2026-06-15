import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/firestore_service.dart';

class PaymentPlaceholderScreen extends StatelessWidget {
  final String? unitId;
  final String? tenantId;

  const PaymentPlaceholderScreen({super.key, this.unitId, this.tenantId});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fmt = NumberFormat.currency(symbol: 'KES ');

    return Scaffold(
      appBar: AppBar(title: const Text('Payments')),
      body: StreamBuilder<QuerySnapshot>(
        stream: tenantId != null
            ? FirebaseFirestore.instance
                .collection('leases')
                .where('tenantId', isEqualTo: tenantId)
                .where('isActive', isEqualTo: true)
                .limit(1)
                .snapshots()
            : null,
        builder: (context, snapshot) {
          final rentAmount = snapshot?.hasData == true && snapshot!.data!.docs.isNotEmpty
              ? (snapshot.data!.docs.first.data() as Map<String, dynamic>)['rentAmount'] as num?
              : null;

          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Icon(Icons.payments_outlined, size: 64, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text('Payment Gateway',
                  style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center),
              const SizedBox(height: 8),
              Text(
                'Online payments are coming soon.\nYou can still make payments manually via M-Pesa, bank transfer, or cash.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.grey[600], height: 1.5),
              ),
              const SizedBox(height: 24),
              if (rentAmount != null) ...[
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Text('Current Rent Due',
                            style: TextStyle(fontSize: 13, color: Colors.grey[600])),
                        const SizedBox(height: 4),
                        Text(fmt.format(rentAmount),
                            style: theme.textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.bold, color: Colors.green)),
                        const SizedBox(height: 8),
                        Chip(
                          avatar: Icon(Icons.info_outline, size: 14, color: Colors.orange[700]),
                          label: const Text('Gateway not yet connected',
                              style: TextStyle(fontSize: 11)),
                          backgroundColor: Colors.orange.withValues(alpha: 0.1),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.withValues(alpha: 0.2)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.lightbulb_outline, size: 18, color: Colors.blue[700]),
                        const SizedBox(width: 8),
                        Text('Manual Payment Options',
                            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue[700])),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _optionRow('M-Pesa Paybill', 'Business Number: 247247'),
                    const SizedBox(height: 8),
                    _optionRow('Bank Transfer', 'Account: REMS - 1234567890'),
                    const SizedBox(height: 8),
                    _optionRow('Cash', 'Pay at the property management office'),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _optionRow(String title, String detail) {
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Icon(Icons.check_circle, size: 16, color: Colors.green[400]),
      const SizedBox(width: 8),
      Expanded(child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
          Text(detail, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
        ],
      )),
    ]);
  }
}
