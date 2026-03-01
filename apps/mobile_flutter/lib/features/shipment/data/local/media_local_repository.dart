import 'dart:convert';

import 'package:path/path.dart' as p;
import 'package:sqflite/sqlite_api.dart';

import '../../domain/media_queue_models.dart';
import 'media_local_schema.dart';

abstract class MediaLocalRepository {
  Future<void> init();
  Future<MediaQueueItem> enqueue(MediaQueueDraft draft);
  Future<MediaQueueItem?> getById(int id);
  Future<List<MediaQueueItem>> listByStatus(
    MediaQueueStatus status, {
    int limit = 50,
  });
  Future<void> markUploaded(int id);
  Future<void> markFailed(int id, {String? errorCode});
  Future<void> markDeadLetter(int id, {String? errorCode});
  Future<int> cleanupUploadedOlderThan(DateTime threshold);
  Future<void> close();
}

class MediaLocalDatabase {
  MediaLocalDatabase({
    required this.databaseFactory,
    required this.databasePath,
  });

  final DatabaseFactory databaseFactory;
  final String databasePath;

  Database? _database;

  Future<Database> open() async {
    final existing = _database;
    if (existing != null && existing.isOpen) {
      return existing;
    }

    final db = await databaseFactory.openDatabase(
      databasePath,
      options: OpenDatabaseOptions(
        version: MediaLocalSchema.databaseVersion,
        onCreate: (Database db, int version) async {
          await db.execute(MediaLocalSchema.createTableSql);
          await db.execute(MediaLocalSchema.createStatusIndexSql);
        },
      ),
    );
    _database = db;
    return db;
  }

  Future<void> close() async {
    final db = _database;
    if (db != null && db.isOpen) {
      await db.close();
    }
    _database = null;
  }
}

class SqfliteMediaLocalRepository implements MediaLocalRepository {
  SqfliteMediaLocalRepository(this._database);

  final MediaLocalDatabase _database;

  @override
  Future<void> init() async {
    await _database.open();
  }

  @override
  Future<MediaQueueItem> enqueue(MediaQueueDraft draft) async {
    _validateDraft(draft);
    LocalMetadataPolicy.assertAllowed(draft.metadata);

    final db = await _database.open();
    final now = DateTime.now().toUtc();
    final payload = <String, Object?>{
      'tracking_no': draft.trackingNo.trim(),
      'file_path': p.normalize(draft.filePath.trim()),
      'file_name': draft.fileName.trim(),
      'media_type': draft.mediaType.value,
      'status': MediaQueueStatus.pending.value,
      'retry_count': 0,
      'last_error_code': null,
      'metadata_json': jsonEncode(draft.metadata),
      'created_at': now.toIso8601String(),
      'updated_at': now.toIso8601String(),
    };

    final id = await db.insert(MediaLocalSchema.tableName, payload);
    return MediaQueueItem(
      id: id,
      trackingNo: draft.trackingNo.trim(),
      filePath: p.normalize(draft.filePath.trim()),
      fileName: draft.fileName.trim(),
      mediaType: draft.mediaType,
      status: MediaQueueStatus.pending,
      retryCount: 0,
      lastErrorCode: null,
      createdAt: now,
      updatedAt: now,
      metadata: draft.metadata,
    );
  }

  @override
  Future<List<MediaQueueItem>> listByStatus(
    MediaQueueStatus status, {
    int limit = 50,
  }) async {
    final db = await _database.open();
    final rows = await db.query(
      MediaLocalSchema.tableName,
      where: 'status = ?',
      whereArgs: <Object?>[status.value],
      orderBy: 'created_at ASC',
      limit: limit,
    );

    return rows.map(_mapRow).toList(growable: false);
  }

  @override
  Future<MediaQueueItem?> getById(int id) async {
    final db = await _database.open();
    final rows = await db.query(
      MediaLocalSchema.tableName,
      where: 'id = ?',
      whereArgs: <Object?>[id],
      limit: 1,
    );
    if (rows.isEmpty) {
      return null;
    }
    return _mapRow(rows.first);
  }

  @override
  Future<void> markUploaded(int id) async {
    final db = await _database.open();
    final now = DateTime.now().toUtc().toIso8601String();
    await db.update(
      MediaLocalSchema.tableName,
      <String, Object?>{
        'status': MediaQueueStatus.uploaded.value,
        'updated_at': now,
        'last_error_code': null,
      },
      where: 'id = ?',
      whereArgs: <Object?>[id],
    );
  }

  @override
  Future<void> markFailed(int id, {String? errorCode}) async {
    final db = await _database.open();
    final now = DateTime.now().toUtc().toIso8601String();
    await db.rawUpdate(
      '''
UPDATE ${MediaLocalSchema.tableName}
SET status = ?, retry_count = retry_count + 1, last_error_code = ?, updated_at = ?
WHERE id = ?
''',
      <Object?>[
        MediaQueueStatus.failed.value,
        errorCode,
        now,
        id,
      ],
    );
  }

  @override
  Future<void> markDeadLetter(int id, {String? errorCode}) async {
    final db = await _database.open();
    final now = DateTime.now().toUtc().toIso8601String();
    await db.update(
      MediaLocalSchema.tableName,
      <String, Object?>{
        'status': MediaQueueStatus.deadLetter.value,
        'updated_at': now,
        'last_error_code': errorCode,
      },
      where: 'id = ?',
      whereArgs: <Object?>[id],
    );
  }

  @override
  Future<int> cleanupUploadedOlderThan(DateTime threshold) async {
    final db = await _database.open();
    return db.delete(
      MediaLocalSchema.tableName,
      where: 'status = ? AND updated_at < ?',
      whereArgs: <Object?>[
        MediaQueueStatus.uploaded.value,
        threshold.toUtc().toIso8601String(),
      ],
    );
  }

  @override
  Future<void> close() async {
    await _database.close();
  }

  static void _validateDraft(MediaQueueDraft draft) {
    if (draft.trackingNo.trim().isEmpty) {
      throw ArgumentError('trackingNo is required');
    }
    if (draft.filePath.trim().isEmpty) {
      throw ArgumentError('filePath is required');
    }
    if (draft.fileName.trim().isEmpty) {
      throw ArgumentError('fileName is required');
    }
    if (draft.filePath.contains('..')) {
      throw ArgumentError('filePath cannot contain path traversal');
    }
  }

  static MediaQueueItem _mapRow(Map<String, Object?> row) {
    final metadataJson = row['metadata_json'] as String? ?? '{}';
    final decoded = jsonDecode(metadataJson);
    final metadata = <String, String>{};
    if (decoded is Map<String, dynamic>) {
      for (final entry in decoded.entries) {
        metadata[entry.key] = entry.value?.toString() ?? '';
      }
    }

    return MediaQueueItem(
      id: row['id'] as int? ?? 0,
      trackingNo: row['tracking_no'] as String? ?? '',
      filePath: row['file_path'] as String? ?? '',
      fileName: row['file_name'] as String? ?? '',
      mediaType: MediaType.fromValue(row['media_type'] as String? ?? ''),
      status: MediaQueueStatus.fromValue(row['status'] as String? ?? ''),
      retryCount: row['retry_count'] as int? ?? 0,
      lastErrorCode: row['last_error_code'] as String?,
      createdAt: DateTime.parse(
        row['created_at'] as String? ??
            DateTime.fromMillisecondsSinceEpoch(0).toIso8601String(),
      ),
      updatedAt: DateTime.parse(
        row['updated_at'] as String? ??
            DateTime.fromMillisecondsSinceEpoch(0).toIso8601String(),
      ),
      metadata: metadata,
    );
  }
}
