import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/usecases/get_all_persons.dart';
import 'users_state.dart';

class UsersCubit extends Cubit<UsersState> {
  final GetAllPersons getAllPersons;

  UsersCubit({required this.getAllPersons}) : super(const UsersInitial());

  Future<void> load() async {
    emit(const UsersLoading());
    try {
      final persons = await getAllPersons();
      emit(UsersLoaded(persons));
    } catch (e) {
      emit(UsersError(e.toString()));
    }
  }
}
