import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/firestore_service.dart';
import '../profile/profile_screen.dart';

class OwnerShell extends StatefulWidget {
  const OwnerShell({super.key});

  @override
  State<OwnerShell> createState() => _OwnerShellState();
}

class _OwnerShellState extends State<OwnerShell> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _buildDashboard(colorScheme),
          _buildPropertiesList(colorScheme),
          _buildRevenueChart(colorScheme),
          const ProfileScreen(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) {
          setState(() => _currentIndex = i);
          HapticFeedback.selectionClick();
        },
        destinations: const [
          NavigationDestination(
              icon: Icon(Icons.dashboard_outlined),
              selectedIcon: Icon(Icons.dashboard),
              label: 'Overview'),
          NavigationDestination(
              icon: Icon(Icons.business_outlined),
              selectedIcon: Icon(Icons.business),
              label: 'Properties'),
          NavigationDestination(
              icon: Icon(Icons.bar_chart_outlined),
              selectedIcon: Icon(Icons.bar_chart),
              label: 'Revenue'),
          NavigationDestination(
              icon: Icon(Icons.person_outline),
              selectedIcon: Icon(Icons.person),
              label: 'Profile'),
        ],
      ),
    );
  }

  Widget _buildDashboard(ColorScheme colors) {
    final firestore = FirestoreService.instance;

    return Scaffold(
      appBar: AppBar(title: const Text('My Portfolio')),
      body: StreamBuilder<QuerySnapshot>(
        stream: firestore.allUnitsStream(),
        builder: (context, snap) {
          final total = snap.data?.docs.length ?? 0;
          final occupied = snap.data?.docs
                  .where((d) =>
                      (d.data() as Map<String, dynamic>)['status'] == 'occupied')
                  .length ??
              0;
          final vacant = total - occupied;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _stat(Icons.business, 'Total', total.toString(),
                              colors.primary),
                          _stat(Icons.check_circle, 'Occupied',
                              occupied.toString(), Colors.green),
                          _stat(Icons.home_outlined, 'Vacant',
                              vacant.toString(), Colors.orange),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text('Occupancy Overview',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: LinearProgressIndicator(
                  value: total > 0 ? occupied / total : 0,
                  minHeight: 24,
                  backgroundColor: Colors.orange.withValues(alpha: 0.2),
                  valueColor: const AlwaysStoppedAnimation(Colors.green),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('$occupied occupied',
                      style: const TextStyle(
                          fontSize: 12, color: Colors.green)),
                  Text('$vacant vacant',
                      style:
                          const TextStyle(fontSize: 12, color: Colors.orange)),
                ],
              ),
              const SizedBox(height: 24),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.info_outline),
                  title: const Text('Read-Only Dashboard'),
                  subtitle: const Text(
                      'Contact your landlord for changes or full reports.'),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildPropertiesList(ColorScheme colors) {
    final firestore = FirestoreService.instance;
    return Scaffold(
      appBar: AppBar(title: const Text('My Properties')),
      body: StreamBuilder<QuerySnapshot>(
        stream: firestore.propertiesStream(),
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final props = snap.data!.docs;
          if (props.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.business_outlined,
                      size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text('No properties yet',
                      style: TextStyle(color: Colors.grey[600], fontSize: 16)),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: props.length,
            itemBuilder: (_, i) {
              final d = props[i];
              final data = d.data() as Map<String, dynamic>;
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: const Icon(Icons.business),
                  title: Text(data['name'] as String? ?? '',
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(data['location'] as String? ?? '',
                      style: const TextStyle(fontSize: 12)),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildRevenueChart(ColorScheme colors) {
    return Scaffold(
      appBar: AppBar(title: const Text('Revenue')),
      body: const Center(
        child: Card(
          margin: EdgeInsets.all(16),
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.bar_chart, size: 48, color: Colors.grey),
                SizedBox(height: 16),
                Text('Revenue charts coming soon',
                    style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold)),
                SizedBox(height: 8),
                Text(
                  'Connect with your landlord for detailed\nfinancial reports and revenue breakdowns.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey, fontSize: 13),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _stat(IconData icon, String label, String value, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 4),
        Text(value,
            style: TextStyle(
                fontSize: 28, fontWeight: FontWeight.bold, color: color)),
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
      ],
    );
  }
}
