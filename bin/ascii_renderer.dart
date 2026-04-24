import 'dart:io';

import 'package:image/image.dart' as img;

import 'package:ascii_renderer/ascii_renderer.dart';

void main() async {
  // === Configuration ===
  const String imagePath = 'input.jpg';
  const String outputPath = 'output.txt';
  const int targetColumns = 240;
  const double contrastExponent = 10.0; // 1.0 = normal, > 1.0 = sharper edges

  final File file = File(imagePath);
  if (!file.existsSync()) {
    print(
      "Error: Please ensure '$imagePath' exists in the application directory.",
    );
    return;
  }

  print("Loading image...");
  final img.Image? targetImage = img.decodeImage(file.readAsBytesSync());
  if (targetImage == null) {
    print("Failed to decode image.");
    return;
  }

  print("Initializing renderer (computing 6D shape vectors)...");
  final AsciiRenderer renderer = AsciiRenderer();
  renderer.initialize();

  // Calculate rows to maintain the image's aspect ratio.
  // Monospace characters are roughly twice as tall as they are wide (1:2 ratio).
  double imageAspectRatio = targetImage.width / targetImage.height;
  int targetRows = ((targetColumns / imageAspectRatio) * 0.5).toInt();

  print("Rendering ASCII at ${targetColumns}x$targetRows...");
  final stopwatch = Stopwatch()..start();

  String asciiArt = renderer.render(
    targetImage,
    targetColumns,
    targetRows,
    contrastExponent,
  );

  stopwatch.stop();
  print("Render completed in ${stopwatch.elapsedMilliseconds} ms.");

  File(outputPath).writeAsStringSync(asciiArt);
  print(
    "Success! Open '$outputPath' in a text editor (zoom out and turn off word wrap!).",
  );
}
