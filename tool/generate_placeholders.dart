// Generates offline placeholder product images into assets/images/.
//
// A minimal pure-Dart PNG encoder (truecolor, 8-bit) with zero dependencies:
//   - zlib (dart:io) for the IDAT stream
//   - a hand-rolled CRC-32 for chunk checksums
//
// Run from the project root:
//   dart run tool/generate_placeholders.dart
//
// Each image is a soft vertical gradient plus a subtle radial highlight, so the
// catalogue still looks polished while the app remains fully offline.
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

const _signature = <int>[0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A];

// ---------------------------------------------------------------------------
// Minimal PNG encoder
// ---------------------------------------------------------------------------

int _crc32(List<int> data) {
  var crc = 0xFFFFFFFF;
  for (final byte in data) {
    crc ^= byte;
    for (var k = 0; k < 8; k++) {
      crc = (crc & 1) != 0 ? (crc >> 1) ^ 0xEDB88320 : crc >> 1;
    }
  }
  return crc ^ 0xFFFFFFFF;
}

List<int> _be32(int value) =>
    [value >> 24 & 0xFF, value >> 16 & 0xFF, value >> 8 & 0xFF, value & 0xFF];

void _writeChunk(BytesBuilder out, String type, List<int> data) {
  final typeBytes = ascii.encode(type);
  out.add(_be32(data.length));
  out.add(typeBytes);
  out.add(data);
  out.add(_be32(_crc32([...typeBytes, ...data])));
}

List<int> _encodePng(int width, int height, Uint8List rgb) {
  final out = BytesBuilder();
  out.add(_signature);
  // IHDR: 8-bit truecolor RGB, default compression/filter/interlace.
  _writeChunk(out, 'IHDR', [
    ..._be32(width),
    ..._be32(height),
    8, // bit depth
    2, // color type: truecolor RGB
    0, // compression
    0, // filter method
    0, // interlace
  ]);
  final raw = BytesBuilder();
  for (var y = 0; y < height; y++) {
    raw.addByte(0); // scanline filter: None
    final start = y * width * 3;
    raw.add(rgb.sublist(start, start + width * 3));
  }
  _writeChunk(out, 'IDAT', zlib.encode(raw.takeBytes()));
  _writeChunk(out, 'IEND', const []);
  return out.takeBytes();
}

// ---------------------------------------------------------------------------
// Image rendering
// ---------------------------------------------------------------------------

double _lerp(double a, double b, double t) => a + (b - a) * t;

Uint8List _render(int size, int top, int bottom) {
  final topR = top >> 16 & 0xFF, topG = top >> 8 & 0xFF, topB = top & 0xFF;
  final botR = bottom >> 16 & 0xFF, botG = bottom >> 8 & 0xFF, botB = bottom & 0xFF;
  final bytes = Uint8List(size * size * 3);
  for (var y = 0; y < size; y++) {
    final t = size == 1 ? 0.0 : y / (size - 1);
    for (var x = 0; x < size; x++) {
      var r = _lerp(topR.toDouble(), botR.toDouble(), t);
      var g = _lerp(topG.toDouble(), botG.toDouble(), t);
      var b = _lerp(topB.toDouble(), botB.toDouble(), t);
      // Soft radial highlight suggesting a product on a lit pedestal.
      final dx = (x - size * 0.5) / (size * 0.5);
      final dy = (y - size * 0.42) / (size * 0.58);
      final d = math.sqrt(dx * dx + dy * dy);
      if (d < 1.0) {
        final glow = (1.0 - d) * 0.25;
        r += (255 - r) * glow;
        g += (255 - g) * glow;
        b += (255 - b) * glow;
      }
      final i = (y * size + x) * 3;
      bytes[i] = r.round().clamp(0, 255);
      bytes[i + 1] = g.round().clamp(0, 255);
      bytes[i + 2] = b.round().clamp(0, 255);
    }
  }
  return bytes;
}

// (file name, gradient top color, gradient bottom color)
const _products = <(String, int, int)>[
  ('product_1', 0xFF4F46E5, 0xFF7C3AED), // Aurora headphones     — indigo
  ('product_2', 0xFF0D9488, 0xFF22D3EE), // Pulse smartwatch      — teal
  ('product_3', 0xFFF97316, 0xFFFBBF24), // Strider sneakers      — orange
  ('product_4', 0xFF8B5CF6, 0xFFC084FC), // Nomad backpack        — violet
  ('product_5', 0xFF0284C7, 0xFF38BDF8), // Solstice sunglasses   — sky
  ('product_6', 0xFF334155, 0xFF94A3B8), // Lumina camera         — slate
  ('product_7', 0xFFE11D48, 0xFFFB7185), // Breeze tee            — rose
  ('product_8', 0xFF16A34A, 0xFF4ADE80), // Mechkey keyboard      — green
];

void main() {
  const size = 480;
  const outDir = 'assets/images';
  Directory(outDir).createSync(recursive: true);
  for (final (name, top, bottom) in _products) {
    final png = _encodePng(size, size, _render(size, top, bottom));
    File('$outDir/$name.png').writeAsBytesSync(png);
    stdout.writeln('wrote $outDir/$name.png (${png.length} bytes)');
  }
  stdout.writeln('done: ${_products.length} placeholders generated.');
}
