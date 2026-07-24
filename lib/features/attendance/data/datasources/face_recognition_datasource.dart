import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/foundation.dart';

import '../../domain/entities/face_embedding.dart';
import '../../domain/services/face_embedding_extractor.dart';
import '../datasources/embedding_local_datasource.dart';
import '../datasources/person_local_datasource.dart';

// ── Result ─────────────────────────────────────────────────

class RecognitionResult {
  final String personId;
  final String personName;
  final String department;
  final double confidence;

  const RecognitionResult({
    required this.personId,
    required this.personName,
    required this.department,
    required this.confidence,
  });

  factory RecognitionResult.fromJson(Map<String, dynamic> json) {
    return RecognitionResult(
      personId: json['person_id']?.toString() ?? '',
      personName: json['name']?.toString() ?? 'Unknown',
      department: json['department']?.toString() ?? '',
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

// ── Datasource ───────────────────────────────────────────────

abstract class FaceRecognitionDatasource {
  Future<RecognitionResult> recognize(String imagePath);
  Future<void> reloadEmbeddings();
}

class FaceRecognitionDatasourceImpl implements FaceRecognitionDatasource {
  final PersonLocalDatasource _personLocal;
  final EmbeddingLocalDatasource _embeddingLocal;
  final FaceEmbeddingExtractor _extractor;

  Map<String, _CachedPerson>? _cache;

  static const double _kSimilarityThreshold = 0.65;

  FaceRecognitionDatasourceImpl({
    required PersonLocalDatasource personLocalDatasource,
    required EmbeddingLocalDatasource embeddingLocalDatasource,
    required FaceEmbeddingExtractor embeddingExtractor,
  })  : _personLocal = personLocalDatasource,
        _embeddingLocal = embeddingLocalDatasource,
        _extractor = embeddingExtractor;

  @override
  Future<void> reloadEmbeddings() async {
    final persons = await _personLocal.getAllPersons();
    final personMap = <String, _PersonInfo>{};
    for (final p in persons) {
      personMap[p.employeeId] = _PersonInfo(
        name: p.name,
        department: p.department,
      );
    }

    final grouped = await _embeddingLocal.getAllEmbeddingsGrouped();

    _cache = {};
    for (final entry in grouped.entries) {
      final info = personMap[entry.key];
      if (info == null) continue;
      _cache![entry.key] = _CachedPerson(
        name: info.name,
        department: info.department,
        embeddings: entry.value,
      );
    }

    debugPrint(
      '[FaceRecognition] Loaded ${_cache?.length ?? 0} persons with '
      '${grouped.values.fold(0, (s, l) => s + l.length)} embeddings',
    );
  }

  Future<Map<String, _CachedPerson>> _getCache() async {
    if (_cache == null) await reloadEmbeddings();
    return _cache!;
  }

  @override
  Future<RecognitionResult> recognize(String imagePath) async {
    await _extractor.loadModel();

    final file = File(imagePath);
    if (!file.existsSync()) {
      throw Exception('Captured image not found: $imagePath');
    }

    final bytes = await file.readAsBytes();
    final captured = await _extractor.extractEmbedding(bytes);

    final cache = await _getCache();
    if (cache.isEmpty) {
      throw const FaceNotRecognizedException();
    }

    String? bestPersonId;
    String? bestName;
    String? bestDepartment;
    var bestSimilarity = -1.0;

    for (final entry in cache.entries) {
      final cached = entry.value;
      for (final emb in cached.embeddings) {
        final sim = _cosineSimilarity(captured, emb.embedding);
        if (sim > bestSimilarity) {
          bestSimilarity = sim;
          bestPersonId = entry.key;
          bestName = cached.name;
          bestDepartment = cached.department;
        }
      }
    }

    if (bestPersonId == null || bestSimilarity < _kSimilarityThreshold) {
      throw const FaceNotRecognizedException();
    }

    return RecognitionResult(
      personId: bestPersonId,
      personName: bestName!,
      department: bestDepartment ?? '',
      confidence: bestSimilarity.clamp(0.0, 1.0),
    );
  }
}

// ── Helpers ──────────────────────────────────────────────────

double _cosineSimilarity(Float32List a, Float32List b) {
  var dot = 0.0, normA = 0.0, normB = 0.0;
  for (var i = 0; i < a.length; i++) {
    dot += a[i] * b[i];
    normA += a[i] * a[i];
    normB += b[i] * b[i];
  }
  if (normA == 0 || normB == 0) return 0.0;
  return dot / (math.sqrt(normA) * math.sqrt(normB));
}

// ── Internal types ───────────────────────────────────────────

class _PersonInfo {
  final String name;
  final String department;
  const _PersonInfo({required this.name, required this.department});
}

class _CachedPerson {
  final String name;
  final String department;
  final List<FaceEmbedding> embeddings;
  const _CachedPerson({
    required this.name,
    required this.department,
    required this.embeddings,
  });
}

// ── Exception ────────────────────────────────────────────────

class FaceNotRecognizedException implements Exception {
  const FaceNotRecognizedException();
  @override
  String toString() => 'No matching face found in the database.';
}
