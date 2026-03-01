import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import 'media_local_repository.dart';

const String _mediaLocalDbFile = 'media_local.db';

final mediaLocalRepositoryProvider = FutureProvider<MediaLocalRepository>((
  Ref ref,
) async {
  final dbRoot = await getDatabasesPath();
  final dbPath = p.join(dbRoot, _mediaLocalDbFile);

  final localDatabase = MediaLocalDatabase(
    databaseFactory: databaseFactory,
    databasePath: dbPath,
  );
  final repository = SqfliteMediaLocalRepository(localDatabase);
  await repository.init();

  ref.onDispose(() async {
    await repository.close();
  });
  return repository;
});
