library document_scanner;

import 'dart:io';

import 'package:document_scanner/src/external/shrared_pref.handle.dart';
import 'package:document_scanner/src/widgets/document_scanner.widget.dart';
import 'package:flutter/cupertino.dart';

class DocumentScanner extends StatelessWidget {
  const DocumentScanner({super.key, required this.onScanDone});

  final Function(File scannedPdf) onScanDone;

  static Future<void> clearScan() async {
    await SharedPrefHandle.clearScannedImages();
  }

  @override
  Widget build(BuildContext context) {
    return DocumentScannerWidget(
      onDone: onScanDone,
    );
  }
}
