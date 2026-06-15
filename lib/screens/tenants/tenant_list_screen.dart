import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/tenant_provider.dart';
import '../../widgets/tenant_card.dart';
import 'tenant_detail_screen.dart';
import 'add_edit_tenant_screen.dart';

class TenantListScreen extends StatefulWidget {
  const TenantListScreen({super.key});

  @override
  State<TenantListScreen> createState() => _TenantListScreenState();
}

class _TenantListScreenState extends State<TenantListScreen> {
  final _searchController = TextEditingController();
  List<dynamic> _searchResults = [];
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TenantProvider>().loadTenants();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tenantProvider = context.watch<TenantProvider>();

    return Scaffold(
      appBar: AppBar(
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'Search tenants...',
                  border: InputBorder.none,
                ),
                onChanged: (value) async {
                  if (value.isNotEmpty) {
                    final results =
                        await tenantProvider.searchTenants(value);
                    setState(() => _searchResults = results);
                  } else {
                    setState(() => _searchResults = []);
                  }
                },
              )
            : const Text('Tenants'),
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                _isSearching = !_isSearching;
                if (!_isSearching) {
                  _searchController.clear();
                  _searchResults = [];
                }
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddTenant(context),
          ),
        ],
      ),
      body: tenantProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : _isSearching
              ? _buildSearchResults(tenantProvider)
              : _buildTenantList(tenantProvider),
    );
  }

  Widget _buildSearchResults(TenantProvider provider) {
    if (_searchResults.isEmpty && _searchController.text.isNotEmpty) {
      return const Center(child: Text('No tenants found'));
    }
    final results =
        _searchResults.isNotEmpty ? _searchResults : provider.tenants;
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: results.length,
      itemBuilder: (context, index) {
        final tenant = results[index];
        return TenantCard(
          tenant: tenant,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  TenantDetailScreen(tenantId: tenant.id!),
            ),
          ),
          onEdit: () => _showEditTenant(context, tenant),
          onDelete: () => _confirmDelete(context, tenant.id!, tenant.name),
        );
      },
    );
  }

  Widget _buildTenantList(TenantProvider provider) {
    if (provider.tenants.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text('No tenants yet',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: () => _showAddTenant(context),
              icon: const Icon(Icons.add),
              label: const Text('Add Tenant'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => provider.loadTenants(),
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: provider.tenants.length,
        itemBuilder: (context, index) {
          final tenant = provider.tenants[index];
          return Dismissible(
            key: ValueKey(tenant.id),
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
            confirmDismiss: (direction) async {
              HapticFeedback.mediumImpact();
              return await _confirmDelete(
                  context, tenant.id!, tenant.name);
            },
            child: TenantCard(
              tenant: tenant,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      TenantDetailScreen(tenantId: tenant.id!),
                ),
              ),
              onEdit: () => _showEditTenant(context, tenant),
              onDelete: () =>
                  _confirmDelete(context, tenant.id!, tenant.name),
            ),
          );
        },
      ),
    );
  }

  void _showAddTenant(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AddEditTenantScreen()),
    );
  }

  void _showEditTenant(BuildContext context, dynamic tenant) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddEditTenantScreen(tenant: tenant),
      ),
    );
  }

  Future<bool?> _confirmDelete(
      BuildContext context, int tenantId, String tenantName) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Tenant'),
        content: Text('Are you sure you want to delete "$tenantName"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              context.read<TenantProvider>().deleteTenant(tenantId);
              Navigator.pop(context, true);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
