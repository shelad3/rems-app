import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

class FileManagerService {
  static final FileManagerService instance = FileManagerService._init();
  FileManagerService._init();

  Future<Directory> get _docsDir async {
    final appDir = await getApplicationDocumentsDirectory();
    final dir = Directory('${appDir.path}/rems_documents');
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  Future<String> saveFile(String sourcePath, {String? subfolder}) async {
    final dir = await _docsDir;
    final targetDir = subfolder != null
        ? Directory('${dir.path}/$subfolder')
        : dir;
    if (!await targetDir.exists()) await targetDir.create(recursive: true);

    final ext = sourcePath.split('.').last;
    final newName = '${const Uuid().v4()}.$ext';
    final newPath = '${targetDir.path}/$newName';
    await File(sourcePath).copy(newPath);
    return newPath;
  }

  Future<String> saveFileFromBytes(List<int> bytes, String fileName) async {
    final dir = await _docsDir;
    final newPath = '${dir.path}/$fileName';
    await File(newPath).writeAsBytes(bytes);
    return newPath;
  }

  Future<void> deleteFile(String path) async {
    final file = File(path);
    if (await file.exists()) await file.delete();
  }

  Future<List<FileSystemEntity>> listFiles(String subfolder) async {
    final dir = await _docsDir;
    final target = Directory('${dir.path}/$subfolder');
    if (!await target.exists()) return [];
    return target.list().toList();
  }

  Future<int> getStorageUsed() async {
    final dir = await _docsDir;
    int total = 0;
    await for (final entity in dir.list(recursive: true)) {
      if (entity is File) {
        total += await entity.length();
      }
    }
    return total;
  }
}
