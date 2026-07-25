import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/datasources/face_recognition_datasource.dart';
import '../../domain/entities/attendance_record.dart';
import '../../domain/repositories/attendance_repository.dart';
import '../../domain/usecases/log_attendance.dart';
import 'attendance_state.dart';

class AttendanceCubit extends Cubit<AttendanceState> {
  final FaceRecognitionDatasource faceRecognition;
  final LogAttendance logAttendance;

  AttendanceCubit({required this.faceRecognition, required this.logAttendance})
    : super(AttendanceInitial());

  bool _isProcessing = false;

  /// Called by the page when a face is first detected in the frame.
  /// Switches to scanning state so the page can capture a still image.
  void onFaceDetected() {
    if (_isProcessing || state is! AttendanceInitial) return;
    _isProcessing = true;
    emit(AttendanceScanning());
  }

  /// Called by the page after capturing a still image during scanning.
  /// Sends the image to the local recognizer, then logs the result locally.
  Future<void> recognizeFace(String imagePath) async {
    if (state is! AttendanceScanning) return;

    try {
      // ── Call face recognition matcher ──────────────────────
      final result = await faceRecognition.recognize(imagePath);

      // ── Log the attendance scan (type determined by the repository) ─
      final logged = await logAttendance(
        AttendanceRecord(
          personId: result.personId,
          personName: result.personName,
          department: result.department,
          confidence: result.confidence,
          checkedInAt: DateTime.now(),
        ),
      );

      final now = DateTime.now();
      final hour = now.hour;
      final minute = now.minute.toString().padLeft(2, '0');
      final period = hour >= 12 ? 'PM' : 'AM';
      final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
      final timeStr = '$displayHour:$minute $period';

      emit(
        AttendanceSuccess(
          employeeName: result.personName,
          time: timeStr,
          confidence: result.confidence,
          scanType: logged.scanType,
        ),
      );
    } on FaceNotRecognizedException {
      _isProcessing = false;
      emit(
        const AttendanceFailure(
          message: 'Face not recognized. Please try again.',
        ),
      );
    } on DuplicateAttendanceException catch (e) {
      _isProcessing = false;
      final hour = e.checkedInAt.hour;
      final minute = e.checkedInAt.minute.toString().padLeft(2, '0');
      final period = hour >= 12 ? 'PM' : 'AM';
      final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
      final timeStr = '$displayHour:$minute $period';
      emit(AttendanceAlreadyMarked(employeeName: e.personName, time: timeStr));
    } catch (e) {
      _isProcessing = false;
      emit(
        AttendanceFailure(message: 'Something went wrong. Please try again.'),
      );
    }
  }

  /// Called when the face disappears before scanning completes.
  void onFaceLost() {
    if (state is AttendanceScanning || state is AttendanceInitial) {
      _isProcessing = false;
      emit(AttendanceInitial());
    }
  }

  /// Retry after a failure.
  void startScanning() {
    _isProcessing = false;
    emit(AttendanceInitial());
  }

  void reset() {
    _isProcessing = false;
    emit(AttendanceInitial());
  }
}
