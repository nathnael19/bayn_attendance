import 'package:flutter_bloc/flutter_bloc.dart';
import 'attendance_state.dart';

class AttendanceCubit extends Cubit<AttendanceState> {
  AttendanceCubit() : super(AttendanceInitial());

  bool _isProcessing = false;

  /// Called when a face is detected in the camera frame.
  /// Starts the scan countdown only once per session.
  void onFaceDetected() {
    if (_isProcessing || state is! AttendanceInitial) return;
    _isProcessing = true;
    emit(AttendanceScanning());

    Future.delayed(const Duration(seconds: 3), () {
      if (isClosed) return;
      // Simulate recognition success — swap with real recognition result
      emit(const AttendanceSuccess(employeeName: 'John Doe', time: '08:30 AM'));
    });
  }

  /// Called when no face is visible — resets back to waiting state.
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
