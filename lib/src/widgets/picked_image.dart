import 'dart:io';

import 'package:document_scanner/src/pages/image_settings.page.dart';
import 'package:flutter/material.dart';

class PickedImage extends StatelessWidget {
  const PickedImage({
    super.key,
    required this.image,
    required this.onRemove,
    required this.onUpdate,
    required this.onInvertAll,
  });

  final File image;
  final Function(File image) onRemove;
  final Function() onInvertAll;
  final Function(File oldImage, File image) onUpdate;

  void onSave(File newImage) {
    onUpdate(image, newImage);
  }

  void onImageClick(BuildContext context) {
    final args = ImageSettingsPageArgs(image, onSave, onInvertAll);
    Navigator.of(context).push(
      ImageSettingsPage.route(args),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () => onImageClick(context),
      style: ElevatedButton.styleFrom(
        padding: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8.0),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      child: Stack(
        children: [
          Align(
            alignment: Alignment.center,
            child: Image.file(image),
          ),
          Align(
            alignment: Alignment.topRight,
            child: IconButton.outlined(
              onPressed: () => onRemove(image),
              icon: const Icon(Icons.delete_rounded),
              color: Colors.red,
            ),
          )
        ],
      ),
    );
  }
}
