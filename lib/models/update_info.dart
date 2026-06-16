import 'package:package_info_plus/package_info_plus.dart';

class UpdateInfo {
  final String version;
  final int buildNumber;
  final String downloadUrl;
  final String changelog;

  UpdateInfo({
    required this.version,
    required this.buildNumber,
    required this.downloadUrl,
    required this.changelog,
  });

  bool get isNewerThanCurrent => _currentBuildNumber < buildNumber;

  static int _currentBuildNumber = 0;

  static Future<void> init() async {
    final info = await PackageInfo.fromPlatform();
    _currentBuildNumber = int.tryParse(info.buildNumber) ?? 0;
  }

  factory UpdateInfo.fromJson(Map<String, dynamic> json) {
    return UpdateInfo(
      version: json['version'] as String? ?? '',
      buildNumber: json['buildNumber'] as int? ?? 0,
      downloadUrl: json['downloadUrl'] as String? ?? '',
      changelog: json['changelog'] as String? ?? '',
    );
  }
}
