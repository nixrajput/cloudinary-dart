import 'dart:async';

import 'package:http/http.dart' as http;

import 'progress.dart';

/// A multipart request that reports how many bytes have been written.
///
/// `package:http` exposes no send-progress hook, so the encoded body stream
/// from [finalize] is wrapped in a counting transformer.
class ProgressMultipartRequest extends http.MultipartRequest {
  /// Creates a multipart request reporting progress to [onProgress].
  ProgressMultipartRequest(super.method, super.url, {this.onProgress});

  /// Called as the body is written. Null disables progress reporting.
  final CloudinaryProgressCallback? onProgress;

  @override
  http.ByteStream finalize() {
    final byteStream = super.finalize();
    final callback = onProgress;
    if (callback == null) return byteStream;

    final total = contentLength;
    var sent = 0;

    final counted = byteStream.transform(
      StreamTransformer<List<int>, List<int>>.fromHandlers(
        handleData: (chunk, sink) {
          sent += chunk.length;
          callback(sent, total);
          sink.add(chunk);
        },
      ),
    );

    return http.ByteStream(counted);
  }
}
