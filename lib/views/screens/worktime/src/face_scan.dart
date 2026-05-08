/*
  Copyright 2024 Srisoftwarez. All rights reserved.
  Use of this source code is governed by a BSD-style license that can be
  found in the LICENSE file.
*/

// Dart imports:
import 'dart:io';

// Flutter imports:
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// Package imports:
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_face_api/flutter_face_api.dart';
import 'package:http/http.dart' as http;
import 'package:leadcapture/services/database/src/spdb.dart';
import 'package:leadcapture/services/firebase/src/employee_service.dart';
import 'package:leadcapture/views/ui/src/back.dart';
import 'package:leadcapture/views/ui/src/button.dart';
import 'package:leadcapture/views/ui/src/error_display.dart';
import 'package:leadcapture/views/ui/src/loading.dart';
import 'package:leadcapture/views/ui/src/snackbar.dart';
// Project imports:
import '/constants/constants.dart';
import '/theme/theme.dart';
import '/utils/utils.dart';

class FaceScan extends StatefulWidget {
  const FaceScan({super.key});

  @override
  State<FaceScan> createState() => _FaceScanState();
}

class _FaceScanState extends State<FaceScan> {
  late Future _initial;
  String? _staffImage;
  File? _capturedFile;
  final _faceSdk = FaceSDK.instance;

  @override
  void initState() {
    _initial = _init();
    super.initState();
  }

  _init() async {
    String? uid = await Spdb.getUid();
    if (uid == null) return;

    final employee = await EmployeeService.getEmployee(uid: uid);

    _staffImage = employee?.profileImageUrl;

    if (!await initialize()) return;
  }

  Future<bool> initialize() async {
    var license = await loadAssetIfExists("assets/regula.license");
    InitConfig? config;
    if (license != null) config = InitConfig(license);
    var (success, error) = await _faceSdk.initialize(config: config);
    return success;
  }

  Future<ByteData?> loadAssetIfExists(String path) async {
    try {
      return await rootBundle.load(path);
    } catch (_) {
      return null;
    }
  }

  MatchFacesImage setImage(Uint8List bytes, ImageType type) {
    var mfImage = MatchFacesImage(bytes, type);
    return mfImage;
  }

  Future<double> matchFaces(MatchFacesImage img1, MatchFacesImage img2) async {
    var request = MatchFacesRequest([img1, img2]);
    var response = await _faceSdk.matchFaces(request);
    var split = await _faceSdk.splitComparedFaces(response.results, 0.75);
    var match = split.matchedFaces;
    var similarityStatus = 0.0;
    if (match.isNotEmpty) {
      similarityStatus = match[0].similarity * 100;
    }
    return similarityStatus;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Face Scan"), leading: const Back()),
      body: FutureBuilder(
        future: _initial,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const WaitingLoading();
          } else if (snapshot.hasError) {
            return ErrorDisplay(error: snapshot.error.toString());
          } else {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      "Staff Image",
                      style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                        color: AppColors.primaryColor,
                      ),
                    ),
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: _staffImage != null
                          ? CachedNetworkImage(
                              imageUrl: _staffImage!,
                              height: 200,
                              width: 200,
                              fit: BoxFit.cover,
                              placeholder: (context, url) =>
                                  const Center(child: WaitingLoading()),
                              errorWidget: (context, url, error) =>
                                  const Icon(Icons.error),
                            )
                          : CachedNetworkImage(
                              imageUrl: AppStrings.emptyProfilePhotoUrl,
                              height: 200,
                              width: 200,
                              fit: BoxFit.cover,
                              placeholder: (context, url) =>
                                  const Center(child: WaitingLoading()),
                              errorWidget: (context, url, error) =>
                                  const Icon(Icons.error),
                            ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      "Capture Image",
                      style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                        color: AppColors.primaryColor,
                      ),
                    ),
                    const SizedBox(height: 10),
                    GestureDetector(
                      onTap: () async {
                        var file = await PickImage.captureImage();
                        if (file != null) {
                          _capturedFile = file;
                          setState(() {});
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        height: 200,
                        width: 200,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(15),
                          color: AppColors.secondaryColor,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.2),
                              spreadRadius: 5,
                              blurRadius: 7,
                            ),
                          ],
                        ),
                        child: _capturedFile != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: Image.file(
                                  _capturedFile!,
                                  fit: BoxFit.cover,
                                ),
                              )
                            : Image.asset(
                                ImageAssets.upload,
                                fit: BoxFit.contain,
                              ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Button(
                      event: () async {
                        if (_staffImage == null) {
                          return Snackbar.showSnackBar(
                            context,
                            content: "Staff image not uploaded by user/admin",
                            isSuccess: false,
                          );
                        }

                        if (_staffImage != null && _capturedFile != null) {
                          futureLoading(context);
                          var img1 = await http.get(Uri.parse(_staffImage!));
                          var img1Bytes = img1.bodyBytes;

                          var mfImage1 = setImage(img1Bytes, ImageType.PRINTED);
                          var mfImage2 = setImage(
                            _capturedFile!.readAsBytesSync(),
                            ImageType.PRINTED,
                          );

                          var result = await matchFaces(mfImage1, mfImage2);
                          Navigator.pop(context);

                          if (result > 80) {
                            Snackbar.showSnackBar(
                              context,
                              content:
                                  "Face matched. Similarity - ${result.toStringAsFixed(2)} %",
                              isSuccess: true,
                            );
                            Future.delayed(const Duration(seconds: 2), () {
                              Navigator.pop(context, true);
                            });
                          } else {
                            Snackbar.showSnackBar(
                              context,
                              content:
                                  "Face not matched. Similarity - ${result.toStringAsFixed(2)} %",
                              isSuccess: false,
                            );
                          }
                        }
                      },
                      text: "Match Image",
                    ),
                  ],
                ),
              ),
            );
          }
        },
      ),
    );
  }
}
