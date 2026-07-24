import 'dart:typed_data';

abstract class FaceEmbeddingExtractor {
  Future<void> loadModel();

  Future<Float32List> extractEmbedding(Uint8List imageBytes);

  int get embeddingDimension;

  void dispose();
}
