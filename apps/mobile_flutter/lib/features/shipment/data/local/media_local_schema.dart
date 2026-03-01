class MediaLocalSchema {
  static const String tableName = 'media_upload_queue';
  static const int databaseVersion = 1;

  static const String createTableSql = '''
CREATE TABLE $tableName (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  tracking_no TEXT NOT NULL,
  file_path TEXT NOT NULL,
  file_name TEXT NOT NULL,
  media_type TEXT NOT NULL,
  status TEXT NOT NULL DEFAULT 'pending',
  retry_count INTEGER NOT NULL DEFAULT 0,
  last_error_code TEXT,
  metadata_json TEXT NOT NULL DEFAULT '{}',
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL
)
''';

  static const String createStatusIndexSql = '''
CREATE INDEX idx_media_upload_queue_status_created
ON $tableName(status, created_at)
''';
}

class LocalMetadataPolicy {
  static const List<String> forbiddenKeyFragments = <String>[
    'password',
    'passwd',
    'access_token',
    'refresh_token',
    'token',
    'secret',
    'authorization',
    'cookie',
    'apikey',
    'api_key',
  ];

  static void assertAllowed(Map<String, String> metadata) {
    for (final entry in metadata.entries) {
      final key = entry.key.toLowerCase();
      final value = entry.value.toLowerCase();
      for (final forbidden in forbiddenKeyFragments) {
        if (key.contains(forbidden) || value.contains(forbidden)) {
          throw ArgumentError(
            'FORBIDDEN_LOCAL_FIELD:${entry.key}',
          );
        }
      }
    }
  }
}
