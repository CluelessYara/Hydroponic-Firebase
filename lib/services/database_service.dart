import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../models/plant_profile.dart';

class DatabaseService {
  static final DatabaseService instance = DatabaseService._internal();
  static Database? _database;

  DatabaseService._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  Future<Database> _initDB() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'hydroponic.db');

    return await openDatabase(
      path,
      version: 2,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE plant_profiles(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            phMin REAL NOT NULL,
            phMax REAL NOT NULL,
            tempMin REAL NOT NULL,
            tempMax REAL NOT NULL,
            tdsMin REAL NOT NULL,
            tdsMax REAL NOT NULL,
            wateringCycleHours INTEGER NOT NULL,
            isActive INTEGER NOT NULL DEFAULT 0
          )
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        await db.execute('DROP TABLE IF EXISTS plant_profiles');
        await db.execute('''
          CREATE TABLE plant_profiles(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            phMin REAL NOT NULL,
            phMax REAL NOT NULL,
            tempMin REAL NOT NULL,
            tempMax REAL NOT NULL,
            tdsMin REAL NOT NULL,
            tdsMax REAL NOT NULL,
            wateringCycleHours INTEGER NOT NULL,
            isActive INTEGER NOT NULL DEFAULT 0
          )
        ''');
      },
    );
  }

  Future<int> insertPlant(PlantProfile plant) async {
    final db = await database;
    return db.insert('plant_profiles', plant.toMap());
  }

  Future<List<PlantProfile>> getPlants() async {
    final db = await database;
    final maps = await db.query('plant_profiles');
    return maps.map((map) => PlantProfile.fromMap(map)).toList();
  }

  Future<void> setActivePlant(int id) async {
    final db = await database;
    await db.update('plant_profiles', {'isActive': 0});
    await db.update(
      'plant_profiles',
      {'isActive': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> updatePlant(PlantProfile plant) async {
    final db = await database;
    await db.update(
      'plant_profiles',
      plant.toMap(),
      where: 'id = ?',
      whereArgs: [plant.id],
    );
  }

  Future<void> deletePlant(int id) async {
    final db = await database;
    await db.delete(
      'plant_profiles',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}