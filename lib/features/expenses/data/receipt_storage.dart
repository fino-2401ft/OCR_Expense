import 'dart:io';

import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class ReceiptStorage {
  Future<Directory> _receiptDir() async {
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(docs.path, 'receipts'));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  /// Saves full image and a compressed thumbnail. Returns (imagePath, thumbPath).
  Future<(String imagePath, String thumbnailPath)> saveReceiptImages(
    File source,
  ) async {
    final dir = await _receiptDir();
    final stamp = DateTime.now().millisecondsSinceEpoch;
    final imagePath = p.join(dir.path, 'receipt_$stamp.jpg');
    final thumbPath = p.join(dir.path, 'receipt_${stamp}_thumb.jpg');

    await source.copy(imagePath);

    final bytes = await File(imagePath).readAsBytes();
    final decoded = img.decodeImage(bytes);
    if (decoded != null) {
      final thumb = img.copyResize(
        decoded,
        width: decoded.width > decoded.height ? 800 : null,
        height: decoded.height >= decoded.width ? 800 : null,
      );
      await File(thumbPath).writeAsBytes(img.encodeJpg(thumb, quality: 75));
    } else {
      await File(imagePath).copy(thumbPath);
    }

    return (imagePath, thumbPath);
  }

  Future<void> deleteIfExists(String? path) async {
    if (path == null || path.isEmpty) return;
    final file = File(path);
    if (await file.exists()) {
      await file.delete();
    }
  }
}
