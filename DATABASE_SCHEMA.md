# Database Schema — Attendance Management System (Kiosk)

## Current Tables (SQLite v4)

### `persons`

Registered individuals for facial recognition.

| Column | Type | Constraints | Notes |
|---|---|---|---|
| `id` | INTEGER | PRIMARY KEY AUTOINCREMENT | Local ID |
| `server_id` | TEXT | | Remote server UUID |
| `name` | TEXT | NOT NULL | |
| `employee_id` | TEXT | NOT NULL UNIQUE | |
| `department` | TEXT | NOT NULL | |
| `phone` | TEXT | | Contact number |
| `email` | TEXT | | |
| `role` | TEXT | NOT NULL DEFAULT 'employee' | `admin`, `manager`, `employee` |
| `pin_code` | TEXT | | 4-6 digit PIN fallback (hashed) |
| `is_active` | INTEGER | NOT NULL DEFAULT 1 | Soft-delete / deactivate |
| `shift_id` | INTEGER | | FK to shifts.id — default shift assignment |
| `face_image_paths` | TEXT | NOT NULL DEFAULT '{}' | JSON map of angle -> file paths |
| `registered_at` | TEXT | NOT NULL | ISO 8601 |
| `is_synced` | INTEGER | NOT NULL DEFAULT 0 | 0 = pending, 1 = synced |

### `attendance_records`

Check-in events.

| Column | Type | Constraints | Notes |
|---|---|---|---|
| `id` | INTEGER | PRIMARY KEY AUTOINCREMENT | Local ID |
| `server_id` | TEXT | | Remote server UUID |
| `person_id` | TEXT | | Matches persons.employee_id |
| `person_name` | TEXT | NOT NULL | |
| `department` | TEXT | NOT NULL DEFAULT '' | |
| `confidence` | REAL | NOT NULL DEFAULT 0.0 | Face match score (0.0–1.0) |
| `checked_in_at` | TEXT | NOT NULL | ISO 8601 |
| `checked_out_at` | TEXT | | ISO 8601 — nullable, covers full session |
| `status` | TEXT | NOT NULL DEFAULT 'present' | `on_time`, `late`, `early_leave` |
| `shift_id` | INTEGER | | FK to shifts.id |
| `location` | TEXT | | Which kiosk/device captured it |
| `scan_type` | TEXT | NOT NULL DEFAULT 'check_in' | `check_in`, `lunch_break`, `check_out` |
| `is_synced` | INTEGER | NOT NULL DEFAULT 0 | 0 = pending, 1 = synced |

### `face_embeddings`

192-dim facial feature vectors (MobileFaceNet).

| Column | Type | Constraints | Notes |
|---|---|---|---|
| `id` | INTEGER | PRIMARY KEY AUTOINCREMENT | |
| `person_id` | TEXT | NOT NULL | FK to persons.employee_id |
| `label` | TEXT | | Descriptive label |
| `embedding` | BLOB | NOT NULL | Serialized Float32List |
| `created_at` | TEXT | NOT NULL | ISO 8601 |

**Index:** `idx_embeddings_person_id` on `face_embeddings(person_id)`

---

## Proposed New Tables

### `shifts`

Work shift definitions for schedule enforcement.

| Column | Type | Constraints | Notes |
|---|---|---|---|
| `id` | INTEGER | PRIMARY KEY AUTOINCREMENT | |
| `server_id` | TEXT | | Remote UUID |
| `name` | TEXT | NOT NULL | e.g. "Morning", "Night", "Flex" |
| `start_time` | TEXT | NOT NULL | HH:mm (24h) |
| `end_time` | TEXT | NOT NULL | HH:mm (24h) |
| `grace_minutes` | INTEGER | NOT NULL DEFAULT 0 | Late grace period before marked "late" |
| `min_work_hours` | REAL | NOT NULL DEFAULT 8.0 | Required hours per session |
| `break_start` | TEXT | | HH:mm — lunch break start |
| `break_end` | TEXT | | HH:mm — lunch break end |
| `is_active` | INTEGER | NOT NULL DEFAULT 1 | Soft disable |
| `is_synced` | INTEGER | NOT NULL DEFAULT 0 | |

### `attendance_sessions`

Full check-in/check-out sessions (replaces flat `attendance_records` over time).

| Column | Type | Constraints | Notes |
|---|---|---|---|
| `id` | INTEGER | PRIMARY KEY AUTOINCREMENT | |
| `server_id` | TEXT | | Remote UUID |
| `person_id` | TEXT | NOT NULL | FK to persons.employee_id |
| `shift_id` | INTEGER | | FK to shifts.id |
| `checked_in_at` | TEXT | NOT NULL | ISO 8601 |
| `checked_out_at` | TEXT | | ISO 8601 — nullable until checkout |
| `check_in_confidence` | REAL | NOT NULL DEFAULT 0.0 | |
| `check_out_confidence` | REAL | | Nullable |
| `check_in_device_id` | TEXT | | FK to devices.device_id |
| `check_out_device_id` | TEXT | | FK to devices.device_id |
| `check_in_image_path` | TEXT | | Captured face photo |
| `check_out_image_path` | TEXT | | Captured face photo |
| `status` | TEXT | NOT NULL DEFAULT 'present' | `present`, `late`, `early_leave`, `absent` |
| `total_hours` | REAL | | Computed: checkout - checkin (hours) |
| `overtime_minutes` | INTEGER | NOT NULL DEFAULT 0 | Beyond shift end_time |
| `notes` | TEXT | | Manual override reason |
| `is_synced` | INTEGER | NOT NULL DEFAULT 0 | |

### `devices`

Kiosk device registry for multi-kiosk environments.

| Column | Type | Constraints | Notes |
|---|---|---|---|
| `id` | INTEGER | PRIMARY KEY AUTOINCREMENT | |
| `server_id` | TEXT | | Remote UUID |
| `device_id` | TEXT | NOT NULL UNIQUE | Hardware-derived or assigned |
| `name` | TEXT | NOT NULL | e.g. "Main Gate Kiosk A" |
| `location` | TEXT | | e.g. "Building 1, Floor 2" |
| `model` | TEXT | | Device model string |
| `os_version` | TEXT | | Android/iOS version |
| `app_version` | TEXT | | Installed app version |
| `last_heartbeat` | TEXT | | ISO 8601 — last health check |
| `is_active` | INTEGER | NOT NULL DEFAULT 1 | |
| `is_synced` | INTEGER | NOT NULL DEFAULT 0 | |

### `audit_logs`

Immutable action log for security & debugging.

| Column | Type | Constraints | Notes |
|---|---|---|---|
| `id` | INTEGER | PRIMARY KEY AUTOINCREMENT | |
| `action` | TEXT | NOT NULL | e.g. `face_registered`, `sync_pulled`, `user_deleted`, `settings_changed` |
| `performed_by` | TEXT | | person_id, device_id, or "system" |
| `target_id` | TEXT | | Affected entity ID |
| `details` | TEXT | | JSON blob with extra context |
| `created_at` | TEXT | NOT NULL | ISO 8601 |

### `settings`

Key-value kiosk configuration (replaces hardcoded flags).

| Column | Type | Constraints | Notes |
|---|---|---|---|
| `id` | INTEGER | PRIMARY KEY AUTOINCREMENT | |
| `key` | TEXT | NOT NULL UNIQUE | |
| `value` | TEXT | NOT NULL | |
| `updated_at` | TEXT | NOT NULL | ISO 8601 |

**Preseeded keys:**

| Key | Type | Default | Purpose |
|---|---|---|---|
| `kiosk_mode_enabled` | bool | `false` | Lock down navigation |
| `auto_attendance_redirect` | bool | `true` | Auto-navigate on face detect |
| `recognition_threshold` | double | `0.65` | Cosine similarity threshold |
| `tts_enabled` | bool | `true` | Text-to-speech feedback |
| `sync_interval_minutes` | int | `30` | Auto-sync interval |
| `check_in_only` | bool | `false` | If true, skip checkout flow |
| `require_pin_fallback` | bool | `false` | Allow PIN if face fails |
| `office_name` | string | `""` | Location label for records |

---

## Entity Relationship Summary

## Entity Relationship Summary

```
persons 1───* face_embeddings
persons 1───* attendance_sessions
persons *───1 shifts (via default_shift_id)
shifts 1───* attendance_sessions
devices 1───* attendance_sessions
persons 1───* audit_logs
settings (standalone key-value store)
```