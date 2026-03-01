enum MediaType {
  deliveryPhoto('delivery_photo'),
  exceptionPhoto('exception_photo'),
  signature('signature');

  const MediaType(this.value);
  final String value;

  static MediaType fromValue(String value) {
    return MediaType.values.firstWhere(
      (item) => item.value == value,
      orElse: () => MediaType.deliveryPhoto,
    );
  }
}

enum MediaQueueStatus {
  pending('pending'),
  uploaded('uploaded'),
  failed('failed'),
  deadLetter('dead_letter');

  const MediaQueueStatus(this.value);
  final String value;

  static MediaQueueStatus fromValue(String value) {
    return MediaQueueStatus.values.firstWhere(
      (item) => item.value == value,
      orElse: () => MediaQueueStatus.pending,
    );
  }
}

class MediaQueueDraft {
  const MediaQueueDraft({
    required this.trackingNo,
    required this.filePath,
    required this.fileName,
    required this.mediaType,
    this.metadata = const <String, String>{},
  });

  final String trackingNo;
  final String filePath;
  final String fileName;
  final MediaType mediaType;
  final Map<String, String> metadata;
}

class MediaQueueItem {
  const MediaQueueItem({
    required this.id,
    required this.trackingNo,
    required this.filePath,
    required this.fileName,
    required this.mediaType,
    required this.status,
    required this.retryCount,
    required this.createdAt,
    required this.updatedAt,
    this.lastErrorCode,
    this.metadata = const <String, String>{},
  });

  final int id;
  final String trackingNo;
  final String filePath;
  final String fileName;
  final MediaType mediaType;
  final MediaQueueStatus status;
  final int retryCount;
  final String? lastErrorCode;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Map<String, String> metadata;

  MediaQueueItem copyWith({
    int? id,
    String? trackingNo,
    String? filePath,
    String? fileName,
    MediaType? mediaType,
    MediaQueueStatus? status,
    int? retryCount,
    String? lastErrorCode,
    DateTime? createdAt,
    DateTime? updatedAt,
    Map<String, String>? metadata,
  }) {
    return MediaQueueItem(
      id: id ?? this.id,
      trackingNo: trackingNo ?? this.trackingNo,
      filePath: filePath ?? this.filePath,
      fileName: fileName ?? this.fileName,
      mediaType: mediaType ?? this.mediaType,
      status: status ?? this.status,
      retryCount: retryCount ?? this.retryCount,
      lastErrorCode: lastErrorCode ?? this.lastErrorCode,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      metadata: metadata ?? this.metadata,
    );
  }
}
