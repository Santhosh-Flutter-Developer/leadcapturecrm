import 'dart:io';
import 'package:file_picker/file_picker.dart';

class FilePick {
  static List<File>? selectedFile;

  static Future<List<File>?> pickFiles(context) async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
    );

    if (result != null) {
      List<File> files = result.paths.map((path) => File(path!)).toList();
      return files;
    } else {
      return null;
    }
  }

  static Future<File?> pickFile(
    context, {
    List<String>? allowedExtensions,
  }) async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      allowedExtensions: allowedExtensions,
      type: allowedExtensions != null ? FileType.custom : FileType.any,
    );

    if (result != null) {
      List<File> files = result.paths.map((path) => File(path!)).toList();
      return files.first;
    } else {
      return null;
    }
  }

  static Future<List<File>?> pickFileWithExtensions(
    context, {
    List<String>? allowedExtensions,
  }) async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      allowedExtensions: allowedExtensions,
      type: allowedExtensions != null ? FileType.custom : FileType.any,
      allowMultiple: true,
    );

    if (result != null) {
      List<File> files = result.paths.map((path) => File(path!)).toList();
      return files;
    } else {
      return null;
    }
  }
}
