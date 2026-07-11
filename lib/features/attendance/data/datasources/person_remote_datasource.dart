import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/person_model.dart';

// ─────────────────────────────────────────────────────────────
//  TODO (Backend team): fill in your API details below
// ─────────────────────────────────────────────────────────────

/// Base URL of your face-recognition backend.
/// Example: 'https://api.yourserver.com/v1'
// TODO: replace empty string with your actual base URL
const String _kBaseUrl = '';

/// If your API requires a fixed API key, set it here.
/// Leave empty and handle auth differently if you use JWT / OAuth.
// TODO: add your API key or remove if not needed
const String _kApiKey = '';

// ─────────────────────────────────────────────────────────────

/// Handles all communication with the remote backend.
abstract class PersonRemoteDatasource {
  /// Register a person on the backend.
  /// Sends profile data + face images as a multipart request.
  /// Returns the backend-assigned [serverId] on success.
  Future<String> registerPerson(PersonModel person);

  /// Push a list of already-locally-stored persons that haven't been synced.
  Future<void> syncPersons(List<PersonModel> persons);
}

class PersonRemoteDatasourceImpl implements PersonRemoteDatasource {
  final http.Client httpClient;

  PersonRemoteDatasourceImpl({required this.httpClient});

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (_kApiKey.isNotEmpty) 'X-Api-Key': _kApiKey,
        // TODO: add Authorization header if using JWT
        // 'Authorization': 'Bearer $yourToken',
      };

  @override
  Future<String> registerPerson(PersonModel person) async {
    // TODO (Backend team): confirm the exact endpoint path with your API docs.
    // Example endpoint: POST /persons/register
    const endpoint = '/persons/register'; // TODO: update if different

    if (_kBaseUrl.isEmpty) {
      // No backend configured yet — skip silently so local save still works.
      debugPrint('[RemoteDatasource] Base URL not set — skipping remote sync.');
      throw const _BackendNotConfiguredException();
    }

    final uri = Uri.parse('$_kBaseUrl$endpoint');

    // Build multipart request so we can attach face images
    final request = http.MultipartRequest('POST', uri);
    request.headers.addAll(_headers..remove('Content-Type'));

    // ── Profile fields ────────────────────────────────────────
    // TODO: adjust field names to match your backend's expected body
    request.fields['name'] = person.name;
    request.fields['employee_id'] = person.employeeId;
    request.fields['department'] = person.department;
    request.fields['registered_at'] = person.registeredAt.toIso8601String();

    // ── Face images ───────────────────────────────────────────
    // Attach every image. We label them as: face_front_0, face_left_1, …
    // TODO: confirm image field naming convention with your backend team
    for (final entry in person.faceImagePaths.entries) {
      final angle = entry.key;
      final paths = entry.value;
      for (var i = 0; i < paths.length; i++) {
        final file = File(paths[i]);
        if (!file.existsSync()) continue;
        request.files.add(
          await http.MultipartFile.fromPath(
            'face_${angle}_$i', // TODO: rename field if your API differs
            file.path,
          ),
        );
      }
    }

    // ── Send ──────────────────────────────────────────────────
    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);

    if (response.statusCode == 200 || response.statusCode == 201) {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      // TODO: adjust the key below to match your API's response shape
      // e.g. if your API returns { "person_id": "abc123" } use 'person_id'
      final serverId = body['id']?.toString() ??
          body['person_id']?.toString() ??
          '';
      return serverId;
    } else {
      throw HttpException(
        'Backend returned ${response.statusCode}: ${response.body}',
      );
    }
  }

  @override
  Future<void> syncPersons(List<PersonModel> persons) async {
    if (_kBaseUrl.isEmpty) {
      debugPrint('[RemoteDatasource] Base URL not set — skipping sync.');
      return;
    }

    // TODO: implement a bulk-sync endpoint if your backend supports it,
    // or loop and call registerPerson one by one as a fallback.
    for (final person in persons) {
      try {
        await registerPerson(person);
      } catch (e) {
        debugPrint('[RemoteDatasource] Sync failed for ${person.name}: $e');
        // Continue trying others even if one fails
      }
    }
  }
}

/// Thrown when [_kBaseUrl] is empty so callers can handle gracefully.
class _BackendNotConfiguredException implements Exception {
  const _BackendNotConfiguredException();
  @override
  String toString() => 'Backend not configured: set _kBaseUrl in person_remote_datasource.dart';
}
