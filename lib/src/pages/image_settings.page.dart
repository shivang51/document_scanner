import 'dart:io';

import 'package:crop_image/crop_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class ImageSettingsPage extends StatelessWidget {
  const ImageSettingsPage({super.key});

  static const routeName = '/image-settings';

  static Route route(File imageFile) {
    return MaterialPageRoute<void>(
      settings: RouteSettings(arguments: imageFile),
      builder: (BuildContext context) => const ImageSettingsPage(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final imageFile = ModalRoute.of(context)!.settings.arguments as File;

    return CropImage(
      image: Image.file(imageFile),
    );
  }
}
