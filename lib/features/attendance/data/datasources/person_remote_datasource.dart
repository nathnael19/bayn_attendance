import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/face_embedding_model.dart';
import '../models/person_model.dart';

const String _kBaseUrl = String.fromEnvironment(
  'BAYN_API_BASE_URL',
  defaultValue: '',
);

const String _kApiKey = String.fromEnvironment(
  'BAYN_API_KEY',
  defaultValue: '',
);

const String _kRegisterEndpoint = '/api/employees';

abstract class PersonRemoteDatasource {
  Future<String> registerPerson(
    PersonModel person, {
    List<FaceEmbeddingModel>? embeddings,
  });

  Future<void> syncPersons(List<PersonModel> persons);

  Future<List<RemoteEmployee>> fetchAllEmployees();

  /// Push all un-synced persons to the server.
  /// Returns count of persons successfully pushed.
  Future<int> pushUnsyncedPersons(List<PersonModel> persons);
}

class PersonRemoteDatasourceImpl implements PersonRemoteDatasource {
  final http.Client httpClient;

  PersonRemoteDatasourceImpl({required this.httpClient});

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    if (_kApiKey.isNotEmpty) 'X-Api-Key': _kApiKey,
  };

  @override
  Future<String> registerPerson(
    PersonModel person, {
    List<FaceEmbeddingModel>? embeddings,
  }) async {
    if (_kBaseUrl.isEmpty) {
      debugPrint('[RemoteDatasource] Base URL not set — skipping remote sync.');
      throw const BackendNotConfiguredException();
    }

    final uri = Uri.parse('$_kBaseUrl$_kRegisterEndpoint');
    final body = <String, dynamic>{};

    body['name'] = person.name;
    body['employee_id'] = person.employeeId;
    body['department'] = person.department;
    body['registered_at'] = person.registeredAt.toIso8601String();

    if (embeddings != null && embeddings.isNotEmpty) {
      body['embeddings'] = embeddings.map((e) => e.toJson()).toList();
      body['embedding_dimension'] = embeddings.first.embedding.length;
    }

    final jsonBody = jsonEncode(body);

    final response = await httpClient.post(
      uri,
      headers: _headers,
      body: jsonBody,
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final responseBody = jsonDecode(response.body) as Map<String, dynamic>;
      final serverId =
          responseBody['id']?.toString() ??
          responseBody['person_id']?.toString() ??
          responseBody['server_id']?.toString() ??
          '';
      return serverId;
    } else {
      throw Exception(
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

    for (final person in persons) {
      try {
        await registerPerson(person);
      } catch (e) {
        debugPrint('[RemoteDatasource] Sync failed for ${person.name}: $e');
      }
    }
  }

  @override
  Future<List<RemoteEmployee>> fetchAllEmployees() async {
    if (_kBaseUrl.isEmpty) {
      debugPrint('[RemoteDatasource] Base URL not set — skipping fetch.');
      throw const BackendNotConfiguredException();
    }

    final uri = Uri.parse('$_kBaseUrl$_kRegisterEndpoint');
    final response = await httpClient.get(
      uri,
      headers: {if (_kApiKey.isNotEmpty) 'X-Api-Key': _kApiKey},
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Fetch employees returned ${response.statusCode}: ${response.body}',
      );
    }

    final list = jsonDecode(response.body) as List<dynamic>;
    return list
        .map((e) => RemoteEmployee.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<int> pushUnsyncedPersons(List<PersonModel> persons) async {
    if (_kBaseUrl.isEmpty) {
      debugPrint('[RemoteDatasource] Base URL not set — skipping push.');
      return 0;
    }

    int successCount = 0;
    for (final person in persons) {
      try {
        await registerPerson(person);
        successCount++;
      } catch (e) {
        debugPrint('[RemoteDatasource] Push failed for ${person.name}: $e');
      }
    }
    return successCount;
  }
}

// ── Transfer objects ─────────────────────────────────────────

class RemoteEmployee {
  final String serverId;
  final String name;
  final String employeeId;
  final String department;
  final DateTime registeredAt;
  final List<RemoteEmbedding> embeddings;

  const RemoteEmployee({
    this.serverId = '',
    required this.name,
    required this.employeeId,
    required this.department,
    required this.registeredAt,
    this.embeddings = const [],
  });

  factory RemoteEmployee.fromJson(Map<String, dynamic> json) {
    final rawEmbeddings = json['embeddings'] as List<dynamic>? ?? [];
    return RemoteEmployee(
      serverId:
          json['server_id']?.toString() ??
          json['employee_id']?.toString() ??
          '',
      name: json['name']?.toString() ?? '',
      employeeId: json['employee_id']?.toString() ?? '',
      department: json['department']?.toString() ?? '',
      registeredAt:
          DateTime.tryParse(json['registered_at']?.toString() ?? '') ??
          DateTime.now(),
      embeddings: rawEmbeddings
          .map((e) => RemoteEmbedding.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class RemoteEmbedding {
  final String? label;
  final Float32List vector;

  const RemoteEmbedding({this.label, required this.vector});

  factory RemoteEmbedding.fromJson(Map<String, dynamic> json) {
    final raw = json['vector'] as List<dynamic>;
    final list = Float32List(raw.length);
    for (var i = 0; i < raw.length; i++) {
      list[i] = (raw[i] as num).toDouble();
    }
    return RemoteEmbedding(label: json['label']?.toString(), vector: list);
  }
}

class BackendNotConfiguredException implements Exception {
  const BackendNotConfiguredException();
  @override
  String toString() =>
      'Backend not configured: set BAYN_API_BASE_URL --dart-define';
}
