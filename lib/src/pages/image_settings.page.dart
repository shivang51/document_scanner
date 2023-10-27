import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:image/image.dart' as image;
import 'package:crop_image/crop_image.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

class ImageSettingsPageArgs {
  const ImageSettingsPageArgs(this.imageFile, this.onSaveFile);

  final File imageFile;
  final Function(File newImage) onSaveFile;
}

class ImageSettingsPage extends StatelessWidget {
  const ImageSettingsPage({super.key});

  static Route route(ImageSettingsPageArgs args) {
    return MaterialPageRoute<void>(
      settings: RouteSettings(arguments: args),
      builder: (BuildContext context) => const ImageSettingsPage(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final args =
        ModalRoute.of(context)!.settings.arguments as ImageSettingsPageArgs;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Image'),
      ),
      body: ImageSettingsBody(
        imageFile: args.imageFile,
        onImageSave: args.onSaveFile,
      ),
    );
  }
}

class ImageSettingsBody extends StatefulWidget {
  const ImageSettingsBody({
    super.key,
    required this.imageFile,
    required this.onImageSave,
  });

  final File imageFile;
  final Function(File newImage) onImageSave;

  @override
  State<ImageSettingsBody> createState() => _ImageSettingsBodyState();
}

class _ImageSettingsBodyState extends State<ImageSettingsBody> {
  late CropController cropController;
  late Uint8List imageBytes;

  @override
  void initState() {
    cropController = CropController();
    imageBytes = widget.imageFile.readAsBytesSync();

    super.initState();
  }

  double _getThresholdFromPixels(Uint8List pixels) {
    // Calculate the average pixel value.
    int averagePixelValue = 0;
    for (int i = 0; i < pixels.length; i++) {
      averagePixelValue += pixels[i];
    }
    averagePixelValue ~/= pixels.length;

    // Calculate the standard deviation of the pixel values.
    double standardDeviation = 0.0;
    for (int i = 0; i < pixels.length; i++) {
      standardDeviation += pow(pixels[i] - averagePixelValue, 2).toDouble();
    }
    standardDeviation = sqrt(standardDeviation / pixels.length);

    // Calculate the threshold.
    double threshold = averagePixelValue - standardDeviation;

    // Return the threshold.
    return threshold;
  }

  void _convertBlackAndWhite() async {
    var bitmap = await cropController.croppedBitmap();

    final data = await bitmap.toByteData(
      format: ui.ImageByteFormat.png,
    );

    var imagePixels = data!.buffer.asUint8List();
    final grayImage = image.decodeImage(imagePixels)!;

    final threshold = _getThresholdFromPixels(imagePixels);

    debugPrint(threshold.toString());

    for (var e in grayImage) {
      e.setRgb(
        e.r > threshold ? 255 : 0,
        e.g > threshold ? 255 : 0,
        e.b > threshold ? 255 : 0,
      );
    }

    final ui.Image grayscaleImage = await decodeImageFromList(
      image.encodePng(grayImage),
    );
    cropController.image = grayscaleImage;

    setState(() {
      imageBytes = imagePixels.buffer.asUint8List();
    });
  }

  Future<void> _onSave() async {
    var bitmap = await cropController.croppedBitmap();
    final data = await bitmap.toByteData(format: ui.ImageByteFormat.png);
    final bytes = data!.buffer.asUint8List();

    String imagePath = join((await getTemporaryDirectory()).path,
        "${(DateTime.now().millisecondsSinceEpoch / 1000).round()}.jpeg");

    final newFile = File(imagePath);
    newFile.writeAsBytesSync(bytes);

    widget.onImageSave(newFile);
  }

  void _onSaveWithMsg(BuildContext context) {
    _onSave().then((value) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Image updated'),
        ),
      );
      Navigator.of(context).pop();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: CropImage(
            controller: cropController,
            image: Image.memory(imageBytes),
            gridColor: Colors.blueAccent,
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              IconButton(
                onPressed: () {
                  cropController.rotateLeft();
                },
                icon: const Icon(Icons.rotate_left_rounded),
              ),
              IconButton(
                onPressed: () {
                  cropController.rotateRight();
                },
                icon: const Icon(Icons.rotate_right_rounded),
              ),
              IconButton(
                onPressed: _convertBlackAndWhite,
                icon: const Icon(Icons.colorize_rounded),
              ),
              IconButton(
                onPressed: () => _onSaveWithMsg(context),
                icon: const Icon(Icons.save),
              ),
            ],
          ),
        )
      ],
    );
  }
}
