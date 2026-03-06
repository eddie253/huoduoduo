import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import '../domain/scan_audit_entry.dart';
import 'scan_audit_schema.dart';

class ScanAuditRepository {
  ScanAuditRepository._(this._db);

  final Database _db;

  static Future<ScanAuditRepository> open({required String path}) async {
    final db = await openDatabase(
      path,
      version: ScanAuditSchema.databaseVersion,
      onCreate: (Database db, int version) async {
        await db.execute(ScanAuditSchema.createTableSql);
        await db.execute(ScanAuditSchema.createIndexSql);
      },
    );
    return ScanAuditRepository._(db);
  }

  Future<void> insert(ScanAuditEntry entry) async {
    await _db.insert(
      ScanAuditSchema.tableName,
      entry.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<ScanAuditEntry>> queryRecent({int limit = 100}) async {
    final rows = await _db.query(
      ScanAuditSchema.tableName,
      orderBy: 'scanned_at DESC',
      limit: limit,
    );
    return rows.map(ScanAuditEntry.fromMap).toList();
  }

  Future<void> clearAll() async {
    await _db.delete(ScanAuditSchema.tableName);
  }

  Future<void> close() => _db.close();
}

final scanAuditRepositoryProvider =
    FutureProvider<ScanAuditRepository>((ref) async {
  final dbDir = await getDatabasesPath();
  final path = p.join(dbDir, 'scan_audit.db');
  return ScanAuditRepository.open(path: path);
});
