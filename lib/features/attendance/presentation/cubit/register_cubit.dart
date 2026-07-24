import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/face_embedding.dart';
import '../../domain/entities/person.dart';
import '../../domain/services/face_embedding_extractor.dart';
import '../../domain/usecases/register_person.dart';
import 'register_state.dart';

class RegisterCubit extends Cubit<RegisterState> {
  final RegisterPerson registerPersonUseCase;
  final FaceEmbeddingExtractor embeddingExtractor;

  RegisterCubit({
    required this.registerPersonUseCase,
    required this.embeddingExtractor,
  }) : super(const RegisterInitial());

  Future<void> submit({
    required String name,
    required String employeeId,
    required String department,
    required Map<String, List<String>> faceImagePaths,
  }) async {
    try {
      await embeddingExtractor.loadModel();

      final totalShots =
          faceImagePaths.values.fold(0, (sum, list) => sum + list.length);

      if (totalShots == 0) {
        emit(const RegisterFailure('No photos captured'));
        return;
      }

      final embeddings = <FaceEmbedding>[];
      var processed = 0;

      emit(RegisterProcessingEmbeddings(
        current: 0,
        total: totalShots,
      ));

      for (final entry in faceImagePaths.entries) {
        final label = entry.key;
        for (final path in entry.value) {
          try {
            final file = File(path);
            if (!file.existsSync()) continue;
            final bytes = await file.readAsBytes();
            final vector = await embeddingExtractor.extractEmbedding(bytes);
            embeddings.add(FaceEmbedding(
              personId: employeeId,
              label: label,
              embedding: vector,
              createdAt: DateTime.now(),
            ));
          } catch (e) {
            debugPrint('[RegisterCubit] Embedding failed for $path: $e');
          }
          processed++;
          emit(RegisterProcessingEmbeddings(
            current: processed,
            total: totalShots,
            embeddingsSoFar: List.from(embeddings),
          ));
        }
      }

      emit(const RegisterLoading());

      final person = await registerPersonUseCase(
        Person(
          name: name,
          employeeId: employeeId,
          department: department,
          faceImagePaths: faceImagePaths,
          embeddings: embeddings,
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
