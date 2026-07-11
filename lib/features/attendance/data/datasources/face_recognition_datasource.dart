import 'dart:io';
import 'package:image/image.dart' as img;

import 'person_local_datasource.dart';
import '../models/person_model.dart';

// ─────────────────────────────────────────────────────────────

const int _kHashSize = 8;
const int _kMaxDistanceForMatch = 18;

/// Result returned after a face is matched against the registered persons.
class RecognitionResult {
  /// The matched person's employee/student ID (from your persons DB).
  final String personId;
  final String personName;
  final String department;

  /// Confidence score between 0.0 and 1.0.
  /// Backend teams: map your distance / similarity metric here.
  final double confidence;

  const RecognitionResult({
    required this.personId,
    required this.personName,
    required this.department,
    required this.confidence,
  });

  /// Parse from backend JSON response.
  /// TODO: adjust keys to match your API's response shape.
  /// Expected shape (example):
  /// {
  ///   "person_id":   "EMP-001",
  ///   "name":        "Abebe Girma",
  ///   "department":  "Engineering",
  ///   "confidence":  0.97          // or "distance": 0.03 — convert accordingly
  /// }
  factory RecognitionResult.fromJson(Map<String, dynamic> json) {
    return RecognitionResult(
      personId: json['person_id']?.toString() ?? '',
      personName: json['name']?.toString() ?? 'Unknown',
      department: json['department']?.toString() ?? '',
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

// ─────────────────────────────────────────────────────────────

abstract class FaceRecognitionDatasource {
  /// Compare a captured face image against locally stored registration photos.
  /// Returns a [RecognitionResult] on a successful match.
  /// Throws [FaceNotRecognizedException] if no match found.
  Future<RecognitionResult> recognize(String imagePath);
}

class FaceRecognitionDatasourceImpl implements FaceRecognitionDatasource {
  final PersonLocalDatasource personLocalDatasource;

  FaceRecognitionDatasourceImpl({required this.personLocalDatasource});

  @override
  Future<RecognitionResult> recognize(String imagePath) async {
    final capturedFile = File(imagePath);
    if (!capturedFile.existsSync()) {
      throw Exception('Captured image file not found: $imagePath');
    }

    final capturedHash = _imageHash(capturedFile);
    final persons = await personLocalDatasource.getAllPersons();

    if (persons.isEmpty) {
      throw const FaceNotRecognizedException();
    }

    PersonModel? bestPerson;
    int bestDistance = 1 << 30;

    for (final person in persons) {
      for (final imagePath in _allStoredImages(person)) {
        final imageFile = File(imagePath);
        if (!imageFile.existsSync()) continue;

        final distance = _hashDistance(capturedHash, _imageHash(imageFile));
        if (distance < bestDistance) {
          bestDistance = distance;
          bestPerson = person;
        }
      }
    }

    if (bestPerson == null || bestDistance > _kMaxDistanceForMatch) {
      throw const FaceNotRecognizedException();
    }

    final confidence = 1.0 - (bestDistance / (_kHashSize * _kHashSize));
    return RecognitionResult(
      personId: bestPerson.serverId ?? bestPerson.employeeId,
      personName: bestPerson.name,
      department: bestPerson.department,
      confidence: confidence.clamp(0.0, 1.0),
    );
  }
}

List<String> _allStoredImages(PersonModel person) {
  final images = <String>[];
  for (final entry in person.faceImagePaths.entries) {
    images.addAll(entry.value);
  }
  return images;
}

BigInt _imageHash(File file) {
  final bytes = file.readAsBytesSync();
  final decoded = img.decodeImage(bytes);
  if (decoded == null) {
    throw Exception('Unsupported image file: ${file.path}');
  }

  final resized = img.copyResize(
    decoded,
    width: _kHashSize + 1,
    height: _kHashSize,
  );
  final grayscale = img.grayscale(resized);

  var hash = BigInt.zero;
  var bitIndex = 0;

  for (var y = 0; y < _kHashSize; y++) {
    for (var x = 0; x < _kHashSize; x++) {
      final left = grayscale.getPixel(x, y).r.toInt();
      final right = grayscale.getPixel(x + 1, y).r.toInt();
      if (left > right) {
        hash |= (BigInt.one << bitIndex);
      }
      bitIndex++;
    }
  }

  return hash;
}

int _hashDistance(BigInt a, BigInt b) {
  final xor = a ^ b;
  var distance = 0;
  var value = xor;

  while (value > BigInt.zero) {
    if ((value & BigInt.one) == BigInt.one) {
      distance++;
    }
    value = value >> 1;
  }

  return distance;
}

// ── Custom exceptions ─────────────────────────────────────────

class FaceNotRecognizedException implements Exception {
  const FaceNotRecognizedException();
  @override
  String toString() => 'No matching face found in the database.';
}
