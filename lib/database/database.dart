import 'dart:async';
import 'dart:io';

import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

const businessTABLE = 'KhataBusiness';
const transactionTABLE = 'KhataTransaction';
const customerTABLE = 'KhataCustomer';

class DatabaseProvider {
  static final DatabaseProvider dbProvider = DatabaseProvider();

  Database? _database; // Use nullable type

  Future<Database> get database async {
    if (_database != null) return _database!; // Use null check
    _database = await createDatabase();
    return _database!;
  }

  static Future _onConfigure(Database database) async {
    await database.execute('PRAGMA foreign_keys = ON');
  }

  Future<Database> createDatabase() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, 'khataConnect.db');
    var database = await openDatabase(
      path,
      version: 2, // Increment version for schema changes
      onCreate: initDB,
      onUpgrade: upgradeDatabase, // Handle schema upgrades
      onConfigure: _onConfigure,
    );
    return database;
  }

  static void initDB(Database database, int version) async {
    await database.execute(
        'CREATE TABLE $businessTABLE (id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT, phone TEXT, address TEXT, logo BLOB, email TEXT, website TEXT, role TEXT, companyName TEXT)');

    await database.execute(
        'CREATE TABLE $customerTABLE (id INTEGER PRIMARY KEY AUTOINCREMENT, businessId INTEGER, name TEXT, phone TEXT, address TEXT, image BLOB, FOREIGN KEY (businessId) REFERENCES $businessTABLE (id) ON DELETE CASCADE)');

    await database.execute(
        'CREATE TABLE $transactionTABLE (id INTEGER PRIMARY KEY AUTOINCREMENT, businessId INTEGER, uid INTEGER, ttype TEXT, amount DOUBLE, comment TEXT, date TEXT, attachment BLOB, customer TEXT, FOREIGN KEY (businessId) REFERENCES $businessTABLE (id) ON DELETE CASCADE, FOREIGN KEY (uid) REFERENCES $customerTABLE (id) ON DELETE CASCADE)');
  }

  static Future<void> upgradeDatabase(
      Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db
          .execute('ALTER TABLE $transactionTABLE ADD COLUMN customer TEXT');
    }
  }
}
