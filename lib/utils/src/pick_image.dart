import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_exif_rotation/flutter_exif_rotation.dart';
import 'package:image_picker/image_picker.dart';
import '/services/services.dart';
import '/views/views.dart';

class PickImage {
  static final ImagePicker _picker = ImagePicker();

  static Future<File?> selectImage(context) async {
    var pickOption = await Sheet.showSheet(
      context,
      widget: const PickOption(),
      size: 0.2,
    );
    if (pickOption != null) {
      if (pickOption == 1) {
        var image = await PickImage._captureImage();
        if (image != null) {
          return image;
        }
      } else {
        var image = await PickImage._pickImage();
        if (image != null) {
          return image;
        }
      }
    }
    return null;
  }

  static Future<File?> _captureImage() async {
    try {
      XFile? tmpImage = await _picker.pickImage(source: ImageSource.camera);
      if (tmpImage != null) {
        File rotatedImage = await FlutterExifRotation.rotateImage(
          path: tmpImage.path,
        );
        File image = File(rotatedImage.path);

        final originalImageBytes = await image.readAsBytes();
        // ImageFile input = ImageFile(
        //   rawBytes: originalImageBytes,
        //   filePath: image.path, // Pass the file path
        //   contentType: 'images/png',
        // );

        // Configuration config = const Configuration(
        //   outputType: ImageOutputType.webpThenJpg,
        //   // can only be true for Android and iOS while using ImageOutputType.jpg or ImageOutputType.pngÏ
        //   useJpgPngNativeCompressor: false,
        //   // set quality between 0-100
        //   quality: 40,
        // );
        // final param = ImageFileConfiguration(input: input, config: config);
        // final output = await compressor.compress(param);

        return image.writeAsBytes(originalImageBytes);
      }
      return null;
    } catch (e, st) {
      await ErrorService.recordError(e, st);
      debugPrint("${e.toString()}, ${st.toString()}");
      throw e.toString();
    }
  }

  static Future<File?> _pickImage() async {
    try {
      XFile? tmpImage = await _picker.pickImage(source: ImageSource.gallery);

      if (tmpImage != null) {
        File image = File(tmpImage.path);
        return image;
      }

      return null;
    } catch (e, st) {
      await ErrorService.recordError(e, st);
      debugPrint("${e.toString()}, ${st.toString()}");
      throw e.toString();
    }
  }

  static Future<List<File>> pickMultipleImages() async {
    try {
      List<XFile>? tmpImages = await _picker.pickMultiImage();
      if (tmpImages.isNotEmpty) {
        List<File> images = [];
        for (var tmpImage in tmpImages) {
          File rotatedImage = await FlutterExifRotation.rotateImage(
            path: tmpImage.path,
          );
          File image = File(rotatedImage.path);

          final originalImageBytes = await image.readAsBytes();
          // ImageFile input = ImageFile(
          //   rawBytes: originalImageBytes,
          //   filePath: image.path, // Pass the file path
          //   contentType: 'images/png',
          // );

          // Configuration config = const Configuration(
          //   outputType: ImageOutputType.webpThenJpg,
          //   // can only be true for Android and iOS while using ImageOutputType.jpg or ImageOutputType.pngÏ
          //   useJpgPngNativeCompressor: false,
          //   // set quality between 0-100
          //   quality: 40,
          // );
          // final param = ImageFileConfiguration(input: input, config: config);
          // final output = await compressor.compress(param);

          images.add(await image.writeAsBytes(originalImageBytes));
        }
        return images;
      }
      return [];
    } catch (e, st) {
      await ErrorService.recordError(e, st);
      debugPrint("${e.toString()}, ${st.toString()}");
      throw e.toString();
    }
  }
}
