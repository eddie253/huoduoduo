class ScanAuditSchema {
  static const String tableName = 'scan_audit';
  static const int databaseVersion = 1;

  static const String createTableSql = '''
CREATE TABLE $tableName (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  scanned_at TEXT NOT NULL,
  raw_value TEXT NOT NULL,
  length INTEGER NOT NULL,
  symbology TEXT NOT NULL,
  source TEXT NOT NULL,
  duration_ms INTEGER,
  session_id TEXT NOT NULL DEFAULT ''
)
''';

  static const String createIndexSql = '''
CREATE INDEX idx_scan_audit_scanned_at
ON $tableName(scanned_at DESC)
''';
}
