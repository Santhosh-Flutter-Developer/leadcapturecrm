// import 'dart:convert';
// import 'dart:io';

// import 'package:facesdk_plugin/facedetection_interface.dart';
// import 'package:facesdk_plugin/facesdk_plugin.dart';
// import 'package:flutter/foundation.dart';
// import 'package:flutter/material.dart';
// import 'package:geolocator/geolocator.dart';
// import 'package:intl/intl.dart';
// import 'package:leadcapture/models/src/attendance_model.dart';
// import 'package:leadcapture/models/src/employee_model.dart';
// import 'package:leadcapture/models/src/filter_model.dart';
// import 'package:leadcapture/services/database/src/spdb.dart';
// import 'package:leadcapture/services/firebase/src/attendance_service.dart';
// import 'package:leadcapture/services/firebase/src/employee_service.dart';
// import 'package:leadcapture/services/others/src/location_service.dart';
// import 'package:leadcapture/theme/src/app_colors.dart';
// import 'package:leadcapture/views/ui/src/flush_bar.dart';
// import 'package:leadcapture/views/ui/src/loading.dart';
// import 'package:uuid/uuid.dart';

// class FaceRecognitionAttendance extends StatefulWidget {
//   const FaceRecognitionAttendance({super.key});

//   @override
//   State<FaceRecognitionAttendance> createState() =>
//       _FaceRecognitionAttendanceState();
// }

// class _FaceRecognitionAttendanceState extends State<FaceRecognitionAttendance> {
//   final _facesdkPlugin = FacesdkPlugin();
//   FaceDetectionViewController? faceDetectionViewController;

//   EmployeeModel? employee;
//   Position? currentPosition;
//   bool isInsideGeofence = false;
//   List<PunchModel> todayPunches = [];

//   // Face recognition state
//   dynamic _faces;
//   double _livenessThreshold = 0.7;
//   double _identifyThreshold = 0.8;
//   bool _recognized = false;
//   bool faceRecognized = false;
//   bool locationCheck = false;
//   bool showToast = true;
//   bool callApi = true;

//   String _identifiedName = '';
//   String _identifiedSimilarity = '';
//   String _identifiedLiveness = '';
//   var _identifiedFace;
//   var _enrolledFace;

//   String warningStates = '';
//   bool visibleWarnings = false;

//   final _uuid = const Uuid();

//   @override
//   void initState() {
//     super.initState();
//     init();
//     loadSettings();
//     getEmployee();
//   }

//   @override
//   void dispose() {
//     faceDetectionViewController?.stopCamera();
//     super.dispose();
//   }

//   Future<void> init() async {
//     int facepluginState = -1;
//     String warningState = '';
//     bool visibleWarning = false;

//     try {
//       // Load license from assets or use default
//       if (Platform.isAndroid) {
//         await _facesdkPlugin.setActivation('your-android-license-key').then((
//           value,
//         ) {
//           setState(() => facepluginState = value ?? -1);
//           return facepluginState;
//         });
//       } else {
//         await _facesdkPlugin.setActivation('your-ios-license-key').then((
//           value,
//         ) {
//           setState(() => facepluginState = value ?? -1);
//           return facepluginState;
//         });
//       }

//       if (facepluginState == 0) {
//         await _facesdkPlugin.init().then(
//           (value) => facepluginState = value ?? -1,
//         );
//       }
//     } catch (e) {
//       debugPrint('Init Error: $e');
//     }

//     try {
//       await _facesdkPlugin.setParam({'check_liveness_level': 0});
//     } catch (e) {
//       debugPrint('CHECK_LIVENESS_ERROR: $e');
//     }

//     if (facepluginState == -1) {
//       warningState = 'Invalid license!';
//       visibleWarning = true;
//     } else if (facepluginState == -2) {
//       warningState = 'License expired!';
//       visibleWarning = true;
//     } else if (facepluginState == -3) {
//       warningState = 'Invalid license!';
//       visibleWarning = true;
//     } else if (facepluginState == -4) {
//       warningState = 'No activated!';
//       visibleWarning = true;
//     } else if (facepluginState == -5) {
//       warningState = 'Init error!';
//       visibleWarning = true;
//     }

//     setState(() {
//       warningStates = warningState;
//       visibleWarnings = visibleWarning;
//     });
//   }

//   Future<void> loadSettings() async {
//     setState(() {
//       _livenessThreshold = 0.7;
//       _identifyThreshold = 0.8;
//     });
//   }

//   Future<void> getEmployee() async {
//     final uid = await Spdb.getUid();
//     if (uid != null) {
//       employee = await EmployeeService.getEmployee(uid: uid);
//       await loadTodayPunches();
//     }
//   }

//   Future<void> loadTodayPunches() async {
//     if (employee == null) return;
//     try {
//       final today = DateTime.now();
//       final todayStart = DateTime(today.year, today.month, today.day);
//       final todayEnd = todayStart.add(const Duration(days: 1));

//       final attendance = await AttendanceService.getAttendance(
//         filter: FilterModel(
//           pageNumber: 1,
//           fromDate: todayStart,
//           toDate: todayEnd,
//           pageLimit: 100,
//         ),
//       );

//       setState(() {
//         todayPunches = attendance.punchList;
//       });
//     } catch (e) {
//       debugPrint('Error loading today punches: $e');
//     }
//   }

//   Future<bool> onFaceDetected(faces) async {
//     if (_recognized == true) return false;
//     if (!mounted) return false;

//     setState(() => _faces = faces);

//     bool recognized = false;
//     double maxSimilarity = -1;
//     String maxSimilarityName = '';
//     double maxLiveness = -1;
//     var enrolledFace, identifiedFace;

//     if (faces.length > 0) {
//       if (faces.length > 1) {
//         FlushBar.show(context, 'Multiple Face Detected', isSuccess: false);
//       }

//       var face = faces[0];
//       String storedTemplateString = employee?.faceTemplate ?? '';

//       if (storedTemplateString.isEmpty) {
//         faceDetectionViewController?.stopCamera();
//         Navigator.pop(context);
//         FlushBar.show(
//           context,
//           'Your face is not registered. Please contact admin.',
//           isSuccess: false,
//         );
//         return false;
//       }

//       Uint8List storedTemplate = base64Decode(storedTemplateString);
//       double similarity =
//           await _facesdkPlugin.similarityCalculation(
//             face['templates'],
//             storedTemplate,
//           ) ??
//           -1;

//       if (maxSimilarity < similarity) {
//         maxSimilarity = similarity;
//         maxSimilarityName = employee!.name;
//         maxLiveness = face['liveness'];
//         identifiedFace = face['faceJpg'];
//         enrolledFace = employee!.profileImageUrl;
//       }

//       if (showToast == true) {
//         Future.delayed(const Duration(seconds: 10), () {
//           if (!mounted) return;
//           if (faceRecognized == false) {
//             faceDetectionViewController?.stopCamera();
//             setState(() {
//               faceRecognized = true;
//             });

//             Navigator.pop(context);
//             FlushBar.show(context, 'No Face Matched', isSuccess: false);
//           }
//         });
//       }
//       setState(() => showToast = false);

//       if (maxSimilarity > _identifyThreshold &&
//           maxLiveness > _livenessThreshold) {
//         recognized = true;
//       }
//     }

//     Future.delayed(const Duration(milliseconds: 100), () async {
//       if (!mounted) return false;

//       // Get GPS location
//       try {
//         currentPosition = await LocationService.getCurrentPosition();
//       } catch (e) {
//         debugPrint('Error getting location: $e');
//       }

//       if (!mounted) return false;

//       // Check geofence (simplified - you can integrate with GeofencingHelper)
//       // For now, we'll proceed without strict geofence check
//       isInsideGeofence = true;

//       if (!mounted) return false;
//       setState(() {
//         _recognized = recognized;
//         _identifiedName = maxSimilarityName;
//         _identifiedSimilarity = maxSimilarity.toString();
//         _identifiedLiveness = maxLiveness.toString();
//         _enrolledFace = enrolledFace;
//         _identifiedFace = identifiedFace;
//       });

//       if (recognized) {
//         faceDetectionViewController?.stopCamera();
//         if (!mounted) return false;
//         setState(() {
//           _faces = null;
//           faceRecognized = true;
//         });

//         if (callApi == true) {
//           setState(() => callApi = false);
//           await loadTodayPunches();
//           if (!mounted) return false;
//           await _showPunchSelectorSheet();
//         }
//       }
//     });

//     return recognized;
//   }

//   Future<void> _showPunchSelectorSheet() async {
//     final inPunches = todayPunches
//         .where((p) => p.clockIn != null && p.clockOut == null)
//         .toList();
//     final outPunches = todayPunches.where((p) => p.clockOut != null).toList();

//     // Determine which punch type is valid next
//     final bool mustBeOut = inPunches.length > outPunches.length;
//     final bool mustBeIn = inPunches.length == outPunches.length;

//     String selectedType = mustBeOut ? 'out' : 'in';

//     await showModalBottomSheet(
//       context: context,
//       isScrollControlled: true,
//       backgroundColor: Colors.transparent,
//       isDismissible: false,
//       enableDrag: false,
//       builder: (ctx) => _PunchSelectorSheet(
//         employeeName: employee!.name,
//         todayPunches: todayPunches,
//         inPunches: inPunches,
//         outPunches: outPunches,
//         mustBeOut: mustBeOut,
//         mustBeIn: mustBeIn,
//         preSelectedType: selectedType,
//         currentPosition: currentPosition,
//         isWithinGeofence: isInsideGeofence,
//         onConfirm: (type) async {
//           Navigator.of(ctx).pop();
//           await _savePunch(type);
//         },
//         onCancel: () {
//           Navigator.of(ctx).pop();
//           setState(() {
//             _recognized = false;
//             faceRecognized = false;
//             locationCheck = false;
//             callApi = true;
//             showToast = true;
//           });
//           Navigator.pop(context);
//         },
//       ),
//     );
//   }

//   Future<void> _savePunch(String punchType) async {
//     try {
//       futureLoading(context);

//       if (punchType == 'in') {
//         await AttendanceService.createPunch(
//           userUid: employee!.uid!,
//           workingMinutes: 0,
//           otMinutes: 0,
//           lessMinutes: 0,
//           status: 'present',
//         );
//       } else {
//         // Clock out - find the latest punch without clockOut
//         final latestPunch = todayPunches.where((p) => p.clockOut == null).first;
//         if (latestPunch.uid != null) {
//           await AttendanceService.clockOut(latestPunch.uid!);
//         }
//       }

//       Navigator.pop(context);
//       Navigator.pop(context);

//       final label = punchType == 'in' ? 'Punch IN' : 'Punch OUT';
//       FlushBar.show(context, '$label recorded successfully', isSuccess: true);
//     } catch (e) {
//       Navigator.pop(context);
//       FlushBar.show(context, 'Failed to record punch: $e', isSuccess: false);
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return WillPopScope(
//       onWillPop: () async {
//         faceDetectionViewController?.stopCamera();
//         return true;
//       },
//       child: SafeArea(
//         top: false,
//         child: Scaffold(
//           backgroundColor: Colors.black,
//           appBar: AppBar(
//             backgroundColor: Colors.black,
//             foregroundColor: Colors.white,
//             title: const Text(
//               'Face Recognition',
//               style: TextStyle(color: Colors.white),
//             ),
//             toolbarHeight: 70,
//             centerTitle: false,
//           ),
//           body: Stack(
//             children: <Widget>[
//               FaceDetectionView(faceRecognitionViewState: this),
//               if (visibleWarnings)
//                 Container(
//                   color: Colors.black.withOpacity(0.8),
//                   child: Center(
//                     child: Column(
//                       mainAxisAlignment: MainAxisAlignment.center,
//                       children: [
//                         const Icon(Icons.warning, color: Colors.red, size: 60),
//                         const SizedBox(height: 16),
//                         Text(
//                           warningStates,
//                           style: const TextStyle(
//                             color: Colors.white,
//                             fontSize: 18,
//                             fontWeight: FontWeight.bold,
//                           ),
//                         ),
//                         const SizedBox(height: 24),
//                         ElevatedButton(
//                           onPressed: () => Navigator.pop(context),
//                           style: ElevatedButton.styleFrom(
//                             backgroundColor: AppColors.primaryColor,
//                           ),
//                           child: const Text('Go Back'),
//                         ),
//                       ],
//                     ),
//                   ),
//                 ),
//               // Success overlay after recognition
//               if (_recognized)
//                 Container(
//                   width: double.infinity,
//                   height: double.infinity,
//                   color: Theme.of(context).colorScheme.surface,
//                   child: Column(
//                     mainAxisAlignment: MainAxisAlignment.start,
//                     children: [
//                       const SizedBox(height: 80),
//                       const Icon(
//                         Icons.check_circle,
//                         color: Colors.green,
//                         size: 60,
//                       ),
//                       const SizedBox(height: 8),
//                       Text(
//                         _identifiedName,
//                         style: const TextStyle(
//                           fontSize: 20,
//                           fontWeight: FontWeight.w700,
//                         ),
//                       ),
//                       const SizedBox(height: 6),
//                       const Row(
//                         mainAxisAlignment: MainAxisAlignment.center,
//                         children: [
//                           Icon(
//                             Icons.check_circle,
//                             color: Colors.green,
//                             size: 18,
//                           ),
//                           SizedBox(width: 6),
//                           Text(
//                             'Identity Verified',
//                             style: TextStyle(color: Colors.green, fontSize: 14),
//                           ),
//                         ],
//                       ),
//                       const SizedBox(height: 20),
//                       CircularProgressIndicator(color: AppColors.primaryColor),
//                       const SizedBox(height: 12),
//                       const Text(
//                         'Preparing punch options...',
//                         style: TextStyle(fontSize: 13),
//                       ),
//                     ],
//                   ),
//                 ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }

// // Face Detection View
// class FaceDetectionView extends StatefulWidget
//     implements FaceDetectionInterface {
//   _FaceRecognitionAttendanceState faceRecognitionViewState;

//   FaceDetectionView({super.key, required this.faceRecognitionViewState});

//   @override
//   Future<void> onFaceDetected(faces) async {
//     await faceRecognitionViewState.onFaceDetected(faces);
//   }

//   @override
//   State<StatefulWidget> createState() => _FaceDetectionViewState();
// }

// class _FaceDetectionViewState extends State<FaceDetectionView> {
//   @override
//   Widget build(BuildContext context) {
//     if (defaultTargetPlatform == TargetPlatform.android) {
//       return AndroidView(
//         viewType: 'facedetectionview',
//         onPlatformViewCreated: _onPlatformViewCreated,
//       );
//     } else {
//       return UiKitView(
//         viewType: 'facedetectionview',
//         onPlatformViewCreated: _onPlatformViewCreated,
//       );
//     }
//   }

//   void _onPlatformViewCreated(int id) async {
//     var cameraLens = 1;

//     widget.faceRecognitionViewState.faceDetectionViewController =
//         FaceDetectionViewController(id, widget);

//     await widget.faceRecognitionViewState.faceDetectionViewController
//         ?.initHandler();

//     int? livenessLevel = 0;
//     await widget.faceRecognitionViewState._facesdkPlugin.setParam({
//       'check_liveness_level': livenessLevel,
//       'check_eye_closeness': true,
//       'check_face_occlusion': true,
//       'check_mouth_opened': true,
//       'estimate_age_gender': true,
//     });

//     await widget.faceRecognitionViewState.faceDetectionViewController
//         ?.startCamera(cameraLens);
//   }
// }

// // Punch Selector Bottom Sheet
// class _PunchSelectorSheet extends StatefulWidget {
//   final String employeeName;
//   final List<PunchModel> todayPunches;
//   final List<PunchModel> inPunches;
//   final List<PunchModel> outPunches;
//   final bool mustBeOut;
//   final bool mustBeIn;
//   final String preSelectedType;
//   final Position? currentPosition;
//   final bool isWithinGeofence;
//   final Future<void> Function(String type) onConfirm;
//   final VoidCallback onCancel;

//   const _PunchSelectorSheet({
//     required this.employeeName,
//     required this.todayPunches,
//     required this.inPunches,
//     required this.outPunches,
//     required this.mustBeOut,
//     required this.mustBeIn,
//     required this.preSelectedType,
//     required this.currentPosition,
//     required this.isWithinGeofence,
//     required this.onConfirm,
//     required this.onCancel,
//   });

//   @override
//   State<_PunchSelectorSheet> createState() => _PunchSelectorSheetState();
// }

// class _PunchSelectorSheetState extends State<_PunchSelectorSheet> {
//   late String selectedType;
//   bool loading = false;
//   String? validationError;

//   @override
//   void initState() {
//     super.initState();
//     selectedType = widget.preSelectedType;
//     _validate(selectedType);
//   }

//   void _validate(String type) {
//     String? err;
//     if (type == 'out' && widget.inPunches.length <= widget.outPunches.length) {
//       err = 'You must Punch IN before punching OUT.';
//     } else if (type == 'in' &&
//         widget.inPunches.length > widget.outPunches.length) {
//       err = 'You must Punch OUT before punching IN again.';
//     }
//     setState(() => validationError = err);
//   }

//   void _select(String type) {
//     setState(() => selectedType = type);
//     _validate(type);
//   }

//   String _fmt(DateTime dt) =>
//       '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

//   String _totalHours() {
//     int totalMins = 0;
//     final pairs = widget.inPunches.length < widget.outPunches.length
//         ? widget.inPunches.length
//         : widget.outPunches.length;
//     for (int i = 0; i < pairs; i++) {
//       if (widget.inPunches[i].clockIn != null &&
//           widget.outPunches[i].clockOut != null) {
//         final diff = widget.outPunches[i].clockOutDate!
//             .difference(widget.inPunches[i].clockInDate!)
//             .inMinutes;
//         if (diff > 0) totalMins += diff;
//       }
//     }
//     if (totalMins == 0) return '0h 0m';
//     return '${totalMins ~/ 60}h ${totalMins % 60}m';
//   }

//   @override
//   Widget build(BuildContext context) {
//     final now = DateTime.now();
//     final nowStr =
//         '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

//     return Container(
//       decoration: BoxDecoration(
//         color: AppColors.primaryColor.withOpacity(0.1),
//         borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
//       ),
//       padding: EdgeInsets.only(
//         bottom: MediaQuery.of(context).viewInsets.bottom + 20,
//       ),
//       child: SingleChildScrollView(
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             const SizedBox(height: 10),
//             Container(
//               width: 44,
//               height: 4,
//               decoration: BoxDecoration(
//                 color: Colors.grey,
//                 borderRadius: BorderRadius.circular(2),
//               ),
//             ),
//             const SizedBox(height: 20),

//             // Header
//             Padding(
//               padding: const EdgeInsets.symmetric(horizontal: 20),
//               child: Row(
//                 children: [
//                   Container(
//                     width: 48,
//                     height: 48,
//                     decoration: BoxDecoration(
//                       color: AppColors.primaryColor.withOpacity(0.1),
//                       borderRadius: BorderRadius.circular(14),
//                     ),
//                     child: Icon(
//                       Icons.fingerprint_rounded,
//                       color: AppColors.primaryColor,
//                       size: 26,
//                     ),
//                   ),
//                   const SizedBox(width: 14),
//                   Expanded(
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         const Text(
//                           'Mark Attendance',
//                           style: TextStyle(
//                             fontSize: 17,
//                             fontWeight: FontWeight.w800,
//                           ),
//                         ),
//                         Text(
//                           widget.employeeName,
//                           style: const TextStyle(
//                             fontSize: 13,
//                             color: Colors.grey,
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                   // Current time chip
//                   Container(
//                     padding: const EdgeInsets.symmetric(
//                       horizontal: 12,
//                       vertical: 6,
//                     ),
//                     decoration: BoxDecoration(
//                       color: AppColors.primaryColor.withOpacity(0.08),
//                       borderRadius: BorderRadius.circular(20),
//                       border: Border.all(
//                         color: AppColors.primaryColor.withOpacity(0.2),
//                       ),
//                     ),
//                     child: Row(
//                       children: [
//                         Icon(
//                           Icons.access_time_rounded,
//                           size: 14,
//                           color: AppColors.primaryColor,
//                         ),
//                         const SizedBox(width: 4),
//                         Text(
//                           nowStr,
//                           style: TextStyle(
//                             fontSize: 13,
//                             fontWeight: FontWeight.w700,
//                             color: AppColors.primaryColor,
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                 ],
//               ),
//             ),

//             const SizedBox(height: 20),
//             const Divider(height: 1, color: Colors.grey),
//             const SizedBox(height: 20),

//             // Today's Punch History
//             Padding(
//               padding: const EdgeInsets.symmetric(horizontal: 20),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Row(
//                     children: [
//                       Icon(Icons.history_rounded, size: 16, color: Colors.grey),
//                       SizedBox(width: 6),
//                       Text(
//                         "Today's Punch History",
//                         style: TextStyle(
//                           fontSize: 13,
//                           fontWeight: FontWeight.w700,
//                           color: Colors.grey,
//                         ),
//                       ),
//                       Spacer(),
//                       if (widget.todayPunches.isNotEmpty)
//                         Container(
//                           padding: EdgeInsets.symmetric(
//                             horizontal: 10,
//                             vertical: 3,
//                           ),
//                           decoration: BoxDecoration(
//                             color: Colors.green.withOpacity(0.1),
//                             borderRadius: BorderRadius.circular(12),
//                           ),
//                           child: Text(
//                             'Total: ${_totalHours()}',
//                             style: TextStyle(
//                               fontSize: 12,
//                               fontWeight: FontWeight.w600,
//                               color: Colors.green,
//                             ),
//                           ),
//                         ),
//                     ],
//                   ),
//                   const SizedBox(height: 12),
//                   if (widget.todayPunches.isEmpty)
//                     const Text(
//                       'No punches recorded today',
//                       style: TextStyle(fontSize: 13, color: Colors.grey),
//                     )
//                   else
//                     ...widget.todayPunches.map((punch) {
//                       final clockInTime = punch.clockInDate != null
//                           ? _fmt(punch.clockInDate!)
//                           : '-';
//                       final clockOutTime = punch.clockOutDate != null
//                           ? _fmt(punch.clockOutDate!)
//                           : '-';
//                       return Padding(
//                         padding: const EdgeInsets.only(bottom: 8),
//                         child: Row(
//                           children: [
//                             Container(
//                               width: 8,
//                               height: 8,
//                               decoration: BoxDecoration(
//                                 color: punch.clockOut != null
//                                     ? Colors.green
//                                     : Colors.orange,
//                                 shape: BoxShape.circle,
//                               ),
//                             ),
//                             const SizedBox(width: 12),
//                             Text(
//                               clockInTime,
//                               style: const TextStyle(fontSize: 13),
//                             ),
//                             const Text(' - ', style: TextStyle(fontSize: 13)),
//                             Text(
//                               clockOutTime,
//                               style: const TextStyle(fontSize: 13),
//                             ),
//                           ],
//                         ),
//                       );
//                     }),
//                 ],
//               ),
//             ),

//             const SizedBox(height: 20),
//             const Divider(height: 1, color: Colors.grey),
//             const SizedBox(height: 20),

//             // Punch Type Selection
//             Padding(
//               padding: const EdgeInsets.symmetric(horizontal: 20),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   const Text(
//                     'Select Punch Type',
//                     style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
//                   ),
//                   const SizedBox(height: 12),
//                   Row(
//                     children: [
//                       Expanded(
//                         child: GestureDetector(
//                           onTap: () => _select('in'),
//                           child: Container(
//                             padding: const EdgeInsets.symmetric(vertical: 16),
//                             decoration: BoxDecoration(
//                               color: selectedType == 'in'
//                                   ? AppColors.primaryColor
//                                   : Colors.grey.withOpacity(0.1),
//                               borderRadius: BorderRadius.circular(12),
//                               border: Border.all(
//                                 color: selectedType == 'in'
//                                     ? AppColors.primaryColor
//                                     : Colors.grey.withOpacity(0.3),
//                               ),
//                             ),
//                             child: Column(
//                               children: [
//                                 Icon(
//                                   Icons.login_rounded,
//                                   color: selectedType == 'in'
//                                       ? Colors.white
//                                       : Colors.grey,
//                                   size: 24,
//                                 ),
//                                 const SizedBox(height: 4),
//                                 Text(
//                                   'Punch IN',
//                                   style: TextStyle(
//                                     color: selectedType == 'in'
//                                         ? Colors.white
//                                         : Colors.grey,
//                                     fontWeight: FontWeight.w600,
//                                   ),
//                                 ),
//                               ],
//                             ),
//                           ),
//                         ),
//                       ),
//                       const SizedBox(width: 12),
//                       Expanded(
//                         child: GestureDetector(
//                           onTap: () => _select('out'),
//                           child: Container(
//                             padding: const EdgeInsets.symmetric(vertical: 16),
//                             decoration: BoxDecoration(
//                               color: selectedType == 'out'
//                                   ? AppColors.primaryColor
//                                   : Colors.grey.withOpacity(0.1),
//                               borderRadius: BorderRadius.circular(12),
//                               border: Border.all(
//                                 color: selectedType == 'out'
//                                     ? AppColors.primaryColor
//                                     : Colors.grey.withOpacity(0.3),
//                               ),
//                             ),
//                             child: Column(
//                               children: [
//                                 Icon(
//                                   Icons.logout_rounded,
//                                   color: selectedType == 'out'
//                                       ? Colors.white
//                                       : Colors.grey,
//                                   size: 24,
//                                 ),
//                                 const SizedBox(height: 4),
//                                 Text(
//                                   'Punch OUT',
//                                   style: TextStyle(
//                                     color: selectedType == 'out'
//                                         ? Colors.white
//                                         : Colors.grey,
//                                     fontWeight: FontWeight.w600,
//                                   ),
//                                 ),
//                               ],
//                             ),
//                           ),
//                         ),
//                       ),
//                     ],
//                   ),
//                   if (validationError != null)
//                     Padding(
//                       padding: const EdgeInsets.only(top: 8),
//                       child: Text(
//                         validationError!,
//                         style: const TextStyle(fontSize: 12, color: Colors.red),
//                       ),
//                     ),
//                 ],
//               ),
//             ),

//             const SizedBox(height: 24),

//             // Action Buttons
//             Padding(
//               padding: const EdgeInsets.symmetric(horizontal: 20),
//               child: Row(
//                 children: [
//                   Expanded(
//                     child: OutlinedButton(
//                       onPressed: widget.onCancel,
//                       style: OutlinedButton.styleFrom(
//                         padding: const EdgeInsets.symmetric(vertical: 16),
//                         side: BorderSide(color: Colors.grey.withOpacity(0.3)),
//                       ),
//                       child: const Text('Cancel'),
//                     ),
//                   ),
//                   const SizedBox(width: 12),
//                   Expanded(
//                     child: ElevatedButton(
//                       onPressed: validationError == null
//                           ? () => widget.onConfirm(selectedType)
//                           : null,
//                       style: ElevatedButton.styleFrom(
//                         padding: const EdgeInsets.symmetric(vertical: 16),
//                         backgroundColor: AppColors.primaryColor,
//                       ),
//                       child: const Text('Confirm'),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
