// import 'package:flutter/material.dart';
// import 'package:leadcapture/models/src/attendance_model.dart';
// import '/models/models.dart';
// import '/services/services.dart';
// import '/views/ui/src/flush_bar.dart';

// /// Helper class for integrating geofencing into attendance flow
// class GeofencingHelper {
//   /// Validate geofencing before punch operation
//   /// Returns GeofencingResult with validation status
//   static Future<GeofencingResult> validateBeforePunch(
//     CompanyModel company,
//     BuildContext context,
//   ) async {
//     // Check if company has geofencing configured
//     if (company.latitude == null ||
//         company.longitude == null ||
//         company.radius == 0) {
//       // Geofencing not configured, allow punch
//       return GeofencingResult(
//         isWithinGeofence: true,
//         distanceInMeters: 0,
//         distanceInKm: 0,
//         message: 'Geofencing not configured for this company',
//       );
//     }

//     // Request location permission
//     final permissionResult =
//         await LocationService.requestPermissionWithStatus();
//     if (!permissionResult.canProceed) {
//       // Show permission dialog
//       if (context.mounted) {
//         _showPermissionDialog(context, permissionResult);
//       }
//       return GeofencingResult(
//         isWithinGeofence: false,
//         distanceInMeters: -1,
//         distanceInKm: -1,
//         message: permissionResult.message,
//       );
//     }

//     // Validate geofence
//     final geofenceResult = await LocationService.validateGeofence(company);

//     // Show result to user
//     if (context.mounted) {
//       _showGeofenceResult(context, geofenceResult);
//     }

//     return geofenceResult;
//   }

//   /// Add location data to punch model
//   static Future<PunchModel> addLocationToPunch(
//     PunchModel punch,
//     GeofencingResult geofenceResult,
//   ) async {
//     return punch.copyWith(
//       latitude: geofenceResult.currentPosition?.latitude,
//       longitude: geofenceResult.currentPosition?.longitude,
//       isWithinGeofence: geofenceResult.isWithinGeofence,
//     );
//   }

//   /// Show permission dialog to user
//   static void _showPermissionDialog(
//     BuildContext context,
//     LocationPermissionResult result,
//   ) {
//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: Row(
//           children: [
//             Icon(
//               result.needsSettings ? Icons.settings : Icons.location_off,
//               color: Theme.of(context).colorScheme.error,
//             ),
//             const SizedBox(width: 8),
//             const Text('Location Permission Required'),
//           ],
//         ),
//         content: Text(result.message),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context),
//             child: const Text('Cancel'),
//           ),
//           if (result.needsSettings)
//             ElevatedButton(
//               onPressed: () async {
//                 Navigator.pop(context);
//                 await LocationService.openAppSettings();
//               },
//               child: const Text('Open Settings'),
//             )
//           else if (result.status == LocationPermissionStatus.serviceDisabled)
//             ElevatedButton(
//               onPressed: () async {
//                 Navigator.pop(context);
//                 await LocationService.openLocationSettings();
//               },
//               child: const Text('Enable Location'),
//             )
//           else
//             ElevatedButton(
//               onPressed: () async {
//                 Navigator.pop(context);
//                 final newResult =
//                     await LocationService.requestPermissionWithStatus();
//                 if (newResult.canProceed && context.mounted) {
//                   FlushBar.show(context, 'Location permission granted');
//                 }
//               },
//               child: const Text('Request Permission'),
//             ),
//         ],
//       ),
//     );
//   }

//   /// Show geofence validation result to user
//   static void _showGeofenceResult(
//     BuildContext context,
//     GeofencingResult result,
//   ) {
//     final icon = result.isWithinGeofence
//         ? Icons.check_circle
//         : Icons.location_off;
//     final color = result.isWithinGeofence ? Colors.green : Colors.orange;

//     FlushBar.show(
//       context,
//       result.message,
//       isSuccess: result.isWithinGeofence,
//       icon: icon,
//       backgroundColor: color.withOpacity(0.1),
//       textColor: color,
//     );
//   }

//   /// Show outside office warning with admin override option
//   static Future<bool> showOutsideOfficeWarning(
//     BuildContext context,
//     GeofencingResult result,
//     bool isAdmin,
//   ) async {
//     if (result.isWithinGeofence) return true;

//     if (!isAdmin) {
//       // Regular employee - show warning but allow with confirmation
//       return await showDialog<bool>(
//             context: context,
//             builder: (context) => AlertDialog(
//               title: const Row(
//                 children: [
//                   Icon(Icons.warning, color: Colors.orange),
//                   SizedBox(width: 8),
//                   Text('Outside Office Premises'),
//                 ],
//               ),
//               content: Column(
//                 mainAxisSize: MainAxisSize.min,
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text(result.message),
//                   const SizedBox(height: 12),
//                   Text(
//                     'Note: This punch may be flagged for review.',
//                     style: TextStyle(
//                       fontSize: 12,
//                       color: Theme.of(context).colorScheme.onSurfaceVariant,
//                     ),
//                   ),
//                 ],
//               ),
//               actions: [
//                 TextButton(
//                   onPressed: () => Navigator.pop(context, false),
//                   child: const Text('Cancel'),
//                 ),
//                 ElevatedButton(
//                   onPressed: () => Navigator.pop(context, true),
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: Colors.orange,
//                     foregroundColor: Colors.white,
//                   ),
//                   child: const Text('Proceed Anyway'),
//                 ),
//               ],
//             ),
//           ) ??
//           false;
//     } else {
//       // Admin - can override geofencing
//       return await showDialog<bool>(
//             context: context,
//             builder: (context) => AlertDialog(
//               title: const Row(
//                 children: [
//                   Icon(Icons.admin_panel_settings, color: Colors.blue),
//                   SizedBox(width: 8),
//                   Text('Admin Override'),
//                 ],
//               ),
//               content: Column(
//                 mainAxisSize: MainAxisSize.min,
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text(result.message),
//                   const SizedBox(height: 12),
//                   Text(
//                     'As an admin, you can override geofencing restrictions.',
//                     style: TextStyle(
//                       fontSize: 12,
//                       color: Theme.of(context).colorScheme.onSurfaceVariant,
//                     ),
//                   ),
//                 ],
//               ),
//               actions: [
//                 TextButton(
//                   onPressed: () => Navigator.pop(context, false),
//                   child: const Text('Cancel'),
//                 ),
//                 ElevatedButton(
//                   onPressed: () => Navigator.pop(context, true),
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: Colors.blue,
//                     foregroundColor: Colors.white,
//                   ),
//                   child: const Text('Override & Proceed'),
//                 ),
//               ],
//             ),
//           ) ??
//           false;
//     }
//   }

//   /// Get location status widget for display
//   static Widget buildLocationStatusWidget(GeofencingResult result) {
//     final icon = result.isWithinGeofence
//         ? Icons.check_circle
//         : Icons.location_off;
//     final color = result.isWithinGeofence ? Colors.green : Colors.orange;
//     final label = result.isWithinGeofence ? 'Within Office' : 'Outside Office';

//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
//       decoration: BoxDecoration(
//         color: color.withOpacity(0.1),
//         borderRadius: BorderRadius.circular(8),
//         border: Border.all(color: color.withOpacity(0.3)),
//       ),
//       child: Row(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           Icon(icon, size: 16, color: color),
//           const SizedBox(width: 6),
//           Text(
//             label,
//             style: TextStyle(
//               color: color,
//               fontWeight: FontWeight.w500,
//               fontSize: 12,
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   /// Get distance display widget
//   static Widget buildDistanceWidget(double distanceInMeters) {
//     final distanceText = LocationService.formatDistance(distanceInMeters);

//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
//       decoration: BoxDecoration(
//         color: Colors.blue.withOpacity(0.1),
//         borderRadius: BorderRadius.circular(8),
//         border: Border.all(color: Colors.blue.withOpacity(0.3)),
//       ),
//       child: Row(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           const Icon(Icons.straighten, size: 16, color: Colors.blue),
//           const SizedBox(width: 6),
//           Text(
//             distanceText,
//             style: const TextStyle(
//               color: Colors.blue,
//               fontWeight: FontWeight.w500,
//               fontSize: 12,
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
