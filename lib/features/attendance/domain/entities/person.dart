import 'package:equatable/equatable.dart';

/// Core domain model for a registered person.
class Person extends Equatable {
  final int? localId;       // SQLite row id (null before first save)
  final String? serverId;   // ID returned by the backend (null until synced)
  final String name;
  final String employeeId;
  final String department;

  /// Map of angle label → list of absolute image file paths stored locally.
  /// e.g. { 'front': ['/data/.../front_0.jpg', ...], 'left': [...] }
  final Map<String, List<String>> faceImagePaths;

  final DateTime registeredAt;
  final bool isSynced; // true once successfully pushed to backend

  const Person({
    this.localId,
    this.serverId,
    required this.name,
    required this.employeeId,
    required this.department,
    required this.faceImagePaths,
    required this.registeredAt,
    this.isSynced = false,
  });

  Person copyWith({
    int? localId,
    String? serverId,
    String? name,
    String? employeeId,
    String? department,
    Map<String, List<String>>? faceImagePaths,
    DateTime? registeredAt,
    bool? isSynced,
  }) {
    return Person(
      localId: localId ?? this.localId,
      serverId: serverId ?? this.serverId,
      name: name ?? this.name,
      employeeId: employeeId ?? this.employeeId,
      department: department ?? this.department,
      faceImagePaths: faceImagePaths ?? this.faceImagePaths,
      registeredAt: registeredAt ?? this.registeredAt,
      isSynced: isSynced ?? this.isSynced,
    );
  }

  @override
  List<Object?> get props => [
        localId,
        serverId,
        name,
        employeeId,
        department,
        faceImagePaths,
        registeredAt,
        isSynced,
      ];
}
