import 'package:equatable/equatable.dart';

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

  const AttendanceSuccess({
    required this.employeeName,
    required this.time,
    this.confidence = 0.0,
  });

  @override
  List<Object> get props => [employeeName, time, confidence];
}

class AttendanceFailure extends AttendanceState {
  final String message;

  const AttendanceFailure({required this.message});

  @override
  List<Object> get props => [message];
}
