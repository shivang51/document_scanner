import 'dart:io';

import 'package:document_scanner/src/external/pdf_handle.dart';
import 'package:document_scanner/src/widgets/scanned_images.dart';
import 'package:flutter/material.dart';

class DocumentScannerWidget extends StatefulWidget {
  const DocumentScannerWidget({super.key, required this.onDone});

  final Function(File scannedPdf) onDone;

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
    pickedImages.add(file);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Document Scanner'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: ScannedImages(
          onAddFile: onAddFile,
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
