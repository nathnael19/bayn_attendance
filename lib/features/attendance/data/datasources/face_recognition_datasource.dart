import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

// ─────────────────────────────────────────────────────────────
//  TODO (Backend team): fill in your face recognition API details
// ─────────────────────────────────────────────────────────────

/// Base URL of the face recognition backend.
/// This is THE most critical endpoint — the core of attendance matching.
/// Example: 'https://api.yourserver.com/v1'
// TODO: replace with your actual base URL
const String _kBaseUrl = '';

/// API key if required.
// TODO: add your API key or remove if not needed
const String _kApiKey = '';

// ─────────────────────────────────────────────────────────────

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
      personId: json['person_id']?.toString() ?? '',  // TODO: adjust key
      personName: json['name']?.toString() ?? 'Unknown', // TODO: adjust key
      department: json['department']?.toString() ?? '', // TODO: adjust key
      // TODO: if your API returns a distance score instead of confidence,
      // convert it here, e.g.: confidence = 1.0 - json['distance']
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

// ─────────────────────────────────────────────────────────────

abstract class FaceRecognitionDatasource {
  /// Send a still face image to the backend for recognition.
  /// Returns a [RecognitionResult] on a successful match.
  /// Throws [FaceNotRecognizedException] if no match found.
  /// Throws [BackendNotConfiguredException] if URL is not set.
  Future<RecognitionResult> recognize(String imagePath);
}

class FaceRecognitionDatasourceImpl implements FaceRecognitionDatasource {
  final http.Client httpClient;
  FaceRecognitionDatasourceImpl({required this.httpClient});

  @override
  Future<RecognitionResult> recognize(String imagePath) async {
    // TODO (Backend team): confirm endpoint with your API docs.
    // This endpoint receives an image and returns the matched person.
    // Example: POST /faces/recognize
    const endpoint = '/faces/recognize'; // TODO: update if different

    if (_kBaseUrl.isEmpty) {
      debugPrint(
          '[FaceRecognition] Base URL not set — cannot perform recognition.');
      throw const BackendNotConfiguredException();
    }

    final uri = Uri.parse('$_kBaseUrl$endpoint');

    // Build multipart request to upload the captured face image
    final request = http.MultipartRequest('POST', uri);

    if (_kApiKey.isNotEmpty) {
      request.headers['X-Api-Key'] = _kApiKey;
    }
    // TODO: add Authorization header if using JWT
    // request.headers['Authorization'] = 'Bearer $yourToken';

    final file = File(imagePath);
    if (!file.existsSync()) {
      throw Exception('Captured image file not found: $imagePath');
    }

    // TODO: confirm field name your backend expects for the image
    request.files.add(
      await http.MultipartFile.fromPath(
        'image', // TODO: rename if your API uses a different field name
        file.path,
      ),
    );

    // TODO: add any extra fields your backend needs (e.g. camera type, timestamp)
    // request.fields['timestamp'] = DateTime.now().toIso8601String();

    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);

    if (response.statusCode == 200 || response.statusCode == 201) {
      final body = jsonDecode(response.body) as Map<String, dynamic>;

      // TODO: if your backend returns a "no match" as a 200 with a flag,
      // check that flag here and throw FaceNotRecognizedException accordingly.
      // Example:
      // if (body['matched'] == false) throw const FaceNotRecognizedException();

      return RecognitionResult.fromJson(body);
    } else if (response.statusCode == 404) {
      // Many backends return 404 when no face matches
      throw const FaceNotRecognizedException();
    } else {
      throw Exception(
          'Recognition API returned ${response.statusCode}: ${response.body}');
    }
  }
}

// ── Custom exceptions ─────────────────────────────────────────

class FaceNotRecognizedException implements Exception {
  const FaceNotRecognizedException();
  @override
  String toString() => 'No matching face found in the database.';
}

class BackendNotConfiguredException implements Exception {
  const BackendNotConfiguredException();
  @override
  String toString() =>
      'Face recognition backend not configured: set _kBaseUrl in face_recognition_datasource.dart';
}
