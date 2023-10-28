import 'dart:io';

import 'package:document_scanner/src/external/pdf_handle.dart';
import 'package:document_scanner/src/external/shrared_pref.handle.dart';
import 'package:document_scanner/src/widgets/scanned_images.dart';
import 'package:flutter/material.dart';

class DocumentScannerWidget extends StatefulWidget {
  const DocumentScannerWidget({super.key, required this.onDone});

  final Function(File scannedPdf) onDone;

  static Future<void> clearScan() async {
    await SharedPrefHandle.clearScannedImages();
  }

  @override
  State<DocumentScannerWidget> createState() => _DocumentScannerWidgetState();
}

class _DocumentScannerWidgetState extends State<DocumentScannerWidget> {
  List<File> pickedImages = [];

  void onDoneClick() {
    PdfHandle.imagesToPdf(pickedImages).then(
      (pdfFile) => widget.onDone(pdfFile),
    );
  }

  void onAddFile(File file) {
    if (pickedImages.contains(file)) return;

    setState(() {
      pickedImages.add(file);
    });
    var pickedImagesPath = pickedImages.map((e) => e.path).toList();
    SharedPrefHandle.setScannedImages(pickedImagesPath);
  }

  void onRemoveFile(File file) {
    setState(() {
      pickedImages.remove(file);
    });
    var pickedImagesPath = pickedImages.map((e) => e.path).toList();
    SharedPrefHandle.setScannedImages(pickedImagesPath);
  }

  void onUpdateFile(List<File> files) {
    setState(() {
      pickedImages = files;
    });
    var pickedImagesPath = pickedImages.map((e) => e.path).toList();
    SharedPrefHandle.setScannedImages(pickedImagesPath);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Document Scanner'),
        actions: [
          Text("${pickedImages.length} scans"),
          const SizedBox(width: 8),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: ScannedImages(
          onAddFile: onAddFile,
          onRemoveFile: onRemoveFile,
          onUpdateFile: onUpdateFile,
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: onDoneClick,
        label: const Text("Done"),
        icon: const Icon(Icons.done_rounded),
      ),
    );
  }
}
