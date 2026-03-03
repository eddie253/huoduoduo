import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';

typedef AdapterResponder = ResponseBody Function(RequestOptions options);

class RecordingDioAdapter implements HttpClientAdapter {
  RecordingDioAdapter({AdapterResponder? responder}) : _responder = responder;

  final AdapterResponder? _responder;
  final List<RequestOptions> requests = <RequestOptions>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    final responder = _responder;
    if (responder != null) {
      return responder(options);
    }
    return ResponseBody.fromString(
      '{}',
      200,
      headers: <String, List<String>>{
        Headers.contentTypeHeader: <String>[Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

ResponseBody jsonBody(
  Map<String, dynamic> data, {
  int statusCode = 200,
}) {
  return ResponseBody.fromString(
    jsonEncode(data),
    statusCode,
    headers: <String, List<String>>{
      Headers.contentTypeHeader: <String>[Headers.jsonContentType],
    },
  );
}
