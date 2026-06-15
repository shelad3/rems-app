import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../providers/auth_provider.dart';
import '../../services/firestore_service.dart';
import '../profile/profile_screen.dart';
import '../tenant/discovery_screen.dart';
import '../payments/add_payment_screen.dart';
import '../payments/payment_placeholder_screen.dart';
import '../maintenance/add_maintenance_screen.dart';
import '../chat/chat_screen.dart';

class TenantShell extends StatefulWidget {
  const TenantShell({super.key});

  @override
  State<TenantShell> createState() => _TenantShellState();
}

class _TenantShellState extends State<TenantShell> {
  int _currentIndex = 0;
  final _firestore = FirestoreService.instance;
  final _fmt = NumberFormat.currency(symbol: 'KES ');

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final auth = context.watch<AuthProvider>();
    final uid = auth.user?.uid ?? '';

    final screens = [
      const TenantDiscoveryScreen(),
      _buildMyApplicationsTab(colorScheme),
      PaymentPlaceholderScreen(tenantId: uid),
      _buildMyLeaseTab(colorScheme),
      const ProfileScreen(),
    ];

    final labels = const ['Discover', 'My Apps', 'Payments', 'My Lease', 'Profile'];
    final icons = const [
      Icons.search_outlined,
      Icons.pending_actions_outlined,
      Icons.payments_outlined,
      Icons.description_outlined,
      Icons.person_outline,
    ];
    final activeIcons = const [
      Icons.search,
      Icons.pending_actions,
      Icons.payments,
      Icons.description,
      Icons.person,
    ];

    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: screens),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) {
          setState(() => _currentIndex = i);
          HapticFeedback.selectionClick();
        },
        destinations: List.generate(5, (i) => NavigationDestination(
          icon: Icon(icons[i]),
          selectedIcon: Icon(activeIcons[i]),
          label: labels[i],
        )),
      ),
    );
  }

  Future<void> _acceptCounter(DocumentSnapshot doc) async {
    final data = doc.data() as Map<String, dynamic>;
    final unitId = data['unitId'] as String;
    final rent = (data['caretakerCounterRent'] as num?)?.toDouble() ?? 0;
    final deposit = (data['caretakerCounterDeposit'] as num?)?.toDouble() ?? 0;

    await _firestore.updateApplication(doc.id, {
      'status': 'accepted',
      'reviewedAt': DateTime.now().toIso8601String(),
    });
    await _firestore.updateUnit(unitId, {'status': 'occupied'});
    await _firestore.addLease({
      'unitId': unitId,
      'tenantId': data['tenantId'] as String,
      'rentAmount': rent,
      'deposit': deposit,
      'startDate': DateTime.now().toIso8601String(),
      'isActive': true,
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Offer accepted! Your lease is active.')),
      );
    }
  }

  Widget _buildMyApplicationsTab(ColorScheme colors) {
    final auth = context.watch<AuthProvider>();
    final uid = auth.user?.uid ?? '';
    return Scaffold(
      appBar: AppBar(title: const Text('My Applications')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirestoreService.instance.tenantApplicationsStream(uid),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final apps = snapshot.data!.docs;
          if (apps.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.pending_actions_outlined, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text('No applications yet',
                      style: TextStyle(color: Colors.grey[600], fontSize: 16)),
                  const SizedBox(height: 8),
                  Text('Browse available units and apply!',
                      style: TextStyle(color: Colors.grey[500], fontSize: 13)),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: apps.length,
            itemBuilder: (_, i) {
              final d = apps[i];
              final data = d.data() as Map<String, dynamic>;
              final status = data['status'] as String? ?? 'pending';

              Color statusColor;
              IconData statusIcon;
              switch (status) {
                case 'approved':
                  statusColor = Colors.green;
                  statusIcon = Icons.check_circle;
                case 'rejected':
                case 'declined':
                  statusColor = Colors.red;
                  statusIcon = Icons.cancel;
                case 'countered':
                  statusColor = Colors.purple;
                  statusIcon = Icons.swap_horiz;
                case 'accepted':
                  statusColor = Colors.blue;
                  statusIcon = Icons.verified;
                default:
                  statusColor = Colors.orange;
                  statusIcon = Icons.schedule;
              }

              final proposedRent = (data['proposedRent'] as num?)?.toDouble() ?? 0;
              final counterRent = (data['caretakerCounterRent'] as num?)?.toDouble();
              final isCountered = status == 'countered';

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(statusIcon, color: statusColor, size: 28),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Unit ${data['unitId'] ?? ''}',
                                    style: const TextStyle(fontWeight: FontWeight.bold)),
                                const SizedBox(height: 2),
                                Text('${_fmt.format(proposedRent)}/mo',
                                    style: TextStyle(fontSize: 13, color: Colors.grey[600])),
                              ],
                            ),
                          ),
                          Chip(
                            label: Text(status, style: TextStyle(fontSize: 11, color: statusColor)),
                            backgroundColor: statusColor.withValues(alpha: 0.1),
                          ),
                        ],
                      ),
                      if (isCountered && counterRent != null) ...[
                        const Divider(height: 20),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.purple.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.swap_horiz, size: 16, color: Colors.purple[700]),
                                  const SizedBox(width: 4),
                                  Text('Counter Offer from Manager',
                                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.purple[700])),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text('Rent: ${_fmt.format(counterRent)}/mo',
                                  style: const TextStyle(fontSize: 13)),
                              if (data['caretakerCounterDeposit'] != null)
                                Text('Deposit: ${_fmt.format((data['caretakerCounterDeposit'] as num).toDouble())}',
                                    style: const TextStyle(fontSize: 13)),
                              if (data['caretakerNotes'] != null && (data['caretakerNotes'] as String).isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text('"${data['caretakerNotes']}"',
                                      style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: Colors.grey[700])),
                                ),
                              const SizedBox(height: 12),
                              Row(children: [
                                Expanded(
                                  child: FilledButton.icon(
                                    onPressed: () => _acceptCounter(d),
                                    icon: const Icon(Icons.check, size: 16),
                                    label: const Text('Accept'),
                                    style: FilledButton.styleFrom(backgroundColor: Colors.green),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: () async {
                                      await _firestore.updateApplication(d.id, {'status': 'declined'});
                                    },
                                    icon: const Icon(Icons.close, size: 16),
                                    label: const Text('Decline'),
                                    style: OutlinedButton.styleFrom(
                                        foregroundColor: Colors.red, side: const BorderSide(color: Colors.red)),
                                  ),
                                ),
                              ]),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildMyLeaseTab(ColorScheme colors) {
    final auth = context.watch<AuthProvider>();
    final uid = auth.user?.uid ?? '';

    return Scaffold(
      appBar: AppBar(title: const Text('My Lease')),
      body: FutureBuilder<Map<String, dynamic>?>(
        future: FirestoreService.instance.getLeaseByTenant(uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final lease = snapshot.data;

          if (lease == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.description_outlined, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text('No active lease',
                      style: TextStyle(color: Colors.grey[600], fontSize: 16)),
                  const SizedBox(height: 8),
                  Text('Once your application is approved,\nyour lease will appear here.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey[500], fontSize: 13)),
                ],
              ),
            );
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.description, size: 20),
                          const SizedBox(width: 8),
                          Text('Active Lease',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                          const Spacer(),
                          Chip(
                            label: const Text('Active', style: TextStyle(fontSize: 11)),
                            backgroundColor: Colors.green.withValues(alpha: 0.1),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _detailRow('Unit', lease['unitId'] ?? ''),
                      _detailRow('Rent', _fmt.format(lease['rentAmount'] ?? 0)),
                      if (lease['deposit'] != null)
                        _detailRow('Deposit', _fmt.format(lease['deposit'] as num)),
                      if (lease['startDate'] != null)
                        _detailRow('Start', lease['startDate'] as String),
                      if (lease['endDate'] != null)
                        _detailRow('End', lease['endDate'] as String),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton.icon(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AddPaymentScreen(preSelectedTenantId: auth.user?.tenantId),
                    ),
                  ),
                  icon: const Icon(Icons.payments),
                  label: const Text('Pay Rent'),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton.tonalIcon(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AddMaintenanceScreen()),
                  ),
                  icon: const Icon(Icons.build),
                  label: const Text('Report Issue'),
                ),
              ),
              StreamBuilder<QuerySnapshot>(
                stream: FirestoreService.instance.tenantMaintenanceStream(uid),
                builder: (context, snap) {
                  if (!snap.hasData || snap.data!.docs.isEmpty) {
                    return const SizedBox.shrink();
                  }
                  final tickets = snap.data!.docs;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 24),
                      Text('Recent Tickets',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      ...tickets.take(3).map((d) {
                        final dt = d.data() as Map<String, dynamic>;
                        return ListTile(
                          dense: true,
                          leading: Icon(
                            dt['status'] == 'resolved' ? Icons.check_circle : Icons.build,
                            color: dt['status'] == 'resolved' ? Colors.green : Colors.orange,
                            size: 20,
                          ),
                          title: Text(dt['issue'] as String? ?? '', style: const TextStyle(fontSize: 13)),
                          subtitle: Text('Status: ${dt['status']}', style: const TextStyle(fontSize: 11)),
                        );
                      }),
                    ],
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(children: [
        SizedBox(width: 80, child: Text(label,
            style: const TextStyle(fontWeight: FontWeight.w500, color: Colors.grey))),
        Expanded(child: Text(value)),
      ]),
    );
  }
}
