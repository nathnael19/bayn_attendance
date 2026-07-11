import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/attendance_record_model.dart';

// ─────────────────────────────────────────────────────────────
//  TODO (Backend team): fill in your API details below
// ─────────────────────────────────────────────────────────────

/// Base URL of your backend (same server as person registration).
/// Example: 'https://api.yourserver.com/v1'
// TODO: replace with your actual base URL
const String _kBaseUrl = '';

/// API key if required. Leave empty if using JWT/OAuth.
// TODO: add your API key or remove if not needed
const String _kApiKey = '';

// ─────────────────────────────────────────────────────────────

abstract class AttendanceRemoteDatasource {
  /// Log a check-in event to the backend.
  /// Returns the server-assigned record ID on success.
  Future<String> logAttendance(AttendanceRecordModel record);

  /// Bulk-push a list of un-synced records.
  Future<void> syncRecords(List<AttendanceRecordModel> records);
}

class AttendanceRemoteDatasourceImpl implements AttendanceRemoteDatasource {
  final http.Client httpClient;
  AttendanceRemoteDatasourceImpl({required this.httpClient});

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (_kApiKey.isNotEmpty) 'X-Api-Key': _kApiKey,
        // TODO: add Authorization header if using JWT
        // 'Authorization': 'Bearer $yourToken',
      };

  @override
  Future<String> logAttendance(AttendanceRecordModel record) async {
    // TODO (Backend team): confirm endpoint path with your API docs.
    // Example: POST /attendance/log
    const endpoint = '/attendance/log'; // TODO: update if different

    if (_kBaseUrl.isEmpty) {
      debugPrint(
          '[AttendanceRemote] Base URL not set — skipping remote log.');
      throw const _BackendNotConfiguredException();
    }

    final uri = Uri.parse('$_kBaseUrl$endpoint');
    final response = await httpClient.post(
      uri,
      headers: _headers,
      body: jsonEncode(record.toJson()),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      // TODO: adjust key to match your API response shape
      // e.g. { "record_id": "abc123" }
      return body['id']?.toString() ??
          body['record_id']?.toString() ??
          '';
    } else {
      throw Exception(
          'Backend returned ${response.statusCode}: ${response.body}');
    }
  }

  @override
  Future<void> syncRecords(List<AttendanceRecordModel> records) async {
    if (_kBaseUrl.isEmpty) {
      debugPrint('[AttendanceRemote] Base URL not set — skipping sync.');
      return;
    }
    for (final record in records) {
      try {
        await logAttendance(record);
      } catch (e) {
        debugPrint(
            '[AttendanceRemote] Sync failed for ${record.personName}: $e');
      }
    }
  }
}

class _BackendNotConfiguredException implements Exception {
  const _BackendNotConfiguredException();
  @override
  String toString() =>
      'Backend not configured: set _kBaseUrl in attendance_remote_datasource.dart';
}
