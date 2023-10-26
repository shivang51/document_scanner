import 'dart:io';
import 'dart:typed_data';

import 'package:crop_image/crop_image.dart';
import 'package:flutter/material.dart';

class ImageSettingsPage extends StatelessWidget {
  const ImageSettingsPage({super.key});

  static Route route(File imageFile) {
    return MaterialPageRoute<void>(
      settings: RouteSettings(arguments: imageFile),
      builder: (BuildContext context) => const ImageSettingsPage(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final imageFile = ModalRoute.of(context)!.settings.arguments as File;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Image'),
      ),
      body: ImageSettingsBody(imageFile: imageFile),
    );
  }
}

class ImageSettingsBody extends StatefulWidget {
  const ImageSettingsBody({
    super.key,
    required this.imageFile,
  });

  final File imageFile;

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

  void _convertBlackAndWhite() async {
    final byteData = await cropController.getImage()!.toByteData();

    var imagePixels = byteData!.buffer.asUint32List();

    for (var i = 0; i < imagePixels.length; i++) {
      final pixel = imagePixels[i];
      final alpha = pixel >> 24 & 0xff;
      final red = pixel >> 16 & 0xff;
      final green = pixel >> 8 & 0xff;
      final blue = pixel & 0xff;

      final gray = (red + green + blue) ~/ 3;

      final newPixel = alpha << 24 | gray << 16 | gray << 8 | gray;

      imagePixels[i] = newPixel;
    }
    cropController.image = await decodeImageFromList(imageBytes);

    setState(() {
      imageBytes = imagePixels.buffer.asUint8List();
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
              const IconButton(
                onPressed: null,
                icon: Icon(Icons.colorize_rounded),
              ),
            ],
          ),
        )
      ],
    );
  }
}
