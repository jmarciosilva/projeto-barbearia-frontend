import 'dart:convert';

import 'package:clube_do_salao/services/offline/offline_database.dart';
import 'package:clube_do_salao/services/offline/response_cache.dart';
import 'package:sqflite/sqflite.dart';

class SqfliteResponseCache implements ResponseCache {
  const SqfliteResponseCache();

  @override
  Future<void> write(String key, dynamic body) async {
    final db = await OfflineDatabase.open();

    await db.insert(
      'response_cache',
      {'key': key, 'body': jsonEncode(body)},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<dynamic> read(String key) async {
    final db = await OfflineDatabase.open();
    final rows = await db.query(
      'response_cache',
      where: 'key = ?',
      whereArgs: [key],
      limit: 1,
    );

    if (rows.isEmpty) return null;

    return jsonDecode(rows.first['body'] as String);
  }

  @override
  Future<void> clear() async {
    final db = await OfflineDatabase.open();

    await db.delete('response_cache');
  }
}
