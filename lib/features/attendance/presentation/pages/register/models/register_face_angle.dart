import 'package:flutter/material.dart';

enum FaceAngle { front, left, right, up, down }

extension FaceAngleX on FaceAngle {
  String get label {
    switch (this) {
      case FaceAngle.front:
        return 'Look straight';
      case FaceAngle.left:
        return 'Turn left';
      case FaceAngle.right:
        return 'Turn right';
      case FaceAngle.up:
        return 'Tilt up';
      case FaceAngle.down:
        return 'Tilt down';
    }
  }

  IconData get icon {
    switch (this) {
      case FaceAngle.front:
        return Icons.face_rounded;
      case FaceAngle.left:
        return Icons.arrow_back_rounded;
      case FaceAngle.right:
        return Icons.arrow_forward_rounded;
      case FaceAngle.up:
        return Icons.arrow_upward_rounded;
      case FaceAngle.down:
        return Icons.arrow_downward_rounded;
    }
  }
}
