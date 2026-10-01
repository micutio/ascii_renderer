import 'dart:io';

import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;

/// Runs the compiled CLI: `--help`, then a one-pixel JPEG through the font bitmap.
void main() {
  exitCode = _smoke();
}

int _smoke() {
  final binary = _findBinary();
  stdout.writeln('Smoke testing $binary');

  final help = Process.runSync(binary, ['--help']);
  stdout.write(help.stdout);
  stderr.write(help.stderr);
  if (help.exitCode != 0) {
    stderr.writeln('--help exited with ${help.exitCode}');
    return help.exitCode;
  }
  if ((help.stdout as String).isEmpty) {
    stderr.writeln('--help produced no output');
    return 1;
  }

  final temp = Directory.systemTemp.createTempSync('ascii_renderer_smoke');
  try {
    final imagePath = p.join(temp.path, 'pixel.jpg');
    final outputPath = p.join(temp.path, 'out.txt');
    final pixel = img.Image(width: 1, height: 1);
    pixel.setPixel(0, 0, img.ColorRgb8(32, 32, 32));
    File(imagePath).writeAsBytesSync(img.encodeJpg(pixel));

    final font = p.join(Directory.current.path, 'font', 'iosevka.png');
    final run = Process.runSync(binary, [
      '--input',
      imagePath,
      '--output',
      outputPath,
      '--font',
      font,
    ]);
    stdout.write(run.stdout);
    stderr.write(run.stderr);
    if (run.exitCode != 0) {
      stderr.writeln('Render exited with ${run.exitCode}');
      return run.exitCode;
    }

    final output = File(outputPath);
    if (!output.existsSync() || output.lengthSync() == 0) {
      stderr.writeln('Expected a non-empty ASCII file at $outputPath');
      return 1;
    }
    stdout.writeln('Smoke test wrote ${output.lengthSync()} bytes.');
    return 0;
  } finally {
    temp.deleteSync(recursive: true);
  }
}

String _findBinary() {
  final root = Directory('build/cli');
  if (!root.existsSync()) {
    stderr.writeln('No build/cli directory. Run dart build cli first.');
    exit(1);
  }

  final matches = root.listSync(recursive: true).whereType<File>().where((
    file,
  ) {
    final name = p.basename(file.path);
    return name == 'ascii_renderer' || name == 'ascii_renderer.exe';
  }).toList();
  if (matches.isEmpty) {
    stderr.writeln('No ascii_renderer binary under build/cli.');
    exit(1);
  }
  return matches.first.absolute.path;
}
