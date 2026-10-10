import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/alert_model.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  static Database? _database;

  factory DatabaseService() {
    return _instance;
  }

  DatabaseService._internal();

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, 'posture_alerts.db');

    return openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE alerts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        timestamp DATETIME NOT NULL
      )
    ''');
  }

  Future<int> insertAlert(PostureAlert alert) async {
    final db = await database;
    return db.insert('alerts', alert.toMap());
  }

  Future<List<PostureAlert>> getAllAlerts() async {
    final db = await database;
    final maps = await db.query('alerts', orderBy: 'timestamp DESC');
    return List.generate(maps.length, (i) => PostureAlert.fromMap(maps[i]));
  }

  Future<List<PostureAlert>> getAlertsForDay(DateTime day) async {
    final db = await database;
    final startOfDay = DateTime(day.year, day.month, day.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final maps = await db.query(
      'alerts',
      where: 'timestamp >= ? AND timestamp < ?',
      whereArgs: [startOfDay.toIso8601String(), endOfDay.toIso8601String()],
      orderBy: 'timestamp DESC',
    );

    return List.generate(maps.length, (i) => PostureAlert.fromMap(maps[i]));
  }

  Future<List<PostureAlert>> getAlertsForWeek(DateTime referenceDate) async {
    final db = await database;
    final startOfWeek = referenceDate.subtract(Duration(days: referenceDate.weekday - 1));
    final startOfDay = DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);
    final endOfWeek = startOfDay.add(const Duration(days: 7));

    final maps = await db.query(
      'alerts',
      where: 'timestamp >= ? AND timestamp < ?',
      whereArgs: [startOfDay.toIso8601String(), endOfWeek.toIso8601String()],
      orderBy: 'timestamp ASC',
    );

    return List.generate(maps.length, (i) => PostureAlert.fromMap(maps[i]));
  }

  Future<int> deleteAlert(int id) async {
    final db = await database;
    return db.delete('alerts', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> clearAllAlerts() async {
    final db = await database;
    await db.delete('alerts');
  }
}
