import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import 'dart:io';
import '/services/services.dart' show ErrorService;
import '/theme/theme.dart';
import '/views/views.dart';
import '/utils/utils.dart';

class Download {
  static Future<void> downloadFromUrl(
    BuildContext context,
    String url,
    String? name,
  ) async {
    final dio = Dio();
    int progress = 0;

    var directory = await getApplicationDocumentsDirectory();
    if (Platform.isWindows) {
      directory = (await getDownloadsDirectory())!;
    }

    String savePath = name != null
        ? '${directory.path}/$name'
        : '${directory.path}/${url.split('/').last}';

    // Create an OverlayEntry to show live progress
    OverlayState overlayState = Overlay.of(context);
    OverlayEntry overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        bottom: 80,
        left: 0,
        right: 0,
        child: Align(
          alignment: Alignment.bottomCenter,
          child: _DownloadProgressIndicator(progress: progress),
        ),
      ),
    );

    // Show overlay progress
    overlayState.insert(overlayEntry);

    try {
      await dio.download(
        url,
        savePath,
        onReceiveProgress: (received, total) {
          if (total > 0) {
            progress = (received / total * 100).toInt();

            // Rebuild overlay to reflect progress updates
            overlayEntry.markNeedsBuild();
          }
        },
      );

      // Remove overlay when completed
      overlayEntry.remove();
      FlushBar.show(context, "Download Completed", isSuccess: true);

      openfile(savePath, context);
    } catch (e, st) {
      debugPrint("${e.toString()}, ${st.toString()}");
      await ErrorService.recordError(e, st);
      overlayEntry.remove();
      FlushBar.show(
        context,
        "Download Failed",
        isSuccess: false,
        error: e,
        stackTrace: st,
      );
    }
  }
}

class _DownloadProgressIndicator extends StatelessWidget {
  final int progress;
  const _DownloadProgressIndicator({required this.progress});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.transparent,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.black87,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(value: progress / 100),
            const SizedBox(width: 10),
            Text(
              'Downloading... $progress%',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppColors.white),
            ),
          ],
        ),
      ),
    );
  }
}

Future<String> saveFileToDownloads(Uint8List bytes, {String? fileName}) async {
  Directory? dir;

  if (Platform.isAndroid) {
    // There is no true "Downloads" via path_provider on Android.
    // This will create/use a Download folder inside external storage for your app.
    final baseDir =
        await getExternalStorageDirectory(); // e.g. /storage/emulated/0/Android/data/your.app/files
    if (baseDir == null) {
      throw Exception('Could not get external storage directory.');
    }
    dir = Directory('${baseDir.path}/Download');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
  } else if (Platform.isIOS) {
    // iOS doesn't have a public Downloads folder.
    // Best is app's Documents directory (visible in Files app under your app).
    dir = await getApplicationDocumentsDirectory(); // e.g. ./Documents
  } else if (Platform.isWindows) {
    // On desktop, path_provider has getDownloadsDirectory()
    dir = await getDownloadsDirectory();
    dir ??= await getApplicationDocumentsDirectory();
  } else if (Platform.isMacOS || Platform.isLinux) {
    // On Unix systems, Downloads is usually under HOME
    final downloads = await getDownloadsDirectory();
    if (downloads != null) {
      dir = downloads;
    } else {
      final home = Platform.environment['HOME'];
      if (home != null) {
        dir = Directory('$home/Downloads');
      } else {
        dir = await getApplicationDocumentsDirectory();
      }
    }
  } else {
    // Fallback for other platforms (Fuchsia, etc.)
    dir = await getApplicationDocumentsDirectory();
  }

  final safeFileName = fileName == null || fileName.isEmpty
      ? Uuid().v4()
      : fileName;
  final file = File('${dir.path}/$safeFileName');

  await file.writeAsBytes(bytes, flush: true);
  return file.path;
}
