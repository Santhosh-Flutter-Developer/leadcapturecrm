/*
  Copyright 2024 Srisoftwarez. All rights reserved.
  Use of this source code is governed by a BSD-style license that can be
  found in the LICENSE file.
*/

// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:iconsax/iconsax.dart';

// Project imports:
import '/theme/theme.dart';

class SubmitButton extends StatelessWidget {
  final void Function() event;
  final String? text;
  const SubmitButton({super.key, required this.event, this.text});

  @override
  Widget build(BuildContext context) {
    return BottomAppBar(
      height: 70,
      color: Colors.white,
      surfaceTintColor: Colors.white,
      child: ElevatedButton(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.all(AppColors.primary),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          minimumSize: WidgetStateProperty.all(const Size(80, 30)),
          padding: WidgetStateProperty.all(EdgeInsets.zero),
          shape: WidgetStateProperty.all(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Iconsax.tick_circle, color: AppColors.white),
            const SizedBox(width: 10),
            Text(
              text ?? "Submit",
              style: TextStyle(color: AppColors.white),
            ),
          ],
        ),
        onPressed: () {
          event();
        },
      ),
    );
  }
}
