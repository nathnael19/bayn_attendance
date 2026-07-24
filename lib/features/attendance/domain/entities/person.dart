import 'package:equatable/equatable.dart';

import 'face_embedding.dart';

/// Core domain model for a registered person.
class Person extends Equatable {
  final int? localId;
  final String? serverId;
  final String name;
  final String employeeId;
  final String department;
  final String? phone;
  final String? email;
  final String role;
  final String? pinCode;
  final bool isActive;
  final int? shiftId;

  final Map<String, List<String>> faceImagePaths;
  final List<FaceEmbedding> embeddings;

  final DateTime registeredAt;
  final bool isSynced;

  const Person({
    this.localId,
    this.serverId,
    required this.name,
    required this.employeeId,
    required this.department,
    this.phone,
    this.email,
    this.role = 'employee',
    this.pinCode,
    this.isActive = true,
    this.shiftId,
    this.faceImagePaths = const {},
    this.embeddings = const [],
    required this.registeredAt,
    this.isSynced = false,
  });

  Person copyWith({
    int? localId,
    String? serverId,
    String? name,
    String? employeeId,
    String? department,
    String? phone,
    String? email,
    String? role,
    String? pinCode,
    bool? isActive,
    int? shiftId,
    Map<String, List<String>>? faceImagePaths,
    List<FaceEmbedding>? embeddings,
    DateTime? registeredAt,
    bool? isSynced,
  }) {
    return Person(
      localId: localId ?? this.localId,
      serverId: serverId ?? this.serverId,
      name: name ?? this.name,
      employeeId: employeeId ?? this.employeeId,
      department: department ?? this.department,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      role: role ?? this.role,
      pinCode: pinCode ?? this.pinCode,
      isActive: isActive ?? this.isActive,
      shiftId: shiftId ?? this.shiftId,
      faceImagePaths: faceImagePaths ?? this.faceImagePaths,
      embeddings: embeddings ?? this.embeddings,
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
        phone,
        email,
        role,
        pinCode,
        isActive,
        shiftId,
        faceImagePaths,
        embeddings,
        registeredAt,
        isSynced,
      ];
}
