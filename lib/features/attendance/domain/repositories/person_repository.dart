import '../entities/person.dart';

/// Abstract contract for person persistence.
/// Implemented in the data layer.
/// Result of a pull-from-server sync operation.
class SyncResult {
  final int employeesSynced;
  final int embeddingsSynced;

  const SyncResult({
    required this.employeesSynced,
    required this.embeddingsSynced,
  });
}

abstract class PersonRepository {
  /// Save a new person locally and attempt a backend sync.
  Future<Person> register(Person person, {bool saveImages = false});

  /// Fetch all locally stored persons.
  Future<List<Person>> getAllPersons();

  /// Try to push any un-synced records to the backend.
  Future<void> syncPending();

  /// Download all employees + embeddings from the server,
  /// replace local data, and reload the recognition cache.
  Future<SyncResult> pullFromServer();

  /// Delete a person and their face data by employee ID.
  Future<void> deletePerson(String employeeId);
}
