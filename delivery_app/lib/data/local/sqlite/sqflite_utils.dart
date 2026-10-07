import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';

import 'entity/user_entity.dart';

class SqfliteUtils {
  SqfliteUtils._internal();

  static final SqfliteUtils instance = SqfliteUtils._internal();

  factory SqfliteUtils() {
    return instance;
  }

  late Database _database;

  Future<void> init() async {
    debugPrint('database: ${await getDatabasesPath()}');
    _database = await openDatabase(
      'ss.db',
      version: 1,
      onCreate: (Database db, int version) async {
        await Future.wait([SqlUserProvider.create(db)]);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        // //migration version
      },
    );
  }

  Future<void> insertUser(EntityTest user) async {
    return SqlUserProvider.insertUser(db: _database, user: user);
  }

  Future<List<EntityTest>> getAllUser() async {
    return SqlUserProvider.getAllData(_database);
  }
}
