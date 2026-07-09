import 'package:sqflite/sqflite.dart';

/// Banco `sqflite` unico do app, compartilhado pela fila de mutacoes e pelo
/// cache de leitura (duas tabelas, um arquivo so). Aberto uma unica vez por
/// processo (`Future` memoizado) — chamadas concorrentes recebem a mesma
/// instancia em vez de tentar abrir o arquivo duas vezes.
class OfflineDatabase {
  OfflineDatabase._();

  static Future<Database>? _instance;

  static Future<Database> open() {
    return _instance ??= _open();
  }

  static Future<Database> _open() async {
    final path = await getDatabasesPath();

    return openDatabase(
      '$path/clube_do_salao_offline.db',
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE queued_mutations (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            method TEXT NOT NULL,
            path TEXT NOT NULL,
            body TEXT NOT NULL,
            description TEXT NOT NULL,
            created_at TEXT NOT NULL,
            status TEXT NOT NULL,
            last_error TEXT
          )
        ''');

        await db.execute('''
          CREATE TABLE response_cache (
            key TEXT PRIMARY KEY,
            body TEXT NOT NULL
          )
        ''');
      },
    );
  }
}
