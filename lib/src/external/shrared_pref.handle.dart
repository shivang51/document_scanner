import 'package:shared_preferences/shared_preferences.dart';

abstract class SharedPrefNames {
  static const String scannedImagesCount = "documentScannerScannedImagesCount";
  static const String scannedImages = "documentScannerScannedImages";
}

class SharedPrefHandle {
  static Future<int> getScannedImagesCount() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getInt(SharedPrefNames.scannedImagesCount) ?? 0;
  }

  static Future<List<String>> getScannedImages() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(SharedPrefNames.scannedImages) ?? [];
  }

  static Future<void> setScannedImages(List<String> images) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(SharedPrefNames.scannedImages, images);
    await prefs.setInt(SharedPrefNames.scannedImagesCount, images.length);
  }

  static Future<void> setScannedImagesCount(int count) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setInt(SharedPrefNames.scannedImagesCount, count);
  }

  static Future<void> clearScannedImages() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove(SharedPrefNames.scannedImages);
    await prefs.remove(SharedPrefNames.scannedImagesCount);
  }
}
