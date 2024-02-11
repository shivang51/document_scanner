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
  bool isFiltered = false;
  bool isBW = false;
  bool isGreyScale = false;
  bool isEnhanced = false;

  bool filtering = false;

  List<Uint8List> previous = [];

  @override
  void initState() {
    cropController = CropController();
    super.initState();
  }

  void _convertBlackAndWhite() async {
    var img = cropController.getImage();

    final data = await img!.toByteData(
      format: ui.ImageByteFormat.png,
    );

    var imagePixels = data!.buffer.asUint8List();
    final grayPixels = convertToBlackAndWhite(imagePixels);

    final ui.Image grayscaleImage = await decodeImageFromList(grayPixels);
    cropController.image = grayscaleImage;

    setState(() {
      previous.add(imagePixels);
      isBW = true;
      isFiltered = true;
    });
  }

  void _undoBlackAndWhite() async {
    final ogBytes = previous.last;

    final ui.Image grayscaleImage = await decodeImageFromList(ogBytes);
    cropController.image = grayscaleImage;

    setState(() {
      previous.removeLast();
      isBW = false;
      isFiltered = false;
    });
  }

  void _convertToGreyScale() async {
    var img = cropController.getImage();

    final data = await img!.toByteData(
      format: ui.ImageByteFormat.png,
    );

    var imagePixels = data!.buffer.asUint8List();
    final grayPixels = convertToGreyScale(imagePixels);

    final ui.Image grayscaleImage = await decodeImageFromList(grayPixels);
    cropController.image = grayscaleImage;

    setState(() {
      previous.add(imagePixels);
      isGreyScale = true;
      isFiltered = true;
    });
  }

  void _undoGreyScale() async {
    final ogBytes = previous.last;

    final ui.Image grayscaleImage = await decodeImageFromList(ogBytes);
    cropController.image = grayscaleImage;

    setState(() {
      previous.removeLast();
      isGreyScale = false;
      isFiltered = false;
    });
  }

  void _enhanceImage() async {
    setState(() {
      filtering = true;
    });

    var img = cropController.getImage();

    final data = await img!.toByteData(
      format: ui.ImageByteFormat.png,
    );

    var imagePixels = data!.buffer.asUint8List();
    final enhancedPixels = enhanceImageSharpness(imagePixels);

    final ui.Image enhancedImage = await decodeImageFromList(enhancedPixels);
    cropController.image = enhancedImage;

    setState(() {
      previous.add(imagePixels);
      isEnhanced = true;
      filtering = false;
      isFiltered = true;
    });
  }

  void _undoEnhanceImage() async {
    final ogBytes = previous.last;

    final ui.Image grayscaleImage = await decodeImageFromList(ogBytes);
    cropController.image = grayscaleImage;

    setState(() {
      previous.removeLast();
      isEnhanced = false;
      isFiltered = false;
    });
  }

  Future<void> _onSave() async {
    var bitmap = await cropController.croppedBitmap();
    final data = await bitmap.toByteData(format: ui.ImageByteFormat.png);
    final bytes = data!.buffer.asUint8List();

    String imagePath = join(
      (await getTemporaryDirectory()).path,
      "${(DateTime.now().millisecondsSinceEpoch / 1000).round()}.jpeg",
    );

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
            image: Image.file(widget.imageFile),
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
                isSelected: isGreyScale,
                selectedIcon: const Icon(Icons.format_color_fill),
                onPressed: !isGreyScale
                    ? !isFiltered
                        ? _convertToGreyScale
                        : null
                    : _undoGreyScale,
                icon: const Icon(Icons.format_color_fill),
              ),
              // IconButton(
              //   isSelected: isBW,
              //   selectedIcon: const Icon(Icons.invert_colors_off_rounded),
              //   onPressed: !isBW
              //       ? !isFiltered
              //           ? _convertBlackAndWhite
              //           : null
              //       : _undoBlackAndWhite,
              //   icon: const Icon(Icons.invert_colors_rounded),
              // ),
              IconButton(
                isSelected: isEnhanced,
                selectedIcon: const Icon(Icons.brightness_high),
                onPressed: !filtering
                    ? isEnhanced
                        ? _undoEnhanceImage
                        : !isFiltered
                            ? _enhanceImage
                            : null
                    : null,
                icon: Icon(
                  !filtering ? Icons.brightness_high : Icons.brightness_low,
                ),
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
