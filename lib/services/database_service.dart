import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:idvault/models/aadhaar_record.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'aadhaar_records.db');

    return await openDatabase(
      path,
      version: 2, // Bumped version to allow migration if needed
      onCreate: _createDatabase,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _createDatabase(Database db, int version) async {
    await db.execute('''
      CREATE TABLE aadhaar_records (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        aadhaarNumber TEXT NOT NULL,
        fullName TEXT NOT NULL,
        guardianName TEXT,
        dob TEXT,
        gender TEXT,
        fullAddress TEXT NOT NULL,
        createdAt TEXT NOT NULL,
        updatedAt TEXT NOT NULL
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE aadhaar_records ADD COLUMN dob TEXT');
    }
  }

  Future<int> insertRecord(AadhaarRecord record) async {
    final db = await database;
    final now = DateTime.now();
    final recordWithTimestamps = record.copyWith(
      createdAt: now,
      updatedAt: now,
    );

    return await db.insert(
      'aadhaar_records',
      recordWithTimestamps.toMap()..remove('id'),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<AadhaarRecord>> getAllRecords() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'aadhaar_records',
      orderBy: 'createdAt DESC',
    );

    return List.generate(maps.length, (i) {
      return AadhaarRecord.fromMap(maps[i]);
    });
  }

  Future<AadhaarRecord?> getRecord(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'aadhaar_records',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return AadhaarRecord.fromMap(maps.first);
    }
    return null;
  }

  Future<int> updateRecord(AadhaarRecord record) async {
    final db = await database;
    final updatedRecord = record.copyWith(updatedAt: DateTime.now());

    return await db.update(
      'aadhaar_records',
      updatedRecord.toMap(),
      where: 'id = ?',
      whereArgs: [record.id],
    );
  }

  Future<int> deleteRecord(int id) async {
    final db = await database;
    return await db.delete('aadhaar_records', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<AadhaarRecord>> searchRecords(String query) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'aadhaar_records',
      where: '''
        fullName LIKE ? 
        OR aadhaarNumber LIKE ? 
        OR guardianName LIKE ? 
        OR fullAddress LIKE ? 
        OR gender LIKE ?
      ''',
      whereArgs: ['%$query%', '%$query%', '%$query%', '%$query%', '%$query%'],
      orderBy: 'createdAt DESC',
    );

    return List.generate(maps.length, (i) {
      return AadhaarRecord.fromMap(maps[i]);
    });
  }

  Future<bool> recordExists(String aadhaarNumber) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'aadhaar_records',
      where: 'aadhaarNumber = ?',
      whereArgs: [aadhaarNumber],
      limit: 1,
    );
    return maps.isNotEmpty;
  }

  Future<int> getRecordCount() async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM aadhaar_records',
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<void> close() async {
    final db = _database;
    if (db != null) {
      await db.close();
      _database = null;
    }
  }
}
