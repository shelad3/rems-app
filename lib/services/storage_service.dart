import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

class StorageService {
  static final StorageService instance = StorageService._();
  StorageService._();

  final _storage = FirebaseStorage.instance;
  final _picker = ImagePicker();

  Future<String?> pickAndUpload(String path) async {
    final file = await _picker.pickImage(source: ImageSource.gallery);
    if (file == null) return null;

    final ref = _storage.ref().child('$path/${DateTime.now().millisecondsSinceEpoch}');
    await ref.putData(await file.readAsBytes());
    return await ref.getDownloadURL();
  }

  Future<List<String>> pickAndUploadMultiple(String path) async {
    final files = await _picker.pickMultiImage();
    if (files.isEmpty) return [];

    final urls = <String>[];
    for (final file in files) {
      final ref = _storage.ref().child('$path/${DateTime.now().millisecondsSinceEpoch}');
      await ref.putData(await file.readAsBytes());
      urls.add(await ref.getDownloadURL());
    }
    return urls;
  }

  Future<void> delete(String url) async {
    try {
      final ref = _storage.refFromURL(url);
      await ref.delete();
    } catch (_) {}
  }
}
