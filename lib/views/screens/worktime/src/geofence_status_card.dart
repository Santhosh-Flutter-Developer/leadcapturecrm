// /*
//   GeofenceStatusCard
//   ─────────────────────────────────────────────────────────────────────────────
//   A live-updating card that displays the employee's real-time geofence status.

//   • Shows a pulsing animated dot — Green (inside), Orange (outside), Red (off)
//   • Displays distance from office center
//   • Shows GPS horizontal accuracy for transparency
//   • Exposes [isInsideGeofence] to parent via [onStatusChanged] callback
//   ─────────────────────────────────────────────────────────────────────────────
// */

// import 'dart:async';

// import 'package:flutter/material.dart';
// import 'package:iconsax/iconsax.dart';
// import 'package:leadcapture/services/firebase/src/company_location_service.dart';
// import 'package:leadcapture/services/others/src/location_service.dart';
// import 'package:geolocator/geolocator.dart';

// import '/theme/theme.dart';

// enum _GeofenceStatus { loading, inside, outside, locationOff, notConfigured }

// class GeofenceStatusCard extends StatefulWidget {
//   /// Called whenever the geofence status re-resolves.
//   /// [isInside] is true when the user is within the allowed radius.
//   /// [distanceMeters] and [radiusMeters] are the computed values (may be null).
//   final void Function(
//     bool isInside, {
//     double? distanceMeters,
//     double? radiusMeters,
//   })? onStatusChanged;

//   final bool outsideOfficeAllowed;

//   const GeofenceStatusCard({
//     super.key,
//     this.onStatusChanged,
//     this.outsideOfficeAllowed = false,
//   });

//   @override
//   State<GeofenceStatusCard> createState() => GeofenceStatusCardState();
// }

// class GeofenceStatusCardState extends State<GeofenceStatusCard>
//     with SingleTickerProviderStateMixin {
//   _GeofenceStatus _status = _GeofenceStatus.loading;
//   double? _distanceMeters;
//   double? _accuracyMeters;
//   double? _radiusMeters;
//   bool _refreshing = false;

//   // Pulsing animation
//   late AnimationController _pulseController;
//   late Animation<double> _pulseAnim;

//   @override
//   void initState() {
//     super.initState();
//     _pulseController = AnimationController(
//       vsync: this,
//       duration: const Duration(milliseconds: 1200),
//     )..repeat(reverse: true);
//     _pulseAnim = Tween<double>(begin: 0.5, end: 1.0).animate(
//       CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
//     );
//     _refresh();
//   }

//   @override
//   void dispose() {
//     _pulseController.dispose();
//     super.dispose();
//   }

//   /// Public method so parent can trigger a refresh after location settings change.
//   Future<void> refresh() => _refresh();

//   Future<void> _refresh() async {
//     if (_refreshing) return;
//     setState(() {
//       _refreshing = true;
//       _status = _GeofenceStatus.loading;
//     });

//     try {
//       // 1. Load geofence config
//       final geofence = await CompanyLocationService.getGeofence();
//       if (geofence == null) {
//         _resolve(_GeofenceStatus.notConfigured, null, null, null);
//         return;
//       }

//       // 2. Get current GPS position
//       final Position? position = await LocationService.getCurrentPosition();
//       if (position == null) {
//         _resolve(_GeofenceStatus.locationOff, null, null, geofence.radiusMeters);
//         return;
//       }

//       // 3. Compute distance
//       final distance = LocationService.distanceBetween(
//         position.latitude,
//         position.longitude,
//         geofence.latitude,
//         geofence.longitude,
//       );

//       final inside = distance <= geofence.radiusMeters;
//       _resolve(
//         inside ? _GeofenceStatus.inside : _GeofenceStatus.outside,
//         distance,
//         position.accuracy,
//         geofence.radiusMeters,
//       );
//     } catch (_) {
//       _resolve(_GeofenceStatus.locationOff, null, null, null);
//     }
//   }

//   void _resolve(
//     _GeofenceStatus status,
//     double? distance,
//     double? accuracy,
//     double? radius,
//   ) {
//     if (!mounted) return;
//     setState(() {
//       _status = status;
//       _distanceMeters = distance;
//       _accuracyMeters = accuracy;
//       _radiusMeters = radius;
//       _refreshing = false;
//     });
//     widget.onStatusChanged?.call(
//       status == _GeofenceStatus.inside,
//       distanceMeters: distance,
//       radiusMeters: radius,
//     );
//   }

//   // ── Helpers ──────────────────────────────────────────────────────────────

//   Color get _dotColor {
//     if (widget.outsideOfficeAllowed) {
//       if (_status == _GeofenceStatus.inside ||
//           _status == _GeofenceStatus.outside ||
//           _status == _GeofenceStatus.locationOff) {
//         return AppColors.success;
//       }
//     }
//     return switch (_status) {
//       _GeofenceStatus.inside => AppColors.success,
//       _GeofenceStatus.outside => AppColors.warning,
//       _GeofenceStatus.locationOff ||
//       _GeofenceStatus.loading ||
//       _GeofenceStatus.notConfigured => AppColors.danger,
//     };
//   }

//   Color get _cardBg {
//     if (widget.outsideOfficeAllowed) {
//       if (_status == _GeofenceStatus.inside ||
//           _status == _GeofenceStatus.outside ||
//           _status == _GeofenceStatus.locationOff) {
//         return AppColors.success.withValues(alpha: 0.07);
//       }
//     }
//     return switch (_status) {
//       _GeofenceStatus.inside => AppColors.success.withValues(alpha: 0.07),
//       _GeofenceStatus.outside => AppColors.warning.withValues(alpha: 0.07),
//       _GeofenceStatus.locationOff ||
//       _GeofenceStatus.loading ||
//       _GeofenceStatus.notConfigured =>
//         AppColors.danger.withValues(alpha: 0.07),
//     };
//   }

//   Color get _borderColor {
//     if (widget.outsideOfficeAllowed) {
//       if (_status == _GeofenceStatus.inside ||
//           _status == _GeofenceStatus.outside ||
//           _status == _GeofenceStatus.locationOff) {
//         return AppColors.success.withValues(alpha: 0.25);
//       }
//     }
//     return switch (_status) {
//       _GeofenceStatus.inside => AppColors.success.withValues(alpha: 0.25),
//       _GeofenceStatus.outside => AppColors.warning.withValues(alpha: 0.25),
//       _GeofenceStatus.locationOff ||
//       _GeofenceStatus.loading ||
//       _GeofenceStatus.notConfigured =>
//         AppColors.danger.withValues(alpha: 0.25),
//     };
//   }

//   String get _statusLabel {
//     if (widget.outsideOfficeAllowed) {
//       return switch (_status) {
//         _GeofenceStatus.loading => 'Checking location…',
//         _GeofenceStatus.inside => 'Within Office Premises',
//         _GeofenceStatus.outside => 'Outside Office (Allowed)',
//         _GeofenceStatus.locationOff => 'Location Off (Allowed)',
//         _GeofenceStatus.notConfigured => 'Geofence Not Configured',
//       };
//     }
//     return switch (_status) {
//       _GeofenceStatus.loading => 'Checking location…',
//       _GeofenceStatus.inside => 'Within Office Premises',
//       _GeofenceStatus.outside => 'Outside Office Premises',
//       _GeofenceStatus.locationOff => 'Location Unavailable',
//       _GeofenceStatus.notConfigured => 'Geofence Not Configured',
//     };
//   }

//   IconData get _statusIcon {
//     return switch (_status) {
//       _GeofenceStatus.loading => Iconsax.gps,
//       _GeofenceStatus.inside => Iconsax.location_tick,
//       _GeofenceStatus.outside => Iconsax.location_slash,
//       _GeofenceStatus.locationOff => Iconsax.location_slash,
//       _GeofenceStatus.notConfigured => Iconsax.setting_2,
//     };
//   }

//   String _formatDistance(double meters) {
//     if (meters < 1000) return '${meters.toStringAsFixed(0)} m';
//     return '${(meters / 1000).toStringAsFixed(2)} km';
//   }

//   // ── Build ─────────────────────────────────────────────────────────────────

//   @override
//   Widget build(BuildContext context) {
//     final textTheme = Theme.of(context).textTheme;

//     return AnimatedContainer(
//       duration: const Duration(milliseconds: 350),
//       curve: Curves.easeInOut,
//       margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 8),
//       padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
//       decoration: BoxDecoration(
//         color: _cardBg,
//         borderRadius: BorderRadius.circular(16),
//         border: Border.all(color: _borderColor, width: 1.5),
//       ),
//       child: Column(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           // ── Top row: dot + label + refresh ──────────────────
//           Row(
//             children: [
//               // Pulsing dot
//               if (_status == _GeofenceStatus.loading)
//                 SizedBox(
//                   width: 12,
//                   height: 12,
//                   child: CircularProgressIndicator(
//                     strokeWidth: 2,
//                     color: _dotColor,
//                   ),
//                 )
//               else
//                 AnimatedBuilder(
//                   animation: _pulseAnim,
//                   builder: (context, _) => Opacity(
//                     opacity: _status == _GeofenceStatus.inside
//                         ? _pulseAnim.value
//                         : 1.0,
//                     child: Container(
//                       width: 10,
//                       height: 10,
//                       decoration: BoxDecoration(
//                         color: _dotColor,
//                         shape: BoxShape.circle,
//                         boxShadow: [
//                           BoxShadow(
//                             color: _dotColor.withValues(alpha: 0.5),
//                             blurRadius: 6,
//                             spreadRadius: 1,
//                           ),
//                         ],
//                       ),
//                     ),
//                   ),
//                 ),
//               const SizedBox(width: 10),
//               Icon(_statusIcon, size: 16, color: _dotColor),
//               const SizedBox(width: 8),
//               Expanded(
//                 child: Text(
//                   _statusLabel,
//                   style: textTheme.bodyMedium?.copyWith(
//                     fontWeight: FontWeight.w600,
//                     color: _dotColor,
//                   ),
//                 ),
//               ),
//               // Refresh button
//               InkWell(
//                 onTap: _refreshing ? null : _refresh,
//                 borderRadius: BorderRadius.circular(20),
//                 child: Padding(
//                   padding: const EdgeInsets.all(4),
//                   child: _refreshing
//                       ? SizedBox(
//                           width: 16,
//                           height: 16,
//                           child: CircularProgressIndicator(
//                             strokeWidth: 2,
//                             color: _dotColor,
//                           ),
//                         )
//                       : Icon(
//                           Iconsax.refresh,
//                           size: 18,
//                           color: _dotColor.withValues(alpha: 0.75),
//                         ),
//                 ),
//               ),
//             ],
//           ),

//           // ── Distance & accuracy row ──────────────────────────
//           if (_distanceMeters != null || _accuracyMeters != null) ...[
//             const SizedBox(height: 10),
//             Row(
//               children: [
//                 if (_distanceMeters != null) ...[
//                   _InfoChip(
//                     icon: Iconsax.routing,
//                     label:
//                         '${_formatDistance(_distanceMeters!)} from office',
//                     color: _dotColor,
//                   ),
//                 ],
//                 if (_distanceMeters != null && _accuracyMeters != null)
//                   const SizedBox(width: 8),
//                 if (_accuracyMeters != null) ...[
//                   _InfoChip(
//                     icon: Iconsax.gps,
//                     label: '±${_accuracyMeters!.toStringAsFixed(0)} m accuracy',
//                     color: AppColors.grey,
//                   ),
//                 ],
//               ],
//             ),
//           ],

//           // ── Radius hint ──────────────────────────────────────
//           if (_radiusMeters != null &&
//               _status == _GeofenceStatus.outside) ...[
//             const SizedBox(height: 6),
//             Row(
//               children: [
//                 Icon(
//                   Iconsax.info_circle,
//                   size: 13,
//                   color: AppColors.grey.withValues(alpha: 0.8),
//                 ),
//                 const SizedBox(width: 6),
//                 Text(
//                   'Required: within ${_formatDistance(_radiusMeters!)} of office',
//                   style: textTheme.bodySmall?.copyWith(
//                     color: AppColors.grey,
//                     fontSize: 11.5,
//                   ),
//                 ),
//               ],
//             ),
//           ],

//           // ── Not configured tip ───────────────────────────────
//           if (_status == _GeofenceStatus.notConfigured) ...[
//             const SizedBox(height: 8),
//             Text(
//               'Ask your admin to configure the company GPS location in Settings → Company Location.',
//               style: textTheme.bodySmall?.copyWith(
//                 color: AppColors.danger.withValues(alpha: 0.8),
//                 fontSize: 12,
//               ),
//             ),
//           ],

//           // ── Location off action ──────────────────────────────
//           if (_status == _GeofenceStatus.locationOff) ...[
//             const SizedBox(height: 10),
//             Row(
//               children: [
//                 Expanded(
//                   child: OutlinedButton.icon(
//                     onPressed: () async {
//                       await LocationService.openLocationSettings();
//                       await Future.delayed(const Duration(seconds: 2));
//                       _refresh();
//                     },
//                     icon: const Icon(Iconsax.setting_2, size: 14),
//                     label: const Text('Enable Location'),
//                     style: OutlinedButton.styleFrom(
//                       foregroundColor: AppColors.danger,
//                       side: BorderSide(
//                         color: AppColors.danger.withValues(alpha: 0.5),
//                       ),
//                       padding: const EdgeInsets.symmetric(vertical: 8),
//                       textStyle: const TextStyle(fontSize: 12),
//                       shape: RoundedRectangleBorder(
//                         borderRadius: BorderRadius.circular(10),
//                       ),
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ],
//         ],
//       ),
//     );
//   }
// }

// // ── Small info chip ────────────────────────────────────────────────────────
// class _InfoChip extends StatelessWidget {
//   final IconData icon;
//   final String label;
//   final Color color;

//   const _InfoChip({
//     required this.icon,
//     required this.label,
//     required this.color,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//       decoration: BoxDecoration(
//         color: color.withValues(alpha: 0.1),
//         borderRadius: BorderRadius.circular(20),
//       ),
//       child: Row(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           Icon(icon, size: 11, color: color),
//           const SizedBox(width: 4),
//           Text(
//             label,
//             style: TextStyle(
//               fontSize: 11.5,
//               fontWeight: FontWeight.w500,
//               color: color,
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
