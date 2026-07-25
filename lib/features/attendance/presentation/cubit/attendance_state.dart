import 'package:equatable/equatable.dart';
import '../../domain/entities/attendance_record.dart';

abstract class AttendanceState extends Equatable {
  const AttendanceState();

  @override
  List<Object> get props => [];
}

class AttendanceInitial extends AttendanceState {}

class AttendanceScanning extends AttendanceState {}

class AttendanceSuccess extends AttendanceState {
  final String employeeName;
  final String time;
  final double confidence;
  final ScanType scanType;

  const AttendanceSuccess({
    required this.employeeName,
    required this.time,
    this.confidence = 0.0,
    this.scanType = ScanType.checkIn,
  });

  @override
  List<Object> get props => [employeeName, time, confidence, scanType];
}

class AttendanceFailure extends AttendanceState {
  final String message;

  const AttendanceFailure({required this.message});

  @override
  List<Object> get props => [message];
}

class AttendanceAlreadyMarked extends AttendanceState {
  final String employeeName;
  final String time;

  const AttendanceAlreadyMarked({
    required this.employeeName,
    required this.time,
  });

  @override
  List<Object> get props => [employeeName, time];
}
