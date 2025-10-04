import 'dart:io';
import 'dart:math' as math;

import 'package:image/image.dart' as img;

/// Prepares a circular app icon from the provided image file.
/// - Uses only the circular area (transparent outside the circle).
/// - Applies a small inward margin to avoid any watermark near edges.
/// - Centers the crop to avoid alignment issues on launcher icons.
///
/// Usage:
///   dart run tool/prepare_icon.dart /absolute/path/to/source.png
/// If no argument is provided, it tries a default download path
/// then falls back to assets/icons/app_icon.png
Future<void> main(List<String> args) async {
  final candidates = <String>[
    if (args.isNotEmpty) args.first,
    '/home/ayu/Downloads/new_app_icon.png',
    'assets/icons/app_icon.png',
  ];

  late String inputPath;
  for (final c in candidates) {
    if (c.isNotEmpty && File(c).existsSync()) {
      inputPath = c;
      break;
    }
  }

  stdout.writeln('Using source icon: ' + inputPath);

  final bytes = await File(inputPath).readAsBytes();
  final decoded = img.decodeImage(bytes);
  if (decoded == null) {
    stderr.writeln('Failed to decode image: ' + inputPath);
    exit(2);
  }

  // Create a centered square crop from the source
  final size = math.min(decoded.width, decoded.height);
  final offsetX = ((decoded.width - size) / 2).floor();
  final offsetY = ((decoded.height - size) / 2).floor();
  var square = img.copyCrop(decoded, x: offsetX, y: offsetY, width: size, height: size);

  // Apply a circular mask with a slight margin to avoid edge artifacts/watermarks
  final cx = size / 2.0;
  final cy = size / 2.0;
  final radius = (size / 2.0) * 0.97; // 3% inset
  final feather = size * 0.01; // soft edge

  for (int y = 0; y < size; y++) {
    for (int x = 0; x < size; x++) {
      final dx = x + 0.5 - cx;
      final dy = y + 0.5 - cy;
      final d = math.sqrt(dx * dx + dy * dy);
      if (d > radius + feather) {
        // Fully transparent outside the circle
        final p = square.getPixel(x, y);
        final r = p.r;
        final g = p.g;
        final b = p.b;
        square.setPixelRgba(x, y, r, g, b, 0);
      } else if (d > radius) {
        // Feather the edge for smoother circle boundary
        final t = 1.0 - ((d - radius) / feather);
        final a = (255 * t.clamp(0.0, 1.0)).round();
        final p = square.getPixel(x, y);
        square.setPixelRgba(x, y, p.r, p.g, p.b, a);
      }
    }
  }

  // Ensure destination directory exists
  final outDir = Directory('assets/icons');
  if (!outDir.existsSync()) {
    outDir.createSync(recursive: true);
  }
  final outPath = 'assets/icons/app_icon_processed.png';
  await File(outPath).writeAsBytes(img.encodePng(square, level: 6));
  stdout.writeln('Wrote processed icon: ' + outPath);
}


