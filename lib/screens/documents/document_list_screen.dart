import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/document_provider.dart';
import '../../models/document.dart';
import 'add_document_screen.dart';

class DocumentListScreen extends StatefulWidget {
  final int? propertyId;
  final int? unitId;
  final int? tenantId;
  final String? appBarTitle;

  const DocumentListScreen({
    super.key,
    this.propertyId,
    this.unitId,
    this.tenantId,
    this.appBarTitle,
  });

  @override
  State<DocumentListScreen> createState() => _DocumentListScreenState();
}

class _DocumentListScreenState extends State<DocumentListScreen> {
  String _selectedCategory = 'All';
  final _categories = ['All', 'Lease', 'ID', 'Inspection', 'Receipt', 'Contract', 'Notice', 'Other'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DocumentProvider>().loadDocuments(
        propertyId: widget.propertyId,
        unitId: widget.unitId,
        tenantId: widget.tenantId,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DocumentProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.appBarTitle ?? 'Documents'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AddDocumentScreen(
                    propertyId: widget.propertyId,
                    unitId: widget.unitId,
                    tenantId: widget.tenantId,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          _buildCategoryFilter(),
          Expanded(
            child: provider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : _buildDocumentList(provider),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryFilter() {
    return SizedBox(
      height: 48,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        children: _categories.map((cat) {
          final selected = _selectedCategory == cat;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: FilterChip(
              label: Text(cat),
              selected: selected,
              onSelected: (_) => setState(() => _selectedCategory = cat),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildDocumentList(DocumentProvider provider) {
    final docs = _selectedCategory == 'All'
        ? provider.documents
        : provider.getDocumentsByCategory(_selectedCategory);

    if (docs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.description, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text('No documents yet',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AddDocumentScreen(
                    propertyId: widget.propertyId,
                    unitId: widget.unitId,
                    tenantId: widget.tenantId,
                  ),
                ),
              ),
              icon: const Icon(Icons.add),
              label: const Text('Upload Document'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => provider.loadDocuments(
        propertyId: widget.propertyId,
        unitId: widget.unitId,
        tenantId: widget.tenantId,
      ),
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: docs.length,
        itemBuilder: (context, index) {
          final doc = docs[index];
          final icon = _getIconForCategory(doc.category);
          return Dismissible(
            key: ValueKey(doc.id),
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
            confirmDismiss: (_) async {
              HapticFeedback.mediumImpact();
              final ok = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Delete Document'),
                  content: Text('Delete "${doc.name}"?'),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text('Cancel')),
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      style: TextButton.styleFrom(foregroundColor: Colors.red),
                      child: const Text('Delete'),
                    ),
                  ],
                ),
              );
              if (ok == true) provider.deleteDocument(doc.id!);
              return false;
            },
            child: Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: icon.color.withValues(alpha: 0.1),
                  child: Icon(icon.icon, color: icon.color, size: 20),
                ),
                title: Text(doc.name,
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                subtitle: Text(
                  '${doc.category} \u2022 ${DateFormat.yMMMd().format(doc.createdAt)}',
                  style: const TextStyle(fontSize: 12),
                ),
                trailing: const Icon(Icons.open_in_new, size: 18),
                onTap: () => _showDocumentDetails(doc),
              ),
            ),
          );
        },
      ),
    );
  }

  _IconInfo _getIconForCategory(String category) {
    switch (category) {
      case 'Lease':
        return _IconInfo(Icons.description, Colors.blue);
      case 'ID':
        return _IconInfo(Icons.badge, Colors.purple);
      case 'Inspection':
        return _IconInfo(Icons.search, Colors.teal);
      case 'Receipt':
        return _IconInfo(Icons.receipt, Colors.green);
      case 'Contract':
        return _IconInfo(Icons.article, Colors.indigo);
      case 'Notice':
        return _IconInfo(Icons.campaign, Colors.orange);
      default:
        return _IconInfo(Icons.insert_drive_file, Colors.grey);
    }
  }

  void _showDocumentDetails(Document doc) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(doc.name,
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            _detailRow(Icons.category, 'Category', doc.category),
            _detailRow(Icons.calendar_today, 'Uploaded',
                DateFormat.yMMMd().format(doc.createdAt)),
            if (doc.notes.isNotEmpty) ...[
              const SizedBox(height: 8),
              _detailRow(Icons.notes, 'Notes', doc.notes),
            ],
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('File: ${doc.filePath}')),
                  );
                },
                icon: const Icon(Icons.open_in_new),
                label: const Text('Open File'),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey),
          const SizedBox(width: 8),
          Text('$label: ',
              style: const TextStyle(
                  fontWeight: FontWeight.w500, color: Colors.grey)),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}

class _IconInfo {
  final IconData icon;
  final Color color;
  _IconInfo(this.icon, this.color);
}
