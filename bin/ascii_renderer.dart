import 'dart:io';
import 'dart:math';
import 'package:image/image.dart' as img;

void main() async {
  // === Configuration ===
  const String imagePath = 'input.jpg';
  const String outputPath = 'output.txt';
  const int targetColumns = 120;
  const double contrastExponent = 1.0; // 1.0 = normal, > 1.0 = sharper edges

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

/// Represents a 6-dimensional shape vector
class Vector6 {
  double v0 = 0, v1 = 0, v2 = 0, v3 = 0, v4 = 0, v5 = 0;

  double distanceSquared(Vector6 other) {
    double d0 = v0 - other.v0, d1 = v1 - other.v1, d2 = v2 - other.v2;
    double d3 = v3 - other.v3, d4 = v4 - other.v4, d5 = v5 - other.v5;
    return d0 * d0 + d1 * d1 + d2 * d2 + d3 * d3 + d4 * d4 + d5 * d5;
  }

  double operator [](int index) {
    switch (index) {
      case 0:
        return v0;
      case 1:
        return v1;
      case 2:
        return v2;
      case 3:
        return v3;
      case 4:
        return v4;
      case 5:
        return v5;
      default:
        return 0;
    }
  }

  void operator []=(int index, double value) {
    switch (index) {
      case 0:
        v0 = value;
        break;
      case 1:
        v1 = value;
        break;
      case 2:
        v2 = value;
        break;
      case 3:
        v3 = value;
        break;
      case 4:
        v4 = value;
        break;
      case 5:
        v5 = value;
        break;
    }
  }
}

class CharacterShape {
  String character;
  Vector6 shapeVector;

  CharacterShape(this.character, this.shapeVector);
}

class AsciiRenderer {
  final List<CharacterShape> _characterShapes = [];
  final List<double> _maxVectorVals = List.filled(6, 0.0);

  // The Cache: Maps a quantized 6D shape directly to a character
  final Map<int, String> _lookupCache = {};

  // How many discrete steps to round our floats into.
  static const int quantizationSteps = 15;

  static const String charset =
      " ☺☻♥♦♣♠•◘○◙♂♀♪♫☼►◄↕‼¶§▬↨↑↓→←∟↔▲▼" // 0-31 (Control characters/Symbols)
      " !\"#\$%&'()*+,-./0123456789:;<=>?" // 32-63 (Standard ASCII)
      "@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\\]^_" // 64-95
      "`abcdefghijklmnopqrstuvwxyz{|}~⌂" // 96-127
      "ÇüéâäàåçêëèïîìÄÅÉæÆôöòûùÿÖÜ¢£¥₧ƒ" // 128-159 (Extended ASCII)
      "áíóúñÑªº¿⌐¬½¼¡«»░▒▓│┤╡╢╖╕╣║╗╝╜╛┐" // 160-191
      "└┴┬├─┼╞╟╚╔╩╦╠═╬╧╨╤╥╙╘╒╓╫╪┘┌█▄▌▐▀" // 192-223
      "αßΓπΣσµτΦΘΩδ∞φε∩≡±≥≤⌠⌡÷≈°∙·√ⁿ²■ "; // 224-255

  void initialize() {
    int cellWidth = 12;
    int cellHeight = 24;

    // Use a built-in bitmap font from the image package
    final font = img.arial24;

    for (int i = 0; i < charset.length; i++) {
      String c = charset[i];

      // Create a small black canvas for the character
      img.Image bmp = img.Image(width: cellWidth, height: cellHeight);
      img.fill(bmp, color: img.ColorRgb8(0, 0, 0));

      // Draw white text
      img.drawString(
        bmp,
        c,
        font: font,
        color: img.ColorRgb8(255, 255, 255),
        x: -2,
        y: -2,
      );

      Vector6 v = _sampleCell6D(bmp, 0, 0, cellWidth, cellHeight);
      _characterShapes.add(CharacterShape(c, v));
    }

    // Normalization logic
    for (int i = 0; i < 6; i++) {
      _maxVectorVals[i] = _characterShapes
          .map((cs) => cs.shapeVector[i])
          .reduce(max);
    }

    for (var cs in _characterShapes) {
      Vector6 v = cs.shapeVector;
      for (int i = 0; i < 6; i++) {
        v[i] = _maxVectorVals[i] > 0 ? v[i] / _maxVectorVals[i] : 0.0;
      }
    }

    _lookupCache.clear();
  }

  String render(
    img.Image image,
    int columns,
    int rows,
    double contrastExponent,
  ) {
    int cellWidth = image.width ~/ columns;
    int cellHeight = image.height ~/ rows;

    if (cellWidth == 0) cellWidth = 1;
    if (cellHeight == 0) cellHeight = 1;

    StringBuffer sb = StringBuffer();

    for (int y = 0; y < rows; y++) {
      for (int x = 0; x < columns; x++) {
        Vector6 sample = _sampleCell6D(
          image,
          x * cellWidth,
          y * cellHeight,
          cellWidth,
          cellHeight,
        );

        for (int i = 0; i < 6; i++) {
          sample[i] = _maxVectorVals[i] > 0
              ? sample[i] / _maxVectorVals[i]
              : 0.0;

          if (contrastExponent != 1.0) {
            sample[i] = pow(sample[i], contrastExponent).toDouble();
          }
        }

        sb.write(_findBestCharacterCached(sample));
      }
      sb.writeln();
    }

    return sb.toString();
  }

  // --- Caching Implementation ---

  String _findBestCharacterCached(Vector6 target) {
    int key = _generateCacheKey(target);

    if (_lookupCache.containsKey(key)) {
      return _lookupCache[key]!;
    }

    String bestChar = ' ';
    double bestDist = double.maxFinite;

    for (var cs in _characterShapes) {
      double dist = cs.shapeVector.distanceSquared(target);
      if (dist < bestDist) {
        bestDist = dist;
        bestChar = cs.character;
      }
    }

    _lookupCache[key] = bestChar;
    return bestChar;
  }

  int _generateCacheKey(Vector6 v) {
    int key = 0;
    for (int i = 0; i < 6; i++) {
      // Quantize float (0.0 -> 1.0) to an integer (0 -> 15)
      int quantized = (v[i] * quantizationSteps).round().clamp(
        0,
        quantizationSteps,
      );

      // Bitwise shift each value into its own 4-bit slot
      key |= (quantized << (i * 4));
    }
    return key;
  }

  // --- Image Sampling ---

  Vector6 _sampleCell6D(
    img.Image bmp,
    int startX,
    int startY,
    int width,
    int height,
  ) {
    int halfW = width ~/ 2;
    int thirdH = height ~/ 3;
    int staggerY = height ~/ 12;

    Vector6 v = Vector6();

    // Left Column
    v.v0 = _averageLightness(bmp, startX, startY + staggerY, halfW, thirdH);
    v.v2 = _averageLightness(
      bmp,
      startX,
      startY + thirdH + staggerY,
      halfW,
      thirdH,
    );
    v.v4 = _averageLightness(
      bmp,
      startX,
      startY + 2 * thirdH + staggerY,
      halfW,
      thirdH - staggerY,
    );

    // Right Column
    v.v1 = _averageLightness(
      bmp,
      startX + halfW,
      max(startY - staggerY, startY),
      halfW,
      thirdH,
    );
    v.v3 = _averageLightness(
      bmp,
      startX + halfW,
      startY + thirdH - staggerY,
      halfW,
      thirdH,
    );
    v.v5 = _averageLightness(
      bmp,
      startX + halfW,
      startY + 2 * thirdH - staggerY,
      halfW,
      thirdH,
    );

    return v;
  }

  double _averageLightness(img.Image bmp, int x, int y, int w, int h) {
    double total = 0;
    int count = 0;

    for (int cy = y; cy < y + h && cy < bmp.height; cy++) {
      for (int cx = x; cx < x + w && cx < bmp.width; cx++) {
        img.Pixel pixel = bmp.getPixel(cx, cy);
        total +=
            (0.2126 * pixel.r + 0.7152 * pixel.g + 0.0722 * pixel.b) / 255.0;
        count++;
      }
    }
    return count > 0 ? total / count : 0.0;
  }
}
