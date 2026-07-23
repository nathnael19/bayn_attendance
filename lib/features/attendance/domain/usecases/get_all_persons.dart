import '../entities/person.dart';
import '../repositories/person_repository.dart';

class GetAllPersons {
  final PersonRepository repository;

  const GetAllPersons(this.repository);

  Future<List<Person>> call() => repository.getAllPersons();
}
