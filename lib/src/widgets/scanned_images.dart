import 'dart:io';
import 'package:document_scanner/src/external/shrared_pref.handle.dart';
import 'package:document_scanner/src/utils/utils.dart';
import 'package:edge_detection/edge_detection.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:reorderable_grid_view/reorderable_grid_view.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

import 'picked_image.dart';

class ScannedImages extends StatefulWidget {
  const ScannedImages({
    super.key,
    required this.onAddFile,
    required this.onRemoveFile,
    required this.onUpdateFile,
  });

  final Function(File file) onAddFile;
  final Function(File file) onRemoveFile;
  final Function(List<File> file) onUpdateFile;

  @override
  State<ScannedImages> createState() => _ScannedImagesState();
}

class _ScannedImagesState extends State<ScannedImages> {
  final double scannedImageWidth = 150.0;

  String tempPath = "";
  int invertProgress = 0;
  bool inverting = false;

  List<File> pickedImages = [];

  Future<bool> _checkPermission() async {
    // Check permissions and request its
    bool isCameraGranted = await Permission.camera.request().isGranted;
    if (!isCameraGranted) {
      isCameraGranted =
          await Permission.camera.request() == PermissionStatus.granted;
    }
    return isCameraGranted;
  }

  void _onAddImage() async {
    await _checkPermission();

    String imagePath = join(tempPath,
        "${(DateTime.now().millisecondsSinceEpoch / 1000).round()}.jpeg");

    bool success = await EdgeDetection.detectEdge(
      imagePath,
    );

    if (!success) return;

    final imageFile = File(imagePath);

    if (pickedImages.contains(imageFile)) return;

    setState(() {
      pickedImages.add(imageFile);
      widget.onAddFile(imageFile);
    });
  }

  void _onRemoveImage(File image) {
    setState(() {
      pickedImages.remove(image);
      widget.onRemoveFile(image);
    });
  }

  void _onUpdateImage(File oldImage, File image) {
    setState(() {
      int ind = pickedImages.indexOf(oldImage);
      pickedImages[ind] = image;
      widget.onUpdateFile(pickedImages);
    });
  }

  void _invertAll(BuildContext context) {
    setState(() {
      invertProgress = 0;
      inverting = true;
    });

    for (var ind = 0; ind < pickedImages.length; ind++) {
      final image = pickedImages[ind];

      final grayPixels = convertToBlackAndWhite(image.readAsBytesSync());
      String imagePath = join(
        tempPath,
        "${(DateTime.now().millisecondsSinceEpoch / 1000).round()}.jpeg",
      );

      File file = File(imagePath);
      file.writeAsBytesSync(grayPixels);

      setState(() {
        image.delete();
        pickedImages[ind] = file;
        invertProgress += 1;
      });
    }

    Navigator.of(context).pop();
    Navigator.of(context).pop();

    setState(() {
      widget.onUpdateFile(pickedImages);
      inverting = false;
      invertProgress = 0;
    });
  }

  void _onInvertAll(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog.adaptive(
          title: const Text("Are you sure?"),
          content: const Text("This action is not reversible."),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () => _invertAll(context),
              child: const Text("Continue"),
            )
          ],
        );
      },
    );
  }

  @override
  void initState() {
    SharedPrefHandle.getScannedImages().then((imagesPath) {
      setState(() {
        for (final imagePath in imagesPath) {
          final image = File(imagePath);
          if (!image.existsSync() || pickedImages.contains(image)) continue;
          pickedImages.add(image);
        }
        widget.onUpdateFile(pickedImages);
      });
    });
    if (tempPath == "") {
      getTemporaryDirectory().then((value) => tempPath = value.path);
    }
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final crossAxisCount =
        MediaQuery.of(context).size.width ~/ (scannedImageWidth + 20);
    return ReorderableGridView.count(
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      crossAxisCount: crossAxisCount,
      dragStartDelay: const Duration(milliseconds: 100),
      onReorder: (oldIndex, newIndex) {
        setState(() {
          final item = pickedImages.removeAt(oldIndex);
          pickedImages.insert(newIndex, item);
        });
      },
      dragWidgetBuilderV2: DragWidgetBuilderV2(
        builder: (index, child, screenshot) {
          final el = pickedImages[index];
          return Card(
            child: Image.file(el),
          );
        },
      ),
      footer: [
        ElevatedButton(
          key: const ValueKey('add-image'),
          onPressed: _onAddImage,
          style: ElevatedButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          child: const Icon(Icons.add),
        ),
      ],
      children: pickedImages
          .map(
            (e) => PickedImage(
              key: ValueKey(e),
              image: e,
              onRemove: _onRemoveImage,
              onUpdate: _onUpdateImage,
              onInvertAll: () => _onInvertAll(context),
            ),
          )
          .toList(),
    );
  }
}
