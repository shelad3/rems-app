import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/payment.dart';
import '../../providers/payment_provider.dart';
import '../../providers/tenant_provider.dart';
import '../../providers/lease_provider.dart';

class AddPaymentScreen extends StatefulWidget {
  final int? preSelectedTenantId;

  const AddPaymentScreen({super.key, this.preSelectedTenantId});

  @override
  State<AddPaymentScreen> createState() => _AddPaymentScreenState();
}

class _AddPaymentScreenState extends State<AddPaymentScreen> {
  final _formKey = GlobalKey<FormState>();
  int? _selectedTenantId;
  int? _selectedLeaseId;
  late TextEditingController _amountController;
  late TextEditingController _notesController;
  String _paymentType = 'Rent';
  String _status = 'Paid';
  DateTime _paymentDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController();
    _notesController = TextEditingController();
    _selectedTenantId = widget.preSelectedTenantId;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TenantProvider>().loadTenants();
      context.read<LeaseProvider>().loadLeases();
    });
  }

  @override
  void dispose() {
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tenantProvider = context.watch<TenantProvider>();
    final leaseProvider = context.watch<LeaseProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Record Payment')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            DropdownButtonFormField<int>(
              value: _selectedTenantId,
              decoration: const InputDecoration(
                labelText: 'Tenant',
                prefixIcon: Icon(Icons.person),
                border: OutlineInputBorder(),
              ),
              items: tenantProvider.tenants.map((t) {
                return DropdownMenuItem(value: t.id, child: Text(t.name));
              }).toList(),
              onChanged: (v) {
                setState(() {
                  _selectedTenantId = v;
                  _selectedLeaseId = null;
                });
              },
              validator: (v) => v == null ? 'Select a tenant' : null,
            ),
            if (_selectedTenantId != null) ...[
              const SizedBox(height: 16),
              DropdownButtonFormField<int>(
                value: _selectedLeaseId,
                decoration: const InputDecoration(
                  labelText: 'Lease',
                  prefixIcon: Icon(Icons.description),
                  border: OutlineInputBorder(),
                ),
                items: leaseProvider
                    .getLeasesByTenant(_selectedTenantId!)
                    .map((l) {
                  return DropdownMenuItem(
                      value: l.id,
                      child: Text(
                          'Lease #${l.id} - \$${l.rentAmount.toStringAsFixed(0)}/mo'));
                }).toList(),
                onChanged: (v) => setState(() => _selectedLeaseId = v),
                validator: (v) => v == null ? 'Select a lease' : null,
              ),
            ],
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _paymentType,
              decoration: const InputDecoration(
                labelText: 'Payment Type',
                prefixIcon: Icon(Icons.category),
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'Rent', child: Text('Rent')),
                DropdownMenuItem(
                    value: 'Security Deposit',
                    child: Text('Security Deposit')),
                DropdownMenuItem(value: 'Late Fee', child: Text('Late Fee')),
                DropdownMenuItem(
                    value: 'Other', child: Text('Other')),
              ],
              onChanged: (v) => setState(() => _paymentType = v!),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _amountController,
              decoration: const InputDecoration(
                labelText: 'Amount (\$)',
                prefixIcon: Icon(Icons.attach_money),
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              validator: (v) =>
                  v?.isEmpty ?? true ? 'Enter amount' : null,
            ),
            const SizedBox(height: 16),
            InkWell(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _paymentDate,
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now(),
                );
                if (picked != null) {
                  setState(() => _paymentDate = picked);
                }
              },
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Payment Date',
                  prefixIcon: Icon(Icons.calendar_today),
                  border: OutlineInputBorder(),
                ),
                child: Text(
                  DateFormat('MMM dd, yyyy').format(_paymentDate),
                ),
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _status,
              decoration: const InputDecoration(
                labelText: 'Status',
                prefixIcon: Icon(Icons.info),
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'Paid', child: Text('Paid')),
                DropdownMenuItem(
                    value: 'Pending', child: Text('Pending')),
                DropdownMenuItem(
                    value: 'Overdue', child: Text('Overdue')),
              ],
              onChanged: (v) => setState(() => _status = v!),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Notes',
                prefixIcon: Icon(Icons.notes),
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _savePayment,
              icon: const Icon(Icons.payment),
              label: const Text('Record Payment'),
              style: FilledButton.styleFrom(padding: const EdgeInsets.all(16)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _savePayment() async {
    if (!_formKey.currentState!.validate()) return;

    final payment = Payment(
      leaseId: _selectedLeaseId!,
      tenantId: _selectedTenantId!,
      amount: double.tryParse(_amountController.text) ?? 0,
      paymentDate: _paymentDate,
      paymentType: _paymentType,
      status: _status,
      notes: _notesController.text.trim(),
    );

    await context.read<PaymentProvider>().addPayment(payment);
    if (mounted) Navigator.pop(context);
  }
}
