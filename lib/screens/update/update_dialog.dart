import 'package:flutter/material.dart';
import '../../models/update_info.dart';
import '../../services/update_service.dart';

class UpdateDialog extends StatefulWidget {
  final UpdateInfo info;
  const UpdateDialog({super.key, required this.info});

  static Future<void> show(BuildContext context, UpdateInfo info) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => UpdateDialog(info: info),
    );
  }

  @override
  State<UpdateDialog> createState() => _UpdateDialogState();
}

class _UpdateDialogState extends State<UpdateDialog> {
  final _service = UpdateService.instance;
  bool _downloading = false;
  double _progress = 0;
  String _status = '';

  Future<void> _startDownload() async {
    setState(() {
      _downloading = true;
      _status = 'Downloading...';
    });

    final path = await _service.downloadApk(
      widget.info.downloadUrl,
      onProgress: (received, total) {
        if (!mounted) return;
        setState(() {
          _progress = total > 0 ? received / total : 0;
          _status = '${(received / 1024 / 1024).toStringAsFixed(1)} MB / '
              '${(total / 1024 / 1024).toStringAsFixed(1)} MB';
        });
      },
    );

    if (!mounted) return;

    if (path == null) {
      setState(() {
        _status = 'Download failed';
        _downloading = false;
      });
      return;
    }

    setState(() => _status = 'Installing...');
    await _service.installApk(path);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Icon(
            _downloading ? Icons.download : Icons.system_update,
            color: Colors.blue,
          ),
          const SizedBox(width: 8),
          Text(_downloading ? 'Downloading' : 'Update Available'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!_downloading) ...[
            Text('Version ${widget.info.version} is available.'),
            if (widget.info.changelog.isNotEmpty) ...[
              const SizedBox(height: 8),
              const Text('What\'s new:',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(widget.info.changelog),
            ],
          ],
          if (_downloading) ...[
            LinearProgressIndicator(value: _progress),
            const SizedBox(height: 8),
            Text(_status),
          ],
        ],
      ),
      actions: [
        if (!_downloading)
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Later'),
          ),
        if (!_downloading)
          FilledButton.icon(
            onPressed: _startDownload,
            icon: const Icon(Icons.download),
            label: const Text('Update'),
          ),
        if (_status == 'Download failed')
          FilledButton.icon(
            onPressed: _startDownload,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
      ],
    );
  }
}
