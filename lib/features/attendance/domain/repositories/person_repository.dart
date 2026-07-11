import '../entities/person.dart';

/// Abstract contract for person persistence.
/// Implemented in the data layer.
abstract class PersonRepository {
  /// Save a new person locally and attempt a backend sync.
  /// Always returns the locally-saved [Person] (with [localId] set).
  Future<Person> register(Person person);

  /// Fetch all locally stored persons.
  Future<List<Person>> getAllPersons();

  /// Try to push any un-synced records to the backend.
  Future<void> syncPending();
}
