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

final cloudinary = Cloudinary.unsignedConfig(
  cloudName: cloudName,
);

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

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
  const MyHomePage({Key? key, required this.title}) : super(key: key);

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
  late final ProgressCallback? progressCallback;
  final notifier = ValueNotifier<double>(0);

  DataTransmitNotifier({this.path, ProgressCallback? progressCallback}) {
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
  DataTransmitNotifier dataImages = DataTransmitNotifier();
  CloudinaryResponse cloudinaryResponses = CloudinaryResponse();
  bool loading = false;
  String? errorMessage;
  FileSource fileSource = FileSource.path;

  void onUploadSourceChanged(FileSource? value) =>
      setState(() => fileSource = value!);

  Widget get uploadSourceView => Column(
        children: [
          const Text("File source"),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Expanded(
                child: RadioListTile<FileSource>(
                    title: const Text("Path"),
                    value: FileSource.path,
                    groupValue: fileSource,
                    onChanged: onUploadSourceChanged),
              ),
              Expanded(
                child: RadioListTile<FileSource>(
                    title: const Text("Bytes"),
                    value: FileSource.bytes,
                    groupValue: fileSource,
                    onChanged: onUploadSourceChanged),
              ),
            ],
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
                        padding: MaterialStateProperty.all(
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
              if (cloudinaryResponses.secureUrl != null)
                const Text(
                  'Cloudinary URL',
                ),
              const SizedBox(
                height: 16.0,
              ),
              if (cloudinaryResponses.secureUrl != null)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).bottomAppBarColor,
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    padding: const EdgeInsets.all(16.0),
                    child: RichText(
                      text: TextSpan(
                        text: cloudinaryResponses.secureUrl ?? '',
                      ),
                    ),
                  ),
                ),
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
                      padding: MaterialStateProperty.all(
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
                          MaterialStateProperty.all(const EdgeInsets.all(16.0)),
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

  Future<List<int>> getFileBytes(String path) async {
    return await File(path).readAsBytes();
  }

  Future<void> doSingleUpload({bool signed = true}) async {
    try {
      final data = dataImages;
      List<int>? fileBytes;

      if (fileSource == FileSource.bytes) {
        fileBytes = await getFileBytes(data.path!);
      }

      CloudinaryResponse response = signed
          ? await cloudinary.upload(
              file: data.path,
              fileBytes: fileBytes,
              resourceType: CloudinaryResourceType.image,
              folder: folder,
              progressCallback: data.progressCallback,
            )
          : await cloudinary.unsignedUpload(
              file: data.path,
              fileBytes: fileBytes,
              resourceType: CloudinaryResourceType.image,
              folder: folder,
              progressCallback: data.progressCallback,
              uploadPreset: uploadPreset,
            );

      if (response.isSuccessful && response.secureUrl!.isNotEmpty) {
        setState(() {
          cloudinaryResponses = response;
        });
      } else {
        setState(() {
          errorMessage = response.error;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = e.toString();
      });
      if (kDebugMode) {
        print(e);
      }
    }
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
