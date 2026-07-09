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

  const AttendanceSuccess({required this.employeeName, required this.time});

  @override
  List<Object> get props => [employeeName, time];
}

class AttendanceFailure extends AttendanceState {
  final String message;

  const AttendanceFailure({required this.message});

  @override
  List<Object> get props => [message];
}
