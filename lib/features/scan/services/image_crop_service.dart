import 'dart:io';
import 'dart:ui' show Rect;

import 'package:image/image.dart' as img;

/// Crops a captured camera image using normalized overlay rect (0..1).
class ImageCropService {
  /// [normalizedCrop] is relative to the preview widget (left, top, width, height).
  Future<File> cropToOverlay({
    required File source,
    required Rect normalizedCrop,
    required bool isFrontCamera,
  }) async {
    final bytes = await source.readAsBytes();
    var decoded = img.decodeImage(bytes);
    if (decoded == null) return source;

    // Camera images are often rotated; bake orientation if EXIF present.
    decoded = img.bakeOrientation(decoded);

    if (isFrontCamera) {
      decoded = img.flipHorizontal(decoded);
    }

    final left = (normalizedCrop.left * decoded.width)
        .round()
        .clamp(0, decoded.width - 1);
    final top = (normalizedCrop.top * decoded.height)
        .round()
        .clamp(0, decoded.height - 1);
    final width = (normalizedCrop.width * decoded.width)
        .round()
        .clamp(1, decoded.width - left);
    final height = (normalizedCrop.height * decoded.height)
        .round()
        .clamp(1, decoded.height - top);

    final cropped = img.copyCrop(
      decoded,
      x: left,
      y: top,
      width: width,
      height: height,
    );

    final outPath = '${source.path}_cropped.jpg';
    final out = File(outPath);
    await out.writeAsBytes(img.encodeJpg(cropped, quality: 90));
    return out;
  }

  /// Default centered receipt frame: 82% width × 62% height.
  static Rect defaultNormalizedCrop() {
    const w = 0.82;
    const h = 0.62;
    return Rect.fromLTWH((1 - w) / 2, (1 - h) / 2, w, h);
  }
}
