import 'package:sqflite/sqflite.dart';

enum TableUserConstant {
  table_name('table_name'),
  id('id'),
  value('value');

  const TableUserConstant(this.rawValue);

  final String rawValue;
}

class EntityTest {
  int? id;
  String? value;

  EntityTest({this.id, this.value});

  Map<String, Object?> toMap() {
    var map = <String, Object?>{
      TableUserConstant.id.rawValue: id,
      TableUserConstant.value.rawValue: value,
    };
    return map;
  }

  EntityTest.fromMap(Map<String, Object?> map) {
    id = map[TableUserConstant.id.rawValue] as int?;
    value = map[TableUserConstant.value.rawValue] as String?;
  }

  @override
  String toString() => 'id: $id, value: $value';
}

class SqlUserProvider {
  static Future<void> create(Database db) async {
    await db.execute('''
      create table "${TableUserConstant.table_name.rawValue}" (
        ${TableUserConstant.id.rawValue} INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL UNIQUE,
        ${TableUserConstant.value.rawValue} TEXT NOT NULL
          );
            ''');
  }

  static Future<void> insertUser({
    required Database db,
    required EntityTest user,
  }) async {
    await db.insert(TableUserConstant.table_name.rawValue, user.toMap());
  }

  static Future<List<EntityTest>> getAllData(Database db) async {
    final rawData = await db.query(TableUserConstant.table_name.rawValue);
    return rawData.map((e) => EntityTest.fromMap(e)).toList();
  }
}
