import 'dart:typed_data';

import '../../domain/entities/face_embedding.dart';

class FaceEmbeddingModel extends FaceEmbedding {
  const FaceEmbeddingModel({
    super.id,
    required super.personId,
    super.label,
    required super.embedding,
    required super.createdAt,
  });

  Map<String, dynamic> toMap() {
    final blob = _float32ListToUint8List(embedding);
    return {
      if (id != null) 'id': id,
      'person_id': personId,
      'label': label,
      'embedding': blob,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory FaceEmbeddingModel.fromMap(Map<String, dynamic> map) {
    final blob = map['embedding'] as Uint8List;
    return FaceEmbeddingModel(
      id: map['id'] as int?,
      personId: map['person_id'] as String,
      label: map['label'] as String?,
      embedding: _uint8ListToFloat32List(blob),
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    final list = <double>[];
    for (var i = 0; i < embedding.length; i++) {
      list.add(embedding[i]);
    }
    return {
      'label': label,
      'vector': list,
    };
  }

  factory FaceEmbeddingModel.fromRemote({
    required String personId,
    required String? label,
    required Float32List vector,
    required DateTime createdAt,
  }) {
    return FaceEmbeddingModel(
      personId: personId,
      label: label,
      embedding: vector,
      createdAt: createdAt,
    );
  }

  factory FaceEmbeddingModel.fromEntity(FaceEmbedding e) {
    return FaceEmbeddingModel(
      id: e.id,
      personId: e.personId,
      label: e.label,
      embedding: e.embedding,
      createdAt: e.createdAt,
    );
  }

  static Uint8List _float32ListToUint8List(Float32List data) {
    final bytes = ByteData(data.length * 4);
    for (var i = 0; i < data.length; i++) {
      bytes.setFloat32(i * 4, data[i], Endian.little);
    }
    return bytes.buffer.asUint8List();
  }

  static Float32List _uint8ListToFloat32List(Uint8List data) {
    final count = data.length ~/ 4;
    final result = Float32List(count);
    final bytes = ByteData.view(data.buffer, data.offsetInBytes, data.length);
    for (var i = 0; i < count; i++) {
      result[i] = bytes.getFloat32(i * 4, Endian.little);
    }
    return result;
  }
}
