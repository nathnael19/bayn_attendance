import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';

import '../../domain/services/face_embedding_extractor.dart';

class TfliteEmbeddingExtractor implements FaceEmbeddingExtractor {
  static const String _kModelPath = 'assets/models/mobilefacenet.tflite';
  static const int _kInputSize = 112;
  static const int _kEmbeddingDim = 192;

  Interpreter? _interpreter;

  @override
  int get embeddingDimension => _kEmbeddingDim;

  @override
  Future<void> loadModel() async {
    if (_interpreter != null) return;
    try {
      _interpreter = await Interpreter.fromAsset(_kModelPath);
      if (_interpreter == null) {
        throw StateError('Interpreter.fromAsset returned null');
      }
      debugPrint('[TFLite] Model loaded from $_kModelPath');
    } catch (e) {
      debugPrint('[TFLite] Failed to load model: $e');
      rethrow;
    }
  }

  @override
  Future<Float32List> extractEmbedding(Uint8List imageBytes) async {
    await loadModel();

    final decoded = img.decodeImage(imageBytes);
    if (decoded == null) {
      throw ArgumentError('Failed to decode image');
    }

    final resized = img.copyResize(decoded, width: _kInputSize, height: _kInputSize);
    final input = _preprocess(resized);

    final output = List.filled(1 * _kEmbeddingDim, 0.0).reshape([1, _kEmbeddingDim]);

    _interpreter!.run(input, output);

    final flat = output
        .cast<List<double>>()
        .expand((e) => e)
        .toList();

    final result = Float32List(_kEmbeddingDim);
    for (var i = 0; i < _kEmbeddingDim; i++) {
      result[i] = flat[i];
    }

    return result;
  }

  static List<List<List<List<double>>>> _preprocess(img.Image image) {
    return List.generate(
      1,
      (_) => List.generate(
        _kInputSize,
        (y) => List.generate(
          _kInputSize,
          (x) {
            final pixel = image.getPixel(x, y);
            return [
              (pixel.r.toInt() - 127.5) / 127.5,
              (pixel.g.toInt() - 127.5) / 127.5,
              (pixel.b.toInt() - 127.5) / 127.5,
            ];
          },
        ),
      ),
    );
  }

  @override
  void dispose() {
    _interpreter?.close();
    _interpreter = null;
  }
}
