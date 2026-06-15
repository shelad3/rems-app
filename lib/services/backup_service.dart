import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:sqflite/sqflite.dart';
import '../database/database_helper.dart';

class BackupService {
  static final BackupService instance = BackupService._();
  BackupService._();

  Future<void> exportBackup() async {
    final dbPath = await getDatabasesPath();
    final source = File('$dbPath/real_estate.db');
    if (!await source.exists()) {
      throw Exception('Database file not found');
    }

    final dir = await getApplicationDocumentsDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final backupPath = '${dir.path}/rems_backup_$timestamp.db';
    await source.copy(backupPath);

    await Share.shareXFiles(
      [XFile(backupPath)],
      subject: 'REMS Backup',
    );
  }

  Future<void> importBackup(String filePath) async {
    final dbPath = await getDatabasesPath();
    final dest = File('$dbPath/real_estate.db');
    final source = File(filePath);

    if (!await source.exists()) {
      throw Exception('Backup file not found');
    }

    await DatabaseHelper.instance.close();
    await source.copy(dest.path);
  }
}
