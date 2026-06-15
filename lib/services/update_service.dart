import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:path_provider/path_provider.dart';

class UpdateService {
  static final UpdateService instance = UpdateService._init();
  UpdateService._init();

  static const String _githubOwner = 'shelad3';
  static const String _githubRepo = 'rems';
  static const String _githubApiUrl =
      'https://api.github.com/repos/$_githubOwner/$_githubRepo/releases/latest';
  static const String _githubReleasesUrl =
      'https://github.com/$_githubOwner/$_githubRepo/releases';

  String? _latestVersion;
  String? _downloadUrl;
  String? _releaseNotes;

  String get latestVersion => _latestVersion ?? 'unknown';
  String? get downloadUrl => _downloadUrl;

  Future<PackageInfo> get _packageInfo => PackageInfo.fromPlatform();

  Future<bool> checkForUpdate() async {
    try {
      final info = await _packageInfo;
      final currentVersion = info.version;

      final response = await http.get(
        Uri.parse(_githubApiUrl),
        headers: {'Accept': 'application/vnd.github.v3+json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final tagName = data['tag_name'] as String? ?? '';
        _latestVersion = tagName.replaceAll('v', '');
        _downloadUrl = data['assets'] != null && (data['assets'] as List).isNotEmpty
            ? (data['assets'] as List).first['browser_download_url'] as String?
            : null;
        _releaseNotes = data['body'] as String?;

        if (_latestVersion != null) {
          return _isNewerVersion(_latestVersion!, currentVersion);
        }
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  bool _isNewerVersion(String remote, String current) {
    final remoteParts = remote.split('.').map((e) => int.tryParse(e) ?? 0).toList();
    final currentParts = current.split('.').map((e) => int.tryParse(e) ?? 0).toList();

    for (int i = 0; i < remoteParts.length && i < currentParts.length; i++) {
      if (remoteParts[i] > currentParts[i]) return true;
      if (remoteParts[i] < currentParts[i]) return false;
    }
    return remoteParts.length > currentParts.length;
  }

  Future<void> checkForUpdates(BuildContext context) async {
    final hasUpdate = await checkForUpdate();

    if (!context.mounted) return;

    if (hasUpdate && _latestVersion != null) {
      _showUpdateDialog(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You are on the latest version')),
      );
    }
  }

  void _showUpdateDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.system_update, color: Colors.blue),
            const SizedBox(width: 8),
            const Text('Update Available'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Version $_latestVersion is available!'),
            if (_releaseNotes != null && _releaseNotes!.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Text('Release Notes:',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(_releaseNotes!,
                  style: const TextStyle(fontSize: 13)),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Later'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _downloadUpdate(context);
            },
            child: const Text('Download'),
          ),
          FilledButton.icon(
            onPressed: () {
              Navigator.pop(ctx);
              _downloadUpdate(context);
            },
            icon: const Icon(Icons.download, size: 18),
            label: const Text('Download & Install'),
          ),
        ],
      ),
    );
  }

  Future<void> _downloadUpdate(BuildContext context) async {
    if (_downloadUrl != null) {
      await _downloadAndInstall(context, _downloadUrl!);
    } else {
      final url = Uri.parse('$_githubReleasesUrl/tag/v$_latestVersion');
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      }
    }
  }

  Future<void> _downloadAndInstall(BuildContext context, String url) async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
            SizedBox(width: 16),
            Text('Downloading update...'),
          ],
        ),
        duration: Duration(seconds: 30),
      ),
    );

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final dir = await getApplicationDocumentsDirectory();
        final fileName = url.split('/').last;
        final file = File('${dir.path}/$fileName');
        await file.writeAsBytes(response.bodyBytes);

        if (context.mounted) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Downloaded to ${file.path}'),
              action: SnackBarAction(
                label: 'Open',
                onPressed: () => launchUrl(Uri.file(file.path)),
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Download failed: $e')),
        );
      }
    }
  }

  Future<void> checkOnStartup(BuildContext context) async {
    final hasUpdate = await checkForUpdate();
    if (hasUpdate && context.mounted) {
      _showUpdateDialog(context);
    }
  }
}
