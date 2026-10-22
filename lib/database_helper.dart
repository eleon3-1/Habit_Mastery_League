import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  static Future<Database>? _database;

  static Future<Database> get database {
    return _database ??= _openDatabase();
  }

  static Future<Database> _openDatabase() async {
    final folder = await getDatabasesPath();

    return openDatabase(
      join(folder, 'habit_mastery.db'),
      version: 2,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE habits (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT NOT NULL CHECK(length(trim(title)) > 0),
            category TEXT NOT NULL CHECK(length(trim(category)) > 0),
            reason TEXT NOT NULL DEFAULT '',
            weekly_target INTEGER NOT NULL
              CHECK(weekly_target BETWEEN 1 AND 7),
            created_at TEXT NOT NULL
          )
        ''');

        await db.execute('''
          CREATE TABLE check_ins (
            habit_id INTEGER NOT NULL
              REFERENCES habits(id) ON DELETE CASCADE,
            local_date TEXT NOT NULL,
            PRIMARY KEY (habit_id, local_date)
          )
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
            await db.execute(
                "ALTER TABLE habits ADD COLUMN reason TEXT NOT NULL DEFAULT ''",
                );
            }
        },







    );
  }

  // Save a new habit.
  static Future<int> saveHabit(Map<String, dynamic> habit) async {
  final db = await database;

  final values = <String, Object?>{
    'title': (habit['title'] as String).trim(),
    'category': (habit['category'] as String).trim(),
    'weekly_target': habit['target'] as int,
    'reason': (habit['reason'] as String? ?? '').trim(),
  };

  final id = habit['id'] as int?;

  if (id == null) {
    values['created_at'] = DateTime.now().toUtc().toIso8601String();
    return db.insert('habits', values);
  }

  final updated = await db.update(
    'habits',
    values,
    where: 'id = ?',
    whereArgs: [id],
  );

  if (updated == 0) {
    throw StateError('Habit no longer exists');
  }

  return id;
}

static Future<void> deleteHabit(int id) async {
  final db = await database;

  await db.delete(
    'habits',
    where: 'id = ?',
    whereArgs: [id],
  );
}
  

  // Load habits with their progress for this Monday through today.
  static Future<List<Map<String, Object?>>> getHabits() async {
    final db = await database;
    final now = DateTime.now();

    final today = _dateKey(now);
    final monday = _dateKey(
      DateTime(now.year, now.month, now.day - now.weekday + 1),
    );

    return db.rawQuery('''
      SELECT h.*,
      h.weekly_target AS target,
             COUNT(c.local_date) AS completed_this_week,
             MAX(
               CASE WHEN c.local_date = ? THEN 1 ELSE 0 END
             ) AS checked_in_today
      FROM habits h
      LEFT JOIN check_ins c
        ON c.habit_id = h.id
        AND c.local_date BETWEEN ? AND ?
      GROUP BY h.id
      ORDER BY h.id DESC
    ''', [today, monday, today]);
  }

  // Allow one check-in per habit per local calendar day.
  static Future<void> checkIn(int habitId) async {
    final db = await database;

    await db.insert(
      'check_ins',
      {
        'habit_id': habitId,
        'local_date': _dateKey(DateTime.now()),
      },
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  static String _dateKey(DateTime date) {
    return date.toLocal().toIso8601String().split('T').first;
  }
}