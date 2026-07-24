# AI Face Recognition Attendance System

A Flutter-based kiosk application that uses on-device AI and facial recognition to automatically record employee attendance — no buttons, no badges, no contact required.

---

## Overview

Employees walk up to the kiosk, their face is detected by the front camera, and attendance is recorded in under a second. First-time users go through a quick face enrollment flow; returning users are recognized and checked in/out automatically.

The system runs entirely on-device for recognition (no internet required for face matching), with optional sync to a remote server.

---

## Features

- **Automatic face recognition** — no manual action needed from the employee
- **On-device inference** — MobileFaceNet model via TFLite, works offline
- **Face enrollment** — multi-angle capture (straight, left, right, up, down) for high accuracy
- **Check-in / Check-out tracking** — full session recording with timestamps
- **Shift awareness** — on-time, late, and early-leave detection
- **Text-to-speech feedback** — audible confirmation on recognition
- **PIN fallback** — optional PIN entry if face recognition fails
- **Local SQLite database** — all data stored on-device, synced when online
- **Kiosk mode** — lockdown navigation for dedicated hardware deployments
- **Audit log** — immutable record of all actions for security and debugging

---

## Screens

| Screen | Description |
|---|---|
| **Splash** | Loads saved state and routes to Signup or Attendance |
| **Signup** | Employee registration with personal info and multi-angle face enrollment |
| **Attendance** | Live camera feed with automatic face detection and recognition |

---

## Architecture

Feature-based Clean Architecture with BLoC/Cubit for state management.

```
lib/
├── core/
│   ├── database/       # SQLite helper (sqflite)
│   ├── error/          # Failure types
│   ├── network/        # HTTP client setup
│   ├── theme/          # App-wide theme
│   └── usecases/       # Base use case interface
├── features/
│   ├── auth/           # Signup & face enrollment
│   │   ├── data/
│   │   ├── domain/
│   │   └── presentation/
│   │       ├── cubit/
│   │       └── pages/
│   └── attendance/     # Face recognition & check-in/out
│       ├── data/
│       ├── domain/
│       └── presentation/
│           ├── cubit/
│           ├── pages/
│           ├── widgets/
│           └── utils/
├── injection_container.dart  # get_it DI setup
└── main.dart
```

---

## Tech Stack

| Layer | Package |
|---|---|
| State management | `flutter_bloc` + `equatable` |
| Dependency injection | `get_it` |
| Functional types | `dartz` |
| Camera | `camera` |
| Face detection | `google_mlkit_face_detection` |
| Face embedding model | `tflite_flutter` (MobileFaceNet, 192-dim) |
| Local database | `sqflite` |
| Text-to-speech | `flutter_tts` |
| HTTP client | `http` |
| Image processing | `image` |
| Fonts | `google_fonts` |
| Storage paths | `path_provider` + `path` |

---

## Database Schema

The local SQLite database has the following tables:

| Table | Purpose |
|---|---|
| `persons` | Registered employees with metadata and face image paths |
| `face_embeddings` | 192-dim MobileFaceNet vectors per person |
| `attendance_records` | Flat check-in event log |
| `attendance_sessions` | Full check-in/check-out sessions with hours and overtime |
| `shifts` | Shift definitions (start/end time, grace period, break times) |
| `devices` | Kiosk device registry for multi-device environments |
| `audit_logs` | Immutable action log |
| `settings` | Key-value configuration store |

See [`DATABASE_SCHEMA.md`](DATABASE_SCHEMA.md) for full column definitions.

---

## API Endpoints

The app communicates with an optional backend for registration and sync.

### Register Employee

```
POST /api/register
```

```json
{
  "name": "John Doe",
  "employee_id": "EMP001",
  "face_images": ["<base64>", "..."]
}
```

### Record Attendance

```
POST /api/attendance/check
```

```json
{
  "face_image": "<base64>"
}
```

Response (success):

```json
{
  "status": "success",
  "employee_name": "John Doe",
  "attendance_type": "Check In",
  "time": "08:30 AM"
}
```

---

## Getting Started

### Prerequisites

- Flutter SDK `^3.12.1`
- Dart SDK `^3.12.1`
- A device or emulator with a front-facing camera

### Setup

```bash
# Clone the repo
git clone <repo-url>
cd attendance_management_system

# Install dependencies
flutter pub get

# Run on a connected device
flutter run
```

> The TFLite model must be placed in `assets/models/` before building. The app will not perform face recognition without it.

### Build

```bash
# Android
flutter build apk --release

# iOS
flutter build ipa --release
```

---

## Configuration

Runtime behavior is controlled via the `settings` table in SQLite. Key settings:

| Key | Default | Description |
|---|---|---|
| `recognition_threshold` | `0.65` | Cosine similarity threshold for a valid match |
| `kiosk_mode_enabled` | `false` | Lock navigation for dedicated kiosk hardware |
| `auto_attendance_redirect` | `true` | Auto-navigate after successful face detection |
| `tts_enabled` | `true` | Enable text-to-speech feedback |
| `sync_interval_minutes` | `30` | How often to sync with the remote server |
| `check_in_only` | `false` | Skip checkout flow entirely |
| `require_pin_fallback` | `false` | Allow PIN entry when face recognition fails |
| `office_name` | `""` | Location label attached to attendance records |

---

## Security

- Face embeddings are stored locally as serialized vectors, not raw images
- API communication uses HTTPS
- No raw passwords stored on device
- PIN codes are hashed before storage
- All actions are written to the immutable `audit_logs` table

---

## Roadmap

- [ ] Attendance history screen for employees
- [ ] Admin dashboard for HR/management
- [ ] Offline-first sync with conflict resolution
- [ ] Liveness detection to prevent photo spoofing
- [ ] Push notifications for missed check-ins
- [ ] Attendance reports (PDF/CSV export)
- [ ] Multi-shift support per employee
