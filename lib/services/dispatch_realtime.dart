import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import '../api/generated/openapi_paths.dart';
import '../api/http_client.dart';

/// SSE framing is independent of HTTP chunks and accepts CRLF/multiline data.
Stream<String> decodeDispatchEvents(Stream<List<int>> bytes) async* {
  var event = 'message';
  var size = 0;
  var hasData = false;
  var first = true;
  await for (var line in _boundedText(bytes).transform(const LineSplitter())) {
    if (first) {
      line = line.replaceFirst(RegExp(r'^\uFEFF'), '');
      first = false;
    }
    if (line.isEmpty) {
      if (hasData &&
          const {'ready', 'change', 'resync', 'heartbeat'}.contains(event)) {
        yield event;
      }
      event = 'message';
      size = 0;
      hasData = false;
      continue;
    }
    size += line.length;
    if (size > 65536) throw const FormatException('SSE frame exceeds limit');
    if (line.startsWith(':')) continue;
    final colon = line.indexOf(':');
    final field = colon < 0 ? line : line.substring(0, colon);
    var value = colon < 0 ? '' : line.substring(colon + 1);
    if (value.startsWith(' ')) value = value.substring(1);
    if (field == 'event') event = value;
    if (field == 'data') hasData = true;
  }
}

Stream<String> _boundedText(Stream<List<int>> bytes) async* {
  var lineLength = 0;
  await for (final chunk
      in bytes.map<List<int>>((value) => value).transform(utf8.decoder)) {
    for (final code in chunk.codeUnits) {
      lineLength = code == 10 || code == 13 ? 0 : lineLength + 1;
      if (lineLength > 65536) {
        throw const FormatException('SSE line exceeds limit');
      }
    }
    yield chunk;
  }
}

abstract interface class DispatchEventSource {
  Stream<String> connect(CancelToken cancel);
}

class DioDispatchEventSource implements DispatchEventSource {
  DioDispatchEventSource(this.client);
  final HttpClient client;
  @override
  Stream<String> connect(CancelToken cancel) async* {
    try {
      final response = await client.dio.get<ResponseBody>(
        ApiPaths.dispatchEvents,
        cancelToken: cancel,
        options: Options(
          responseType: ResponseType.stream,
          receiveTimeout: const Duration(seconds: 45),
          headers: {'Accept': 'text/event-stream'},
        ),
      );
      if (response.data == null ||
          response.headers.value('content-type')?.split(';').first.trim() !=
              'text/event-stream') {
        throw const FormatException('Event stream unavailable');
      }
      await for (final event in decodeDispatchEvents(
        response.data!.stream.timeout(const Duration(seconds: 45)),
      )) {
        yield event;
      }
    } on DioException catch (error) {
      // Account switches, backgrounding and disposal deliberately cancel SSE.
      // Complete normally; genuine transport/server errors still trigger retry.
      if (!CancelToken.isCancel(error)) rethrow;
    }
  }
}
