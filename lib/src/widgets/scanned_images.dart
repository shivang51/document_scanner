import 'dart:io';
import 'package:document_scanner/src/external/shrared_pref.handle.dart';
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

    String imagePath = join((await getTemporaryDirectory()).path,
        "${(DateTime.now().millisecondsSinceEpoch / 1000).round()}.jpeg");

    bool success = await EdgeDetection.detectEdge(
      imagePath,
    );

    if (!success) return;

    final imageFile = File(imagePath);
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

  @override
  void initState() {
    SharedPrefHandle.getScannedImages().then((imagesPath) {
      setState(() {
        pickedImages = imagesPath.map((e) => File(e)).toList();
      });
    });
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
            ),
          )
          .toList(),
    );
  }
}
