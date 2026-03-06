import 'media_queue_models.dart';

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
