import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/property_provider.dart';

import '../../widgets/property_card.dart';
import 'property_detail_screen.dart';
import 'add_edit_property_screen.dart';

class PropertyListScreen extends StatefulWidget {
  const PropertyListScreen({super.key});

  @override
  State<PropertyListScreen> createState() => _PropertyListScreenState();
}

class _PropertyListScreenState extends State<PropertyListScreen> {
  final _searchController = TextEditingController();
  List<dynamic> _searchResults = [];
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PropertyProvider>().loadProperties();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final propertyProvider = context.watch<PropertyProvider>();

    return Scaffold(
      appBar: AppBar(
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'Search properties...',
                  border: InputBorder.none,
                ),
                onChanged: (value) async {
                  if (value.isNotEmpty) {
                    final results =
                        await propertyProvider.searchProperties(value);
                    setState(() => _searchResults = results);
                  } else {
                    setState(() => _searchResults = []);
                  }
                },
              )
            : const Text('Properties'),
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
            onPressed: () => _showAddProperty(context),
          ),
        ],
      ),
      body: propertyProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : _isSearching
              ? _buildSearchResults(propertyProvider)
              : _buildPropertyList(propertyProvider),
    );
  }

  Widget _buildSearchResults(PropertyProvider provider) {
    if (_searchResults.isEmpty && _searchController.text.isNotEmpty) {
      return const Center(child: Text('No properties found'));
    }
    final results = _searchResults.isNotEmpty
        ? _searchResults
        : provider.properties;
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: results.length,
      itemBuilder: (context, index) {
        final property = results[index];
        return PropertyCard(
          property: property,
          ownerName: provider.getOwnerName(property.ownerId),
          occupiedUnits: provider.getOccupiedUnits(property.id!),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => PropertyDetailScreen(propertyId: property.id!),
            ),
          ),
          onEdit: () => _showEditProperty(context, property),
          onDelete: () => _confirmDelete(context, property.id!, property.name),
        );
      },
    );
  }

  Widget _buildPropertyList(PropertyProvider provider) {
    if (provider.properties.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.business, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              'No properties yet',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: () => _showAddProperty(context),
              icon: const Icon(Icons.add),
              label: const Text('Add Property'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => provider.loadProperties(),
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: provider.properties.length,
        itemBuilder: (context, index) {
          final property = provider.properties[index];
          return Dismissible(
            key: ValueKey(property.id),
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
                  context, property.id!, property.name);
            },
            child: PropertyCard(
              property: property,
              ownerName: provider.getOwnerName(property.ownerId),
              occupiedUnits: provider.getOccupiedUnits(property.id!),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      PropertyDetailScreen(propertyId: property.id!),
                ),
              ),
              onEdit: () => _showEditProperty(context, property),
              onDelete: () =>
                  _confirmDelete(context, property.id!, property.name),
            ),
          );
        },
      ),
    );
  }

  void _showAddProperty(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AddEditPropertyScreen()),
    );
  }

  void _showEditProperty(BuildContext context, dynamic property) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddEditPropertyScreen(property: property),
      ),
    );
  }

  Future<bool?> _confirmDelete(
      BuildContext context, int propertyId, String propertyName) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Property'),
        content: Text('Are you sure you want to delete "$propertyName"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              context.read<PropertyProvider>().deleteProperty(propertyId);
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
