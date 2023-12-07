import 'dart:math';
import 'dart:typed_data';

import 'package:image/image.dart' as image_lib;

Uint8List convertToBlackAndWhite(Uint8List imagePixels) {
  var img = image_lib.decodeImage(imagePixels)!;
  const threshold = 127.0;

  for (var p in img) {
    var value = 0;
    if (p.r >= threshold && p.g >= threshold && p.b >= threshold) value = 255;
    p.setRgb(value, value, value);
  }

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

double _getThresholdFromPixels(Uint8List pixels) {
  // Calculate the average pixel value.
  int averagePixelValue = 0;
  for (int i = 0; i < pixels.length; i++) {
    averagePixelValue += pixels[i];
  }
  averagePixelValue ~/= pixels.length;

  // Calculate the standard deviation of the pixel values.
  double standardDeviation = 0.0;
  for (int i = 0; i < pixels.length; i++) {
    standardDeviation += pow(pixels[i] - averagePixelValue, 2).toDouble();
  }
  standardDeviation = sqrt(standardDeviation / pixels.length);

  // Calculate the threshold.
  double threshold = averagePixelValue - standardDeviation;

  // Return the threshold.

  return threshold.abs();
}
