import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart' as dp;
import 'package:flutter/services.dart';
// import 'package:image_compression_flutter/image_compression_flutter.dart';
import 'package:uuid/uuid.dart';
import '/services/services.dart';
import '/constants/constants.dart';

class StorageService {
  static final storage = FirebaseStorage.instance.ref();

  // static Future<Uint8List?> _compressImage(String path) async {
  //   try {
  //     File file = File(path);
  //     if (file.existsSync()) {
  //       ImageFile input = ImageFile(
  //         rawBytes: await file.readAsBytes(),
  //         filePath: file.path, // Pass the file path
  //         contentType: 'images/png',
  //       );

  //       Configuration config = const Configuration(
  //         outputType: ImageOutputType.webpThenJpg,
  //         useJpgPngNativeCompressor: false,
  //         quality: 60,
  //       );
  //       final param = ImageFileConfiguration(input: input, config: config);
  //       final output = await compressor.compress(param);

  //       return output.rawBytes;
  //     }
  //     return null;
  //   } catch (e, st) {
  //     dp.debugPrint("${e.toString()}, ${st.toString()}");
  //     throw e.toString();
  //   }
  // }

  static Future<String> uploadFile({
    required File file,
    required StorageFolder folder,
  }) async {
    var cid = await Spdb.getCid();
    var uid = const Uuid().v1();

    String downloadLink;
    final uploadDir = storage.child(
      "$cid/${folder.name}/$uid.${file.path.split('.').last}",
    );

    try {
      const imageExtensions = [
        "png",
        "jpg",
        "jpeg",
        "webp",
        "bmp",
        "gif",
        "tiff",
      ];
      if (imageExtensions.contains(file.path.split('.').last)) {
        // final compressedImageBytes = await _compressImage(file.path);

        // if (compressedImageBytes != null) {
        // Upload using putData instead of putFile
        UploadTask uploadTask = uploadDir.putData(
          Uint8List.fromList(file.readAsBytesSync()),
        );

        // Wait for upload to complete
        TaskSnapshot taskSnapshot = await uploadTask;
        downloadLink = await taskSnapshot.ref.getDownloadURL();

        return downloadLink;
        // }
      }

      final fileBytes = await file.readAsBytes();

      // Upload using putData instead of putFile
      UploadTask uploadTask = uploadDir.putData(Uint8List.fromList(fileBytes));

      // Wait for upload to complete
      TaskSnapshot taskSnapshot = await uploadTask;
      downloadLink = await taskSnapshot.ref.getDownloadURL();
      return downloadLink;
    } catch (e, st) {
      await ErrorService.recordError(e, st);
      dp.debugPrint("${e.toString()}, ${st.toString()}");
      throw e.toString();
    }
  }

  static Future<String> uploadImage({
    required File file,
    required StorageFolder folder,
    String? collectionId,
  }) async {
    String cid = "";
    if (collectionId == null) {
      cid = await Spdb.getCid() ?? '';
    } else {
      cid = collectionId;
    }

    var uid = const Uuid().v1();

    String downloadLink;
    final uploadDir = storage.child("$cid/${folder.name}/$uid.webp");

    try {
      final originalImageBytes = await file.readAsBytes();

      // ImageFile input = ImageFile(
      //   rawBytes: originalImageBytes,
      //   filePath: file.path, // Pass the file path
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

      // Upload using putData instead of putFile
      UploadTask uploadTask = uploadDir.putData(
        Uint8List.fromList(originalImageBytes),
      );

      // Wait for upload to complete
      TaskSnapshot taskSnapshot = await uploadTask;
      downloadLink = await taskSnapshot.ref.getDownloadURL();
    } catch (e, st) {
      await ErrorService.recordError(e, st);
      dp.debugPrint("${e.toString()}, ${st.toString()}");
      throw e.toString();
    }
    return downloadLink;
  }

  static Future<List<String>> uploadFilesInBatch({
    required List<File> files,
    required StorageFolder folder,
    String? collectionId,
  }) async {
    String cid = collectionId ?? await Spdb.getCid() ?? '';

    // Use `Future.wait` for concurrent uploads
    List<Future<String>> uploadTasks = files.map((file) async {
      try {
        var uid = const Uuid().v1();
        final uploadDir = storage.child(
          "$cid/${folder.name}/$uid.${file.path.split('.').last}",
        );

        final fileBytes = await file.readAsBytes();

        // Upload using putData
        UploadTask uploadTask = uploadDir.putData(
          Uint8List.fromList(fileBytes),
        );

        // Wait for upload to complete and return the download URL
        TaskSnapshot taskSnapshot = await uploadTask;
        return await taskSnapshot.ref.getDownloadURL();
      } catch (e, st) {
        await ErrorService.recordError(e, st);
        dp.debugPrint("${e.toString()}, ${st.toString()}");
        throw "Error uploading file ${file.path}: ${e.toString()}";
      }
    }).toList();

    // Wait for all uploads to complete
    return await Future.wait(uploadTasks);
  }

  static Future<bool> deleteImage(String imageUrl) async {
    try {
      if (imageUrl.isNotEmpty) {
        final Reference storageRef = FirebaseStorage.instance.refFromURL(
          imageUrl,
        );
        await storageRef.delete();
        return true;
      }
      return false;
    } catch (e, st) {
      await ErrorService.recordError(e, st);
      dp.debugPrint("${e.toString()}, ${st.toString()}");
      if (e is FirebaseException && e.code == 'object-not-found') {
        return false;
      }
      throw e.toString();
    }
  }

  // static Future<bool> deleteFolder({required StorageFolder folder}) async {
  //   try {
  //     var cid = await Db.getData(type: UserData.collectionId);
  //     final dir = storage.child("$cid/${folder.name}");

  //     final listResult = await dir.listAll();

  //     for (var fileRef in listResult.items) {
  //       await fileRef.delete();
  //     }

  //     return true;
  //   } catch (e, st) {
  //     if (e is FirebaseException && e.code == 'object-not-found') {
  //       return false;
  //     }
  //     throw e.toString();
  //   }
  // }
}
