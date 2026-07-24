import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

/// Single shared SQLite database for the entire app.
/// Add new tables here and bump [_kVersion] with a migration.
class DatabaseHelper {
  DatabaseHelper._();
  static DatabaseHelper instance = DatabaseHelper._();

  static Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDb();
    return _db!;
  }

  static const int _kVersion = 4;

  Future<Database> _initDb() async {
    final docsDir = await getApplicationDocumentsDirectory();
    final path = p.join(docsDir.path, 'bayn_attendance.db');

    return openDatabase(
      path,
      version: _kVersion,
      onCreate: (db, _) async {
        await _createPersonsTable(db);
        await _createAttendanceTable(db);
        await _createFaceEmbeddingsTable(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await _createAttendanceTable(db);
        }
        if (oldVersion < 3) {
          await _createFaceEmbeddingsTable(db);
        }
        if (oldVersion < 4) {
          try {
            await db.execute('ALTER TABLE persons ADD COLUMN name TEXT NOT NULL DEFAULT \'\'');
          } catch (_) {
            // column may already exist
          }
        }
      },
    );
  }

  // ── Table definitions ─────────────────────────────────────

  static Future<void> _createPersonsTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS persons (
        id              INTEGER PRIMARY KEY AUTOINCREMENT,
        server_id       TEXT,
        name            TEXT    NOT NULL,
        employee_id     TEXT    NOT NULL UNIQUE,
        department      TEXT    NOT NULL,
        face_image_paths TEXT   NOT NULL DEFAULT '{}',
        registered_at   TEXT    NOT NULL,
        is_synced       INTEGER NOT NULL DEFAULT 0
      )
    ''');
  }

  static Future<void> _createAttendanceTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS attendance_records (
        id              INTEGER PRIMARY KEY AUTOINCREMENT,
        server_id       TEXT,
        person_id       TEXT,
        person_name     TEXT    NOT NULL,
        department      TEXT    NOT NULL DEFAULT '',
        confidence      REAL    NOT NULL DEFAULT 0.0,
        checked_in_at   TEXT    NOT NULL,
        is_synced       INTEGER NOT NULL DEFAULT 0
      )
    ''');
  }

  static Future<void> _createFaceEmbeddingsTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS face_embeddings (
        id          INTEGER PRIMARY KEY AUTOINCREMENT,
        person_id   TEXT    NOT NULL,
        label       TEXT,
        embedding   BLOB    NOT NULL,
        created_at  TEXT    NOT NULL
      )
    ''');
    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_embeddings_person_id
      ON face_embeddings (person_id)
    ''');
  }
}
