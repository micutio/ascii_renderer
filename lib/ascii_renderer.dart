import 'dart:math';
import 'dart:typed_data';

import 'package:image/image.dart' as img;

import 'src/character_shape.dart';
import 'src/charset_range.dart';
import 'src/vector6.dart';
export 'src/charset_range.dart';

/// Render a given image to ascii text.
class AsciiRenderer {
  /// How many discrete steps to round our floats into.
  static const int _quantizationSteps = 15;

  /// Set of characters from which we render the ascii image.
  /// The null character is replaced with a space to avoid
  /// unintended consequences.
  static const String charset =
      " ☺☻♥♦♣♠•◘○◙♂♀♪♫☼►◄↕‼¶§▬↨↑↓→←∟↔▲▼" // 0-31 (Control characters/Symbols)
      " !\"#\$%&'()*+,-./0123456789:;<=>?" // 32-63 (Standard ASCII)
      "@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\\]^_" // 64-95
      "`abcdefghijklmnopqrstuvwxyz{|}~⌂" // 96-127
      "ÇüéâäàåçêëèïîìÄÅÉæÆôöòûùÿÖÜ¢£¥₧ƒ" // 128-159 (Extended ASCII)
      "áíóúñÑªº¿⌐¬½¼¡«»░▒▓│┤╡╢╖╕╣║╗╝╜╛┐" // 160-191
      "└┴┬├─┼╞╟╚╔╩╦╠═╬╧╨╤╥╙╘╒╓╫╪┘┌█▄▌▐▀" // 192-223
      "αßΓπΣσµτΦΘΩδ∞φε∩≡±≥≤⌠⌡÷≈°∙·√ⁿ²■ "; // 224-255

  final List<CharacterShape> _characterShapes = [];
  final List<double> _maxVectorVals = List.filled(6, 0.0);

  /// The Cache: Maps a quantized 6D shape directly to a character
  final Map<int, String> _lookupCache = {};

  /// Initialise the ASCII renderer with the default font, Arial.
  void initializeFromDefault(CharsetRange charsetRange) {
    _characterShapes.clear();
    _initCharacterShapesFromDefault(charsetRange);
    _normalizeCharacterValues();
    _lookupCache.clear();
  }

  /// Initialise the ASCII renderer with a font passed as image,
  /// in form of raw bytes.
  void initializeFromFontSheet(
    img.Image fontSheetImg,
    CharsetRange charsetRange,
    int charWidth,
    int charHeight,
  ) {
    _characterShapes.clear();
    _initCharacterShapesFromImg(
      fontSheetImg,
      charsetRange,
      charWidth,
      charHeight,
    );
    _normalizeCharacterValues();
    _lookupCache.clear();
  }

  /// Creates a list of character shapes from the default font, Arial
  /// based on the character set [charset].
  void _initCharacterShapesFromDefault(CharsetRange charsetRange) {
    const cellWidth = 12;
    const cellHeight = 24;

    // Use a built-in bitmap font from the image package
    final font = img.arial24;

    for (var i = charsetRange.start; i < charsetRange.end; i++) {
      final c = charset[i];

      // Create a small black canvas for the character
      final bmp = img.Image(width: cellWidth, height: cellHeight);
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

      // Buffer view onto pixels
      final pixelBuffer = bmp.toUint8List();
      final v = _sampleCell6D(
        pixelBuffer,
        bmp.width,
        bmp.height,
        bmp.numChannels,
        0,
        0,
        cellWidth,
        cellHeight,
      );
      _characterShapes.add(CharacterShape(c, v));
    }
  }

  /// Creates a list of character shapes from the custom font passed
  /// as bytes, based on the character set [charset].
  void _initCharacterShapesFromImg(
    img.Image fontSheet,
    CharsetRange charsetRange,
    int charWidthRatio,
    int charHeightRatio,
  ) {
    // Most CP437 sheets are 16x16 characters.
    final charWidth = fontSheet.width ~/ 16;
    final charHeight = fontSheet.height ~/ 16;

    for (var i = charsetRange.start; i < charsetRange.end; i++) {
      final col = i % 16;
      final row = i ~/ 16;

      // Crop the specific character from the grid.
      final charBmp = img.copyCrop(
        fontSheet,
        x: col * charWidth,
        y: row * charHeight,
        width: charWidth,
        height: charHeight,
      );

      // Map the index to the CP437 string character.
      final charMapping = charset[i];
      // Buffer view onto pixels
      final pixelBuffer = charBmp.toUint8List();
      final vec = _sampleCell6DWithRatio(
        pixelBuffer,
        charWidthRatio,
        charHeightRatio,
        charBmp.width,
        charBmp.height,
        charBmp.numChannels,
        0,
        0,
        charWidth,
        charHeight,
      );
      _characterShapes.add(CharacterShape(charMapping, vec));
    }
  }

  /// Normalize character light value vectors.
  void _normalizeCharacterValues() {
    for (var i = 0; i < 6; i++) {
      _maxVectorVals[i] = _characterShapes
          .map((cs) => cs.shapeVector[i])
          .reduce(max);
    }

    for (final cs in _characterShapes) {
      final v = cs.shapeVector;
      for (var i = 0; i < 6; i++) {
        v[i] = _maxVectorVals[i] > 0 ? v[i] / _maxVectorVals[i] : 0.0;
      }
    }
  }

  /// Render an image to ASCII characters.
  /// Returns the image as ASCII string.
  String render(
    img.Image image,
    int columns,
    int rows,
    double contrastExponent,
  ) {
    var cellWidth = image.width ~/ columns;
    var cellHeight = image.height ~/ rows;

    if (cellWidth == 0) cellWidth = 1;
    if (cellHeight == 0) cellHeight = 1;

    final sb = StringBuffer();

    // Buffer view onto pixels
    final pixelBuffer = image.toUint8List();
    for (var y = 0; y < rows; y++) {
      for (var x = 0; x < columns; x++) {
        final sample = _sampleCell6D(
          pixelBuffer,
          image.width,
          image.height,
          image.numChannels,
          x * cellWidth,
          y * cellHeight,
          cellWidth,
          cellHeight,
        );

        for (var i = 0; i < 6; i++) {
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
    final key = _generateCacheKey(target);

    if (_lookupCache.containsKey(key)) {
      return _lookupCache[key]!;
    }

    var bestChar = ' ';
    var bestDist = double.maxFinite;

    for (final cs in _characterShapes) {
      final dist = cs.shapeVector.distanceSquared(target);
      if (dist < bestDist) {
        bestDist = dist;
        bestChar = cs.character;
      }
    }

    _lookupCache[key] = bestChar;
    return bestChar;
  }

  int _generateCacheKey(Vector6 v) {
    var key = 0;
    for (var i = 0; i < 6; i++) {
      // Quantize float (0.0 -> 1.0) to an integer (0 -> 15)
      final quantized = (v[i] * _quantizationSteps).round().clamp(
        0,
        _quantizationSteps,
      );

      // Bitwise shift each value into its own 4-bit slot
      key |= (quantized << (i * 4));
    }
    return key;
  }

  // --- Image Sampling ---

  /// Adapter method for scaling the sampling area to character proportions
  /// before running [_sampleCell6D].
  Vector6 _sampleCell6DWithRatio(
    Uint8List pixelBuffer,
    int widthRatio,
    int heightRatio,
    int imageWidth,
    int imageHeight,
    int imageChannels,
    int startX,
    int startY,
    int width,
    int height,
  ) {
    if (widthRatio < heightRatio) {
      final scaledWidth = widthRatio / heightRatio;
      final charWidth = (width * scaledWidth).toInt();
      final widthOffset = ((1 - scaledWidth) * width) ~/ 2;
      // adapt parameters
      startX = startX + widthOffset;
      width = charWidth;
    }
    if (widthRatio > heightRatio) {
      final scaledHeight = heightRatio / widthRatio;
      final charHeight = (height * scaledHeight).toInt();
      final heightOffset = ((1 - scaledHeight) * height) ~/ 2;
      // adapt parameters
      startY = startY + heightOffset;
      height = charHeight;
    }

    return _sampleCell6D(
      pixelBuffer,
      imageWidth,
      imageHeight,
      imageChannels,
      startX,
      startY,
      width,
      height,
    );
  }

  /// Samples average lightness values for all six zones of the image and stores
  /// them in a vector.
  /// [pixelBuffer] is the image bytes of the character to be classified.
  Vector6 _sampleCell6D(
    Uint8List pixelBuffer,
    int imageWidth,
    int imageHeight,
    int imageChannels,
    int startX,
    int startY,
    int width,
    int height,
  ) {
    if (width < 2 || height < 3) {
      final lightness = _averageLightness(
        pixelBuffer,
        imageWidth,
        imageHeight,
        imageChannels,
        startX,
        startY,
        width,
        height,
      );
      return Vector6(
        lightness,
        lightness,
        lightness,
        lightness,
        lightness,
        lightness,
      );
    }

    final halfW = width ~/ 2;
    final thirdH = height ~/ 3;
    final staggerY = height ~/ 12;

    // Left Column
    final v0 = _averageLightness(
      pixelBuffer,
      imageWidth,
      imageHeight,
      imageChannels,
      startX,
      startY + staggerY,
      halfW,
      thirdH,
    );

    final v2 = _averageLightness(
      pixelBuffer,
      imageWidth,
      imageHeight,
      imageChannels,
      startX,
      startY + thirdH + staggerY,
      halfW,
      thirdH,
    );

    final v4 = _averageLightness(
      pixelBuffer,
      imageWidth,
      imageHeight,
      imageChannels,
      startX,
      startY + 2 * thirdH + staggerY,
      halfW,
      thirdH - staggerY,
    );

    // Right Column
    final v1 = _averageLightness(
      pixelBuffer,
      imageWidth,
      imageHeight,
      imageChannels,
      startX + halfW,
      max(startY - staggerY, startY),
      halfW,
      thirdH,
    );
    final v3 = _averageLightness(
      pixelBuffer,
      imageWidth,
      imageHeight,
      imageChannels,
      startX + halfW,
      startY + thirdH - staggerY,
      halfW,
      thirdH,
    );
    final v5 = _averageLightness(
      pixelBuffer,
      imageWidth,
      imageHeight,
      imageChannels,
      startX + halfW,
      startY + 2 * thirdH - staggerY,
      halfW,
      thirdH,
    );

    return Vector6(v0, v1, v2, v3, v4, v5);
  }

  /// Computes the average lightness for [pixelBuffer] in a rectangular zone delimited
  /// by the given coordinates.
  double _averageLightness(
    Uint8List pixelBuffer,
    int imageWidth,
    int imageHeight,
    int imageChannels,
    int startX,
    int startY,
    int regionWidth,
    int regionHeight,
  ) {
    double total = 0;
    var count = 0;

    // Pre-calculate strides (4 bytes per pixel for RGBA)
    final pixelStride = imageChannels;
    final imgWidth = imageWidth;
    final rowStride = imgWidth * pixelStride;

    // Ensure boundaries
    final endY = (startY + regionHeight).clamp(0, imageHeight);
    final endX = (startX + regionWidth).clamp(0, imgWidth);

    // Loop
    for (var y = startY; y < endY; y++) {
      // Starting index of current row
      final rowOffset = y * rowStride;

      for (var x = startX; x < endX; x++) {
        final i = rowOffset + (x * pixelStride);

        // Check to prevent crash in case of unexpected format
        if (i + 2 >= pixelBuffer.length) break;

        // Access channels
        final r = pixelBuffer[i];
        // In case of monochrome images, copy R (luminance) to G and B.
        final g = (pixelStride > 1) ? pixelBuffer[i + 1] : r;
        final b = (pixelStride > 2) ? pixelBuffer[i + 2] : r;
        total += (0.2126 * r + 0.7152 * g + 0.0722 * b) / 255.0;
        count++;
      }
    }
    return count > 0 ? total / count : 0.0;
  }
}
