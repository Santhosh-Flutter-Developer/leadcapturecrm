import 'package:another_flushbar/flushbar.dart';
import 'package:flutter/material.dart';
import '/theme/theme.dart';
import '/utils/utils.dart';
import '/views/views.dart';

class FlushBar {
  static void show(
    BuildContext context,
    String message, {
    bool isSuccess = true,
    Object? error,
    StackTrace? stackTrace,
  }) {
    Flushbar(
      message: message,
      icon: Icon(
        isSuccess ? Icons.check_circle : Icons.error,
        color: AppColors.white,
      ),
      duration: const Duration(seconds: 5),
      backgroundColor: isSuccess ? AppColors.success : AppColors.danger,
      margin: const EdgeInsets.all(12),
      borderRadius: BorderRadius.circular(10),
      flushbarPosition: FlushbarPosition.BOTTOM,
      mainButton: error != null
          ? TextButton(
              onPressed: () {
                Navigate.route(
                  context,
                  ErrorScreen(error: error, stackTrace: stackTrace),
                );
              },
              child: Text(
                "Detail",
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: AppColors.white),
              ),
            )
          : null,
    ).show(context);
  }
}
