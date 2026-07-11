import '../entities/person.dart';
import '../repositories/person_repository.dart';

/// Use-case: register a new person (local save + optional backend sync).
class RegisterPerson {
  final PersonRepository repository;

  const RegisterPerson(this.repository);

  Future<Person> call(Person person) => repository.register(person);
}
