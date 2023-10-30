import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:crop_image/crop_image.dart';
import 'package:document_scanner/src/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

class ImageSettingsPageArgs {
  const ImageSettingsPageArgs(
    this.imageFile,
    this.onSaveFile,
    this.onInvertAll,
  );

  final File imageFile;
  final Function(File newImage) onSaveFile;
  final Function() onInvertAll;
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
        onInvertAll: args.onInvertAll,
      ),
    );
  }
}

class ImageSettingsBody extends StatefulWidget {
  const ImageSettingsBody({
    super.key,
    required this.imageFile,
    required this.onImageSave,
    required this.onInvertAll,
  });

  final File imageFile;
  final Function(File newImage) onImageSave;
  final Function() onInvertAll;

  @override
  State<ImageSettingsBody> createState() => _ImageSettingsBodyState();
}

class _ImageSettingsBodyState extends State<ImageSettingsBody> {
  late CropController cropController;
  late Uint8List imageBytes;
  bool isBW = false;

  @override
  void initState() {
    cropController = CropController();
    imageBytes = widget.imageFile.readAsBytesSync();

    super.initState();
  }

  void _convertBlackAndWhite() async {
    var bitmap = await cropController.croppedBitmap();

    final data = await bitmap.toByteData(
      format: ui.ImageByteFormat.png,
    );

    var imagePixels = data!.buffer.asUint8List();
    final grayPixels = convertToBlackAndWhite(imagePixels);

    final ui.Image grayscaleImage = await decodeImageFromList(grayPixels);
    cropController.image = grayscaleImage;

    setState(() {
      imageBytes = imagePixels.buffer.asUint8List();
      isBW = true;
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

  void _undoBlackAndWhite() async {
    final ogBytes = widget.imageFile.readAsBytesSync();

    final ui.Image grayscaleImage = await decodeImageFromList(ogBytes);
    cropController.image = grayscaleImage;

    setState(() {
      imageBytes = ogBytes;
      isBW = false;
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
                isSelected: isBW,
                selectedIcon: const Icon(Icons.invert_colors_off_rounded),
                onPressed: !isBW ? _convertBlackAndWhite : _undoBlackAndWhite,
                icon: const Icon(Icons.invert_colors_rounded),
              ),
              IconButton(
                onPressed: () => _onSaveWithMsg(context),
                icon: const Icon(Icons.save),
              ),
              TextButton(
                onPressed: widget.onInvertAll,
                child: const Text("Invert All"),
              )
            ],
          ),
        )
      ],
    );
  }
}
