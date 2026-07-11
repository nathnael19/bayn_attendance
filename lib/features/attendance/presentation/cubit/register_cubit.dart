import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/person.dart';
import '../../domain/usecases/register_person.dart';
import 'register_state.dart';

class RegisterCubit extends Cubit<RegisterState> {
  final RegisterPerson registerPersonUseCase;

  RegisterCubit({required this.registerPersonUseCase})
      : super(const RegisterInitial());

  /// Called after the user finishes both the form and the photo capture steps.
  Future<void> submit({
    required String name,
    required String employeeId,
    required String department,
    required Map<String, List<String>> faceImagePaths,
  }) async {
    emit(const RegisterLoading());
    try {
      final person = await registerPersonUseCase(
        Person(
          name: name,
          employeeId: employeeId,
          department: department,
          faceImagePaths: faceImagePaths,
          registeredAt: DateTime.now(),
        ),
      );
      emit(RegisterSuccess(person));
    } catch (e) {
      emit(RegisterFailure(e.toString()));
    }
  }

  void reset() => emit(const RegisterInitial());
}
