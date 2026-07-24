import 'dart:typed_data';

import 'package:equatable/equatable.dart';

class FaceEmbedding extends Equatable {
  final int? id;
  final String personId;
  final String? label;
  final Float32List embedding;
  final DateTime createdAt;

  int get dimension => embedding.length;

  const FaceEmbedding({
    this.id,
    required this.personId,
    this.label,
    required this.embedding,
    required this.createdAt,
  });

  FaceEmbedding copyWith({
    int? id,
    String? personId,
    String? label,
    Float32List? embedding,
    DateTime? createdAt,
  }) {
    return FaceEmbedding(
      id: id ?? this.id,
      personId: personId ?? this.personId,
      label: label ?? this.label,
      embedding: embedding ?? this.embedding,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [id, personId, label, embedding, createdAt];
}
