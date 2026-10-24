import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  ///////////(KEEPS ONE SHARED DATABASE CONNECTION FOR THE WHOLE APP)/////////////
  static Future<Database>? _database;

  static Future<Database> get database {
    return _database ??= _openDatabase();
  }

  ///////////(OPENS THE DATABASE FILE AND BUILDS OR UPGRADES THE TABLES)/////////////
  static Future<Database> _openDatabase() async {
    final folder = await getDatabasesPath();

    return openDatabase(
      join(folder, 'habit_mastery.db'),
      version: 2,

      ///////////(TURNS ON FOREIGN KEYS SO DELETING A HABIT DELETES ITS CHECK-INS)/////////////
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },

      ///////////(BRAND NEW INSTALL: CREATES BOTH TABLES)/////////////
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

        ///////////(PRIMARY KEY (habit_id, local_date) MEANS ONE CHECK-IN PER HABIT PER DAY)/////////////
        await db.execute('''
          CREATE TABLE check_ins (
            habit_id INTEGER NOT NULL
              REFERENCES habits(id) ON DELETE CASCADE,
            local_date TEXT NOT NULL,
            PRIMARY KEY (habit_id, local_date)
          )
        ''');
      },

      ///////////(OLDER INSTALL: ADDS THE REASON COLUMN IF IT'S MISSING)/////////////
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute(
            "ALTER TABLE habits ADD COLUMN reason TEXT NOT NULL DEFAULT ''",
          );
        }
      },
    );
  }

  ///////////(SAVES A NEW HABIT OR UPDATES AN EXISTING ONE)/////////////
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

  ///////////(DELETES A HABIT AND ITS CHECK-INS)/////////////
  static Future<void> deleteHabit(int id) async {
    final db = await database;

    await db.delete('habits', where: 'id = ?', whereArgs: [id]);
  }

  ///////////(LOADS HABITS WITH THEIR PROGRESS FROM MONDAY THROUGH TODAY)/////////////
  static Future<List<Map<String, Object?>>> getHabits() async {
    final db = await database;
    final now = DateTime.now();

    final today = _dateKey(now);
    final monday = _dateKey(
      DateTime(now.year, now.month, now.day - now.weekday + 1),
    );

    return db.rawQuery(
      '''
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
    ''',
      [today, monday, today],
    );
  }

  ///////////(SAVES TODAY'S CHECK-IN, A SECOND TAP THE SAME DAY DOES NOTHING)/////////////
  static Future<void> checkIn(int habitId) async {
    final db = await database;

    await db.insert('check_ins', {
      'habit_id': habitId,
      'local_date': _dateKey(DateTime.now()),
    }, conflictAlgorithm: ConflictAlgorithm.ignore);
  }

  ///////////(READ: EVERY CHECK-IN FROM MONDAY THROUGH TODAY, NEWEST FIRST)/////////////
  ///////////(ROWID IS SQLITE'S HIDDEN ROW NUMBER, USED AS THE CHECK-IN'S ID)/////////////
  static Future<List<Map<String, Object?>>> getWeekCheckIns() async {
    final db = await database;
    final now = DateTime.now();

    final today = _dateKey(now);
    final monday = _dateKey(
      DateTime(now.year, now.month, now.day - now.weekday + 1),
    );

    return db.rawQuery(
      '''
      SELECT rowid AS id, habit_id, local_date
      FROM check_ins
      WHERE local_date BETWEEN ? AND ?
      ORDER BY local_date DESC
    ''',
      [monday, today],
    );
  }

  ///////////(CREATE: ADDS A CHECK-IN FOR A PICKED DAY, ERRORS IF THAT DAY IS TAKEN)/////////////
  static Future<void> addCheckIn(int habitId, String date) async {
    final db = await database;

    await db.insert('check_ins', {'habit_id': habitId, 'local_date': date});
  }

  ///////////(UPDATE: MOVES A CHECK-IN TO A DIFFERENT DAY)/////////////
  static Future<void> updateCheckIn(int id, String date) async {
    final db = await database;

    await db.update(
      'check_ins',
      {'local_date': date},
      where: 'rowid = ?',
      whereArgs: [id],
    );
  }

  ///////////(DELETE: REMOVES ONE CHECK-IN)/////////////
  static Future<void> deleteCheckIn(int id) async {
    final db = await database;

    await db.delete('check_ins', where: 'rowid = ?', whereArgs: [id]);
  }

  ///////////(TURNS A DATE INTO TEXT LIKE 2026-10-24)/////////////
  static String _dateKey(DateTime date) {
    return date.toLocal().toIso8601String().split('T').first;
  }
}
