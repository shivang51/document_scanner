import 'dart:typed_data';

// ignore: depend_on_referenced_packages
import 'package:image/image.dart' as image_lib;

Uint8List compressImage(Uint8List imagePixels) {
  var img = image_lib.decodeImage(imagePixels)!;
  img = image_lib.copyResize(img, width: 512);
  return image_lib.encodePng(img);
}

Uint8List convertToBlackAndWhite(Uint8List imagePixels) {
  var img = image_lib.decodeImage(imagePixels)!;
  img = _applyAdaptiveMeanC(img);
  return image_lib.encodePng(img);
}

Uint8List convertToGreyScale(Uint8List imagePixels) {
  var grayImage = image_lib.decodeImage(imagePixels)!;
  grayImage = image_lib.grayscale(grayImage);
  return image_lib.encodePng(grayImage);
}

Uint8List enhanceImageSharpness(Uint8List imagePixels) {
  var image = image_lib.decodeImage(imagePixels)!;
  // image = image_lib.adjustColor(image, brightness: .5);
  image = image_lib.contrast(image, contrast: 110);
  return image_lib.encodePng(image);
}

image_lib.Image _applyAdaptiveMeanC(image_lib.Image image) {
  int constant = 2;
  image_lib.Image outputImage = image_lib.Image(
    width: image.width,
    height: image.height,
  );
  image_lib.Image grayscaleImage = image_lib.grayscale(image);

  for (int y = 0; y < grayscaleImage.height; ++y) {
    for (int x = 0; x < grayscaleImage.width; ++x) {
      int sum = _pixelToARGB(grayscaleImage.getPixelSafe(x, y)) & 0xFF;
      int count = 1;
      for (int dy = -1; dy <= 1; ++dy) {
        for (int dx = -1; dx <= 1; ++dx) {
          int nx = (x + dx).clamp(0, grayscaleImage.width - 1);
          int ny = (y + dy).clamp(0, grayscaleImage.height - 1);
          var p = grayscaleImage.getPixelSafe(nx, ny);
          sum += _pixelToARGB(p) & 0xFF;
          count++;
        }
      }
      int mean = (sum / count).round();
      int threshold = mean - constant;
      int pixelValue = _pixelToARGB(grayscaleImage.getPixelSafe(x, y)) & 0xFF;
      outputImage.setPixel(
        x,
        y,
        (pixelValue < threshold)
            ? image_lib.ColorRgb8(0, 0, 0)
            : image_lib.ColorRgb8(255, 255, 255),
      );
    }
  }
  return outputImage;
}

int _pixelToARGB(image_lib.Pixel p) {
  int alpha = 0xFF; // Full opacity (255)
  int red = p.r.toInt() & 0xFF;
  int green = p.g.toInt() & 0xFF;
  int blue = p.b.toInt() & 0xFF;

  int argbValue = (alpha << 24) | (red << 16) | (green << 8) | blue;
  return argbValue;
}
