import 'dart:io';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import 'package:permission_handler/permission_handler.dart';

class DownloadService {
  final Dio _dio = Dio();

  /// Downloads the APK at [url] to local storage, reporting progress via
  /// [onProgress] (0.0 to 1.0), then opens the Android installer for it.
  Future<void> downloadAndInstall({
    required String url,
    required String fileName,
    required void Function(double progress) onProgress,
  }) async {
    // Android 8+ requires the "install unknown apps" permission, granted
    // per-app in Settings. requestInstallPackages covers this.
    final status = await Permission.requestInstallPackages.request();
    if (!status.isGranted) {
      throw Exception(
          'Permission to install apps was denied. Enable "Install unknown apps" for this app in Settings.');
    }

    final dir = await getExternalStorageDirectory();
    final savePath = '${dir!.path}/$fileName';

    await _dio.download(
      url,
      savePath,
      onReceiveProgress: (received, total) {
        if (total > 0) {
          onProgress(received / total);
        }
      },
    );

    final file = File(savePath);
    if (await file.exists()) {
      await OpenFilex.open(savePath);
    } else {
      throw Exception('Download finished but file was not found.');
    }
  }
}
