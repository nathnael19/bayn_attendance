import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/repositories/person_repository.dart';
import 'users_state.dart';

class UsersCubit extends Cubit<UsersState> {
  final PersonRepository repository;

  UsersCubit({required this.repository}) : super(const UsersInitial());

  Future<void> load() async {
    emit(const UsersLoading());
    try {
      final persons = await repository.getAllPersons();
      emit(UsersLoaded(persons));
    } catch (e) {
      emit(UsersError(e.toString()));
    }
  }

  Future<void> deletePerson(String employeeId, {bool deleteFromServer = false}) async {
    final current = state;
    if (current is! UsersLoaded) return;

    final previousPersons = current.persons;
    emit(UsersLoaded(
      previousPersons.where((p) => p.employeeId != employeeId).toList(),
    ));

    try {
      await repository.deletePerson(employeeId);
      if (deleteFromServer) {
        // TODO: call remote delete when backend supports it
      }
    } catch (e) {
      emit(UsersLoaded(previousPersons));
      rethrow;
    }
  }
}
