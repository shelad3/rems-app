import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import '../models/update_info.dart';

class UpdateService {
  static final UpdateService instance = UpdateService._();
  UpdateService._();

  static const String _versionUrl =
      'https://raw.githubusercontent.com/shelad3/rems-app/main/version.json';

  Future<UpdateInfo?> checkForUpdate() async {
    try {
      final response = await http.get(Uri.parse(_versionUrl));
      if (response.statusCode != 200) return null;
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final info = UpdateInfo.fromJson(json);
      return info.isNewerThanCurrent ? info : null;
    } catch (e) {
      debugPrint('Update check error: $e');
      return null;
    }
  }

  Future<String?> downloadApk(
    String url, {
    void Function(int received, int total)? onProgress,
  }) async {
    try {
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/rems-update.apk');

      final response = await http.Client().send(
        http.Request('GET', Uri.parse(url)),
      );

      if (response.statusCode != 200) return null;

      final total = response.contentLength ?? -1;
      int received = 0;
      final sink = file.openWrite();

      await for (final chunk in response.stream) {
        received += chunk.length;
        sink.add(chunk);
        if (onProgress != null) {
          onProgress(received, total);
        }
      }

      await sink.close();
      return file.path;
    } catch (e) {
      debugPrint('Download error: $e');
      return null;
    }
  }

  Future<void> installApk(String filePath) async {
    await OpenFilex.open(filePath, type: 'application/vnd.android.package-archive');
  }
}
