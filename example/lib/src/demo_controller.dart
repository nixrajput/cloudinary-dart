import 'dart:io';

import 'package:cloudinary/cloudinary.dart';
import 'package:flutter/foundation.dart';

import 'demo_config.dart';

/// Null when unset, so an empty folder is omitted rather than sent blank.
String? get _folder => folder.trim().isEmpty ? null : folder.trim();

/// Whether the file is sent from a path or read into memory first.
enum UploadSource { path, bytes }

/// Holds the demo's state and every call into the SDK.
///
/// Keeping the SDK usage here rather than in widgets is the point of the
/// example: this file is the part worth reading.
class DemoController extends ChangeNotifier {
  DemoController() : _cloudinary = createClient();

  final Cloudinary _cloudinary;

  String? _imagePath;
  UploadSource _source = UploadSource.path;
  UploadResult? _result;
  double _progress = 0;
  bool _busy = false;
  String? _error;
  String? _status;

  String? get imagePath => _imagePath;

  UploadSource get source => _source;

  UploadResult? get result => _result;

  /// Fraction from 0 to 1, not a percentage.
  double get progress => _progress;

  bool get busy => _busy;

  String? get error => _error;

  String? get status => _status;

  bool get canSign => _cloudinary.config.canSign;

  bool get hasUploadPreset => uploadPreset.isNotEmpty;

  /// A transformed delivery URL for the uploaded asset.
  ///
  /// Built with no network call, so a widget can render it immediately.
  String? get transformedUrl {
    final publicId = _result?.publicId;
    if (publicId == null) return null;

    return _cloudinary.url
        .image(publicId)
        .transform(
          Transformation()
            ..width(400)
            ..height(300)
            ..crop(CropMode.fill)
            ..gravity(Gravity.auto)
            ..quality(Quality.auto)
            ..format(DeliveryFormat.auto),
        )
        .build();
  }

  void setSource(UploadSource value) {
    _source = value;
    notifyListeners();
  }

  void setImage(String path) {
    _imagePath = path;
    _result = null;
    _progress = 0;
    _clearMessages();
    notifyListeners();
  }

  void showError(String message) {
    _error = message;
    notifyListeners();
  }

  Future<void> upload({required bool signed}) async {
    final path = _imagePath;
    if (path == null) return;

    await _run(() async {
      final file = switch (_source) {
        UploadSource.path => CloudinaryFileSource.path(path),
        UploadSource.bytes => CloudinaryFileSource.bytes(
          await File(path).readAsBytes(),
          filename: path.split(Platform.pathSeparator).last,
        ),
      };

      void onProgress(int sent, int total) {
        _progress = total == 0 ? 0 : sent / total;
        notifyListeners();
      }

      _result = signed
          ? await _cloudinary.upload.upload(
              file: file,
              folder: _folder,
              onProgress: onProgress,
            )
          : await _cloudinary.upload.unsignedUpload(
              file: file,
              uploadPreset: uploadPreset,
              folder: _folder,
              onProgress: onProgress,
            );
    });
  }

  /// Cloudinary answers `not found` with a 200, so the outcome is read from
  /// the result rather than inferred from the absence of an exception.
  Future<void> destroy() async {
    final publicId = _result?.publicId;
    if (publicId == null) return;

    await _run(() async {
      final outcome = await _cloudinary.upload.destroy(publicId: publicId);
      if (outcome.isDeleted) {
        _result = null;
        _status = 'Deleted $publicId';
      } else {
        _status = 'Not found: $publicId';
      }
    });
  }

  Future<void> search() async {
    await _run(() async {
      // With no folder configured, search the whole environment rather than
      // sending the invalid expression `folder:`.
      final expression = _folder == null
          ? 'resource_type:image'
          : 'folder:${_folder!}';

      final results = await _cloudinary.search
          .expression(expression)
          .sortBy('created_at', SortDirection.desc)
          .maxResults(10)
          .execute();

      final count = results.totalCount ?? results.resources.length;
      _status = 'Found $count asset(s) in "$folder"';
    });
  }

  /// Runs [action], mapping any SDK failure onto [error].
  ///
  /// Only [CloudinaryException] is caught: anything else is a bug in the
  /// example and should surface rather than be swallowed.
  Future<void> _run(Future<void> Function() action) async {
    _busy = true;
    _clearMessages();
    notifyListeners();

    try {
      await action();
    } on CloudinaryException catch (e) {
      _error = e.message;
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  void _clearMessages() {
    _error = null;
    _status = null;
  }

  @override
  void dispose() {
    _cloudinary.close();
    super.dispose();
  }
}
