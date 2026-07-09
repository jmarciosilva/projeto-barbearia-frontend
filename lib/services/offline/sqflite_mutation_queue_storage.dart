import 'dart:convert';

import 'package:clube_do_salao/services/offline/mutation_queue_storage.dart';
import 'package:clube_do_salao/services/offline/offline_database.dart';
import 'package:clube_do_salao/services/offline/queued_mutation.dart';

class SqfliteMutationQueueStorage implements MutationQueueStorage {
  const SqfliteMutationQueueStorage();

  @override
  Future<int> add({
    required String method,
    required String path,
    required Map<String, dynamic> body,
    required String description,
  }) async {
    final db = await OfflineDatabase.open();

    return db.insert('queued_mutations', {
      'method': method,
      'path': path,
      'body': jsonEncode(body),
      'description': description,
      'created_at': DateTime.now().toIso8601String(),
      'status': QueuedMutationStatus.pending.name,
      'last_error': null,
    });
  }

  @override
  Future<List<QueuedMutation>> all() async {
    final db = await OfflineDatabase.open();
    final rows = await db.query('queued_mutations', orderBy: 'id ASC');

    return rows.map(_fromRow).toList();
  }

  @override
  Future<void> markFailed(int id, String errorMessage) async {
    final db = await OfflineDatabase.open();

    await db.update(
      'queued_mutations',
      {'status': QueuedMutationStatus.failed.name, 'last_error': errorMessage},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  @override
  Future<void> remove(int id) async {
    final db = await OfflineDatabase.open();

    await db.delete('queued_mutations', where: 'id = ?', whereArgs: [id]);
  }

  QueuedMutation _fromRow(Map<String, dynamic> row) {
    return QueuedMutation(
      id: row['id'] as int,
      method: row['method'] as String,
      path: row['path'] as String,
      body: jsonDecode(row['body'] as String) as Map<String, dynamic>,
      description: row['description'] as String,
      createdAt: DateTime.parse(row['created_at'] as String),
      status: QueuedMutationStatus.values.byName(row['status'] as String),
      lastError: row['last_error'] as String?,
    );
  }
}
