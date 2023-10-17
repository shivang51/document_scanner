import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path/path.dart' as dart_path;

import "./uuid_handle.dart";

class PdfHandle {
  static Future<File> imagesToPdf(List<File> images) async {
    final document = pw.Document();
    for (var image in images) {
      final imageData = image.readAsBytesSync();
      final page = _createPage(imageData);
      document.addPage(page);
    }
    return _saveDocument(document);
  }

  static Future<File> rawImagesToPdf(List<Uint8List> images) async {
    final document = pw.Document();
    for (var imageData in images) {
      final page = _createPage(imageData);
      document.addPage(page);
    }
    return _saveDocument(document);
  }

  static pw.Page _createPage(Uint8List imageData) {
    final rawImage = pw.MemoryImage(imageData);

    final imageSize = _scaleSize(
      Size(
        rawImage.width!.toDouble(),
        rawImage.height!.toDouble(),
      ),
      Size(PdfPageFormat.a4.width, PdfPageFormat.a4.height),
    );

    final page = pw.Page(
      pageFormat: PdfPageFormat.a4,
      build: (pw.Context context) {
        return pw.Center(
          child: pw.Image(
            rawImage,
            width: imageSize.width,
            height: imageSize.height,
          ),
        );
      },
    );

    return page;
  }

  static Future<File> _saveDocument(pw.Document document) async {
    var tempDir = await getTemporaryDirectory();
    var savePath = dart_path.join(tempDir.path, "${UuidHandle.generate()}.pdf");
    var savedFile = await File(savePath).writeAsBytes(
      await document.save(),
    );
    return savedFile;
  }

  static Size _scaleSize(Size imageSize, Size pdfPageSize) {
    var imageWidth = imageSize.width;
    var imageHeight = imageSize.height;

    final pageWidth = pdfPageSize.width;
    final pageHeight = pdfPageSize.height;

    final ar = imageWidth / imageHeight;

    imageWidth = min(pageWidth, imageWidth);
    imageHeight = imageWidth / ar;

    if (imageHeight > pageHeight) {
      imageHeight = min(pageHeight, imageHeight);
      imageWidth = imageHeight * ar;
    }

    return Size(imageWidth, imageHeight);
  }
}
