import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/owner_provider.dart';
import 'add_edit_owner_screen.dart';

class OwnerListScreen extends StatefulWidget {
  const OwnerListScreen({super.key});

  @override
  State<OwnerListScreen> createState() => _OwnerListScreenState();
}

class _OwnerListScreenState extends State<OwnerListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<OwnerProvider>().loadOwners();
    });
  }

  @override
  Widget build(BuildContext context) {
    final ownerProvider = context.watch<OwnerProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Owners'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AddEditOwnerScreen()),
            ),
          ),
        ],
      ),
      body: ownerProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : ownerProvider.owners.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.person_outline,
                          size: 64, color: Colors.grey[300]),
                      const SizedBox(height: 16),
                      Text('No owners yet',
                          style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 8),
                      ElevatedButton.icon(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const AddEditOwnerScreen()),
                        ),
                        icon: const Icon(Icons.add),
                        label: const Text('Add Owner'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: () => ownerProvider.loadOwners(),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: ownerProvider.owners.length,
                    itemBuilder: (context, index) {
                      final owner = ownerProvider.owners[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Theme.of(context)
                                .primaryColor
                                .withValues(alpha: 0.1),
                            child: Text(
                              owner.name.isNotEmpty
                                  ? owner.name[0].toUpperCase()
                                  : '?',
                              style: TextStyle(
                                color: Theme.of(context).primaryColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          title: Text(owner.name,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold)),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(owner.email),
                              Text(owner.phone),
                            ],
                          ),
                          trailing: PopupMenuButton<String>(
                            onSelected: (value) {
                              if (value == 'edit') {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => AddEditOwnerScreen(
                                        owner: owner),
                                  ),
                                );
                              }
                              if (value == 'delete') {
                                _confirmDelete(
                                    context, owner.id!, owner.name);
                              }
                            },
                            itemBuilder: (context) => [
                              const PopupMenuItem(
                                  value: 'edit', child: Text('Edit')),
                              const PopupMenuItem(
                                  value: 'delete',
                                  child: Text('Delete',
                                      style: TextStyle(color: Colors.red))),
                            ],
                          ),
                          isThreeLine: true,
                        ),
                      );
                    },
                  ),
                ),
    );
  }

  void _confirmDelete(
      BuildContext context, int ownerId, String ownerName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Owner'),
        content: Text('Are you sure you want to delete "$ownerName"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              context.read<OwnerProvider>().deleteOwner(ownerId);
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
