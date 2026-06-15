import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class PaymentTile extends StatelessWidget {
  final double amount;
  final String tenantName;
  final DateTime paymentDate;
  final String status;
  final String paymentType;

  const PaymentTile({
    super.key,
    required this.amount,
    required this.tenantName,
    required this.paymentDate,
    required this.status,
    required this.paymentType,
  });

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(symbol: '\$');
    final dateFormat = DateFormat('MMM dd, yyyy');

    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: status == 'Paid'
              ? Colors.green.withValues(alpha: 0.1)
              : status == 'Pending'
                  ? Colors.orange.withValues(alpha: 0.1)
                  : Colors.red.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          status == 'Paid'
              ? Icons.check_circle
              : status == 'Pending'
                  ? Icons.schedule
                  : Icons.error,
          color: status == 'Paid'
              ? Colors.green
              : status == 'Pending'
                  ? Colors.orange
                  : Colors.red,
        ),
      ),
      title: Text(
        currencyFormat.format(amount),
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      subtitle: Text('$tenantName • ${dateFormat.format(paymentDate)}'),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: status == 'Paid'
                  ? Colors.green.withValues(alpha: 0.1)
                  : status == 'Pending'
                      ? Colors.orange.withValues(alpha: 0.1)
                      : Colors.red.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              status,
              style: TextStyle(
                fontSize: 11,
                color: status == 'Paid'
                    ? Colors.green
                    : status == 'Pending'
                        ? Colors.orange
                        : Colors.red,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            paymentType,
            style: TextStyle(fontSize: 11, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }
}
