import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../providers/inspection_provider.dart';
import '../../providers/property_provider.dart';
import '../../models/inspection.dart';
import '../../services/file_manager_service.dart';

class AddInspectionScreen extends StatefulWidget {
  final int? propertyId;
  final int? unitId;
  const AddInspectionScreen({super.key, this.propertyId, this.unitId});

  @override
  State<AddInspectionScreen> createState() => _AddInspectionScreenState();
}

class _AddInspectionScreenState extends State<AddInspectionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _notesController = TextEditingController();
  String _type = 'Move-in';
  String _overallCondition = 'Good';
  int? _propertyId;
  int? _unitId;

  final _rooms = [
    'Living Room', 'Kitchen', 'Bedroom 1', 'Bedroom 2', 'Bedroom 3',
    'Bathroom 1', 'Bathroom 2', 'Hallway', 'Garage', 'Laundry', 'Dining Room',
    'Garden/Yard', 'Roof', 'Basement'
  ];

  final _conditions = ['Excellent', 'Good', 'Fair', 'Poor'];
  final _types = ['Move-in', 'Move-out', 'Periodic', 'Annual', 'Emergency'];

  final List<Map<String, dynamic>> _roomItems = [];
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _propertyId = widget.propertyId;
    _unitId = widget.unitId;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PropertyProvider>().loadProperties();
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final properties = context.watch<PropertyProvider>().properties;

    return Scaffold(
      appBar: AppBar(title: const Text('New Inspection')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Inspection Title',
                border: OutlineInputBorder(),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _type,
              decoration: const InputDecoration(
                labelText: 'Type',
                border: OutlineInputBorder(),
              ),
              items: _types
                  .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                  .toList(),
              onChanged: (v) => setState(() => _type = v!),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<int>(
              value: _propertyId,
              decoration: const InputDecoration(
                labelText: 'Property',
                border: OutlineInputBorder(),
              ),
              items: properties
                  .map((p) =>
                      DropdownMenuItem(value: p.id, child: Text(p.name)))
                  .toList(),
              onChanged: (v) => setState(() => _propertyId = v),
              validator: (v) => v == null ? 'Select property' : null,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _overallCondition,
              decoration: const InputDecoration(
                labelText: 'Overall Condition',
                border: OutlineInputBorder(),
              ),
              items: _conditions
                  .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                  .toList(),
              onChanged: (v) => setState(() => _overallCondition = v!),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Notes',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 20),
            Text('Room-by-Room Inspection',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ..._roomItems.asMap().entries.map((entry) {
              final idx = entry.key;
              final item = entry.value;
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(item['room'],
                                style:
                                    const TextStyle(fontWeight: FontWeight.w600)),
                          ),
                          _buildConditionChip(item['condition']),
                          IconButton(
                            icon: const Icon(Icons.close, size: 18),
                            onPressed: () =>
                                setState(() => _roomItems.removeAt(idx)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: _conditions
                            .map((c) => ChoiceChip(
                                  label: Text(c, style: const TextStyle(fontSize: 11)),
                                  selected: item['condition'] == c,
                                  onSelected: (_) {
                                    setState(() => item['condition'] = c);
                                  },
                                ))
                            .toList(),
                      ),
                      if (item['photo_path'] != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Row(
                            children: [
                              const Icon(Icons.check_circle,
                                  size: 16, color: Colors.green),
                              const SizedBox(width: 4),
                              const Text('Photo attached',
                                  style: TextStyle(fontSize: 12)),
                              TextButton(
                                onPressed: () => setState(
                                    () => item['photo_path'] = null),
                                child: const Text('Remove',
                                    style: TextStyle(fontSize: 12)),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              );
            }),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () => _addRoom(context),
              icon: const Icon(Icons.add),
              label: const Text('Add Room'),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _save,
              icon: const Icon(Icons.save),
              label: const Text('Save Inspection'),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildConditionChip(String condition) {
    final color = switch (condition) {
      'Excellent' => Colors.green,
      'Good' => Colors.blue,
      'Fair' => Colors.orange,
      'Poor' => Colors.red,
      _ => Colors.grey,
    };
    return Chip(
      label: Text(condition, style: const TextStyle(fontSize: 10)),
      backgroundColor: color.withValues(alpha: 0.1),
      side: BorderSide.none,
      visualDensity: VisualDensity.compact,
      padding: EdgeInsets.zero,
    );
  }

  Future<void> _addRoom(BuildContext context) async {
    final room = await showDialog<String>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('Select Room'),
        children: _rooms
            .map((r) => SimpleDialogOption(
                  onPressed: () => Navigator.pop(ctx, r),
                  child: Text(r),
                ))
            .toList(),
      ),
    );
    if (room != null && mounted) {
      final photo = await _picker.pickImage(source: ImageSource.camera);
      String? photoPath;
      if (photo != null) {
        photoPath = await FileManagerService.instance.saveFile(photo.path,
            subfolder: 'inspections');
      }
      setState(() {
        _roomItems.add({
          'room': room,
          'condition': 'Good',
          'photo_path': photoPath,
        });
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final inspectionId = await context.read<InspectionProvider>().addInspection(
          Inspection(
            propertyId: _propertyId!,
            unitId: _unitId,
            title: _titleController.text.trim(),
            type: _type,
            overallCondition: _overallCondition,
            notes: _notesController.text.trim(),
          ),
        );

    for (final item in _roomItems) {
      await context.read<InspectionProvider>().addInspectionItem(
            InspectionItem(
              inspectionId: inspectionId,
              roomName: item['room'],
              condition: item['condition'],
              photoPath: item['photo_path'],
            ),
          );
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Inspection saved')),
      );
      Navigator.pop(context);
    }
  }
}
