import 'dart:async';
import 'dart:io';

import 'package:cloudinary/cloudinary.dart';
import 'package:example/utils/utility.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

const String apiKey =
    String.fromEnvironment('CLOUDINARY_API_KEY', defaultValue: '');
const String apiSecret =
    String.fromEnvironment('CLOUDINARY_API_SECRET', defaultValue: '');
const String cloudName =
    String.fromEnvironment('CLOUDINARY_CLOUD_NAME', defaultValue: '');
const String folder =
    String.fromEnvironment('CLOUDINARY_FOLDER', defaultValue: '');
const String uploadPreset =
    String.fromEnvironment('CLOUDINARY_UPLOAD_PRESET', defaultValue: '');

/// A signed client needs an API secret, which must never ship in a real
/// mobile or web build. This example only builds one when credentials are
/// passed with --dart-define, so the default run stays unsigned.
final cloudinary = apiKey.isNotEmpty && apiSecret.isNotEmpty
    ? Cloudinary.signed(
        cloudName: cloudName,
        apiKey: apiKey,
        apiSecret: apiSecret,
      )
    : Cloudinary.unsigned(cloudName: cloudName);

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Cloudinary Demo',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.system,
      darkTheme: ThemeData.dark(),
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Cloudinary Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

enum FileSource {
  path,
  bytes,
}

class DataTransmitNotifier {
  final String? path;
  late final CloudinaryProgressCallback? progressCallback;
  final notifier = ValueNotifier<double>(0);

  DataTransmitNotifier(
      {this.path, CloudinaryProgressCallback? progressCallback}) {
    this.progressCallback = progressCallback ??
        (count, total) {
          notifier.value = count.toDouble() / total.toDouble();
        };
  }
}

class _MyHomePageState extends State<MyHomePage> {
  static const int loadImage = 1;
  static const int doSignedUpload = 2;
  static const int doUnsignedUpload = 3;
  static const int doDelete = 4;
  static const int doSearch = 5;
  DataTransmitNotifier dataImages = DataTransmitNotifier();
  UploadResult? uploadResult;
  String? statusMessage;
  bool loading = false;
  String? errorMessage;
  FileSource fileSource = FileSource.path;

  void onUploadSourceChanged(FileSource? value) =>
      setState(() => fileSource = value!);

  Widget get uploadSourceView => Column(
        children: [
          const Text("File source"),
          RadioGroup<FileSource>(
            groupValue: fileSource,
            onChanged: onUploadSourceChanged,
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(
                  child: RadioListTile<FileSource>(
                    title: Text("Path"),
                    value: FileSource.path,
                  ),
                ),
                Expanded(
                  child: RadioListTile<FileSource>(
                    title: Text("Bytes"),
                    value: FileSource.bytes,
                  ),
                ),
              ],
            ),
          )
        ],
      );

  Widget imageFromPathView() {
    return SizedBox(
      width: MediaQuery.of(context).size.width,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.file(
            File(dataImages.path!),
            height: MediaQuery.of(context).size.width * 0.75,
            scale: 1.0,
            fit: BoxFit.cover,
          ),
          const SizedBox(height: 16.0),
          if (dataImages.notifier.value > 0)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: ValueListenableBuilder<double>(
                key: ValueKey(dataImages.path),
                valueListenable: dataImages.notifier,
                builder: (context, value, child) {
                  if (value == 0 && !loading) return const SizedBox();
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      LinearProgressIndicator(
                        value: value,
                        minHeight: 8.0,
                      ),
                      const SizedBox(height: 4.0),
                      Text('${(value * 100).toInt()} %'),
                    ],
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Scrollbar(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              const SizedBox(height: 16),
              const Text(
                'Photos from file',
              ),
              const SizedBox(height: 8.0),
              dataImages.path != null
                  ? imageFromPathView()
                  : ElevatedButton(
                      onPressed: () => onClick(loadImage),
                      style: ButtonStyle(
                        padding: WidgetStateProperty.all(
                          const EdgeInsets.all(8.0),
                        ),
                      ),
                      child: const Text(
                        'Choose Image',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14.0,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
              const Divider(height: 32.0),
              if (uploadResult?.secureUrl != null)
                const Text(
                  'Cloudinary URL',
                ),
              const SizedBox(
                height: 16.0,
              ),
              if (uploadResult?.secureUrl != null)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).bottomAppBarTheme.color,
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    padding: const EdgeInsets.all(16.0),
                    child: RichText(
                      text: TextSpan(
                        text: uploadResult?.secureUrl ?? '',
                      ),
                    ),
                  ),
                ),
              if (transformedPreviewUrl != null) ...[
                const SizedBox(height: 24.0),
                const Text('Transformed delivery URL'),
                const SizedBox(height: 8.0),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: SelectableText(transformedPreviewUrl!),
                ),
                const SizedBox(height: 8.0),
                // Built by the SDK without a network call, so it renders
                // straight from the URL.
                Image.network(
                  transformedPreviewUrl!,
                  height: 150,
                  errorBuilder: (_, __, ___) => const Text('preview failed'),
                ),
              ],
              if (uploadResult != null) ...[
                const SizedBox(height: 16.0),
                Wrap(
                  spacing: 12,
                  alignment: WrapAlignment.center,
                  children: [
                    OutlinedButton(
                      onPressed: loading ? null : () => onClick(doDelete),
                      child: const Text('Delete it'),
                    ),
                    if (cloudinary.config.canSign)
                      OutlinedButton(
                        onPressed: loading ? null : () => onClick(doSearch),
                        child: const Text('Search folder'),
                      ),
                  ],
                ),
              ],
              if (statusMessage != null) ...[
                const SizedBox(height: 12.0),
                Text(statusMessage!, textAlign: TextAlign.center),
              ],
              const SizedBox(height: 16.0),
              Visibility(
                visible: errorMessage?.isNotEmpty ?? false,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "$errorMessage",
                      textAlign: TextAlign.center,
                      style:
                          TextStyle(fontSize: 18, color: Colors.red.shade900),
                    ),
                    const SizedBox(
                      height: 128,
                    ),
                  ],
                ),
              ),
              uploadSourceView,
              const SizedBox(
                height: 16,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: loading ? null : () => onClick(doSignedUpload),
                    style: ButtonStyle(
                      padding: WidgetStateProperty.all(
                        const EdgeInsets.all(16.0),
                      ),
                    ),
                    child: const Text(
                      'Signed upload',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16.0),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: loading ? null : () => onClick(doUnsignedUpload),
                    style: ButtonStyle(
                      padding:
                          WidgetStateProperty.all(const EdgeInsets.all(16.0)),
                    ),
                    child: const Text(
                      'Unsigned upload',
                      textAlign: TextAlign.center,
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 40.0),
            ],
          ),
        ),
      ),
    );
  }

  void onNewImages(List<String> filePaths) {
    if (filePaths.isNotEmpty) {
      for (final path in filePaths) {
        if (path.isNotEmpty) {
          setState(() {
            dataImages = DataTransmitNotifier(path: path);
          });
        }
      }
      setState(() {});
    }
  }

  Future<CloudinaryFileSource> buildFileSource(String path) async {
    if (fileSource == FileSource.bytes) {
      return CloudinaryFileSource.bytes(
        await File(path).readAsBytes(),
        filename: path.split(Platform.pathSeparator).last,
      );
    }
    return CloudinaryFileSource.path(path);
  }

  Future<void> doSingleUpload({bool signed = true}) async {
    final data = dataImages;
    try {
      final source = await buildFileSource(data.path!);

      final result = signed
          ? await cloudinary.upload.upload(
              file: source,
              resourceType: CloudinaryResourceType.image,
              folder: folder,
              onProgress: data.progressCallback,
            )
          : await cloudinary.upload.unsignedUpload(
              file: source,
              resourceType: CloudinaryResourceType.image,
              folder: folder,
              uploadPreset: uploadPreset,
              onProgress: data.progressCallback,
            );

      setState(() {
        uploadResult = result;
        errorMessage = null;
        statusMessage = null;
      });
    } on CloudinaryException catch (e) {
      // v2 throws instead of returning a response carrying an error string.
      setState(() => errorMessage = e.message);
      if (kDebugMode) print(e);
    }
  }

  /// Deletes the asset that was just uploaded.
  ///
  /// Destroy answers `not found` with a 200, so the result is checked rather
  /// than relying on an exception.
  Future<void> deleteUpload() async {
    final publicId = uploadResult?.publicId;
    if (publicId == null) return;

    try {
      final result = await cloudinary.upload.destroy(publicId: publicId);
      setState(() {
        statusMessage =
            result.isDeleted ? 'Deleted $publicId' : 'Not found: $publicId';
        if (result.isDeleted) uploadResult = null;
      });
    } on CloudinaryException catch (e) {
      setState(() => errorMessage = e.message);
    }
  }

  /// Lists what is in the upload folder, using the Search API.
  Future<void> searchFolder() async {
    try {
      final results = await cloudinary.search
          .expression('folder:$folder')
          .sortBy('created_at', SortDirection.desc)
          .maxResults(10)
          .execute();

      setState(() {
        statusMessage =
            'Search found ${results.totalCount ?? results.resources.length} '
            'asset(s) in "$folder"';
      });
    } on CloudinaryException catch (e) {
      setState(() => errorMessage = e.message);
    }
  }

  /// Shows what the URL builder produces for the asset just uploaded.
  String? get transformedPreviewUrl {
    final publicId = uploadResult?.publicId;
    if (publicId == null) return null;
    return cloudinary.url
        .image(publicId)
        .transform(Transformation()
          ..width(400)
          ..height(300)
          ..crop(CropMode.fill)
          ..gravity(Gravity.auto)
          ..quality(Quality.auto)
          ..format(DeliveryFormat.auto))
        .build();
  }

  void onClick(int id) async {
    errorMessage = null;
    try {
      switch (id) {
        case loadImage:
          Utility.showImagePickerModal(
            context: context,
            onImageFromCamera: () async {
              onNewImages(await handleImagePickerResponse(
                  Utility.takePhoto(cameraDevice: CameraDevice.rear)));
            },
            onImageFromGallery: () async {
              onNewImages(await handleImagePickerResponse(
                  Utility.pickImageFromGallery()));
            },
          );
          break;
        case doSignedUpload:
          await doSingleUpload();
          break;
        case doUnsignedUpload:
          await doSingleUpload(signed: false);
          break;
        case doDelete:
          await deleteUpload();
          break;
        case doSearch:
          await searchFolder();
          break;
      }
    } catch (e) {
      if (kDebugMode) {
        print(e);
      }
      loading = false;
      setState(() => errorMessage = e.toString());
    } finally {
      if (loading) hideLoading();
    }
  }

  void showLoading() => setState(() => loading = true);

  void hideLoading() => setState(() => loading = false);

  Future<List<String>> handleImagePickerResponse(Future getImageCall) async {
    Map<String, dynamic> resource =
        await (getImageCall as FutureOr<Map<String, dynamic>>);
    if (resource.isEmpty) return [];
    switch (resource['status']) {
      case 'SUCCESS':
        // ignore: use_build_context_synchronously
        Navigator.pop(context);
        return resource['data'];
      default:
        Utility.showPermissionExplanation(
            context: context, message: resource['message']);
        break;
    }
    return [];
  }
}
