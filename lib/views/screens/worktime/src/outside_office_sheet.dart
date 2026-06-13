import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

import '/theme/theme.dart';

class OutsideOfficeSheet extends StatelessWidget {
  final double? distanceMeters;
  final double? radiusMeters;
  final VoidCallback onRefreshLocation;
  final VoidCallback? onRequestOverride;

  const OutsideOfficeSheet({
    super.key,
    this.distanceMeters,
    this.radiusMeters,
    required this.onRefreshLocation,
    this.onRequestOverride,
  });

  /// Shows the sheet and returns [true] if the user requested an override.
  static Future<bool?> show(
    BuildContext context, {
    double? distanceMeters,
    double? radiusMeters,
    required VoidCallback onRefreshLocation,
    VoidCallback? onRequestOverride,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => OutsideOfficeSheet(
        distanceMeters: distanceMeters,
        radiusMeters: radiusMeters,
        onRefreshLocation: onRefreshLocation,
        onRequestOverride: onRequestOverride,
      ),
    );
  }

  String _fmt(double meters) {
    if (meters < 1000) return '${meters.toStringAsFixed(0)} m';
    return '${(meters / 1000).toStringAsFixed(2)} km';
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 24,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      padding: EdgeInsets.fromLTRB(
        24,
        8,
        24,
        24 + MediaQuery.of(context).padding.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              color: AppColors.grey300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // ── Icon ─────────────────────────────────────────────
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFFA726), Color(0xFFEF5350)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFFA726).withValues(alpha: 0.4),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: const Icon(
              Iconsax.location_slash,
              color: Colors.white,
              size: 34,
            ),
          ),
          const SizedBox(height: 20),

          // ── Title ─────────────────────────────────────────────
          Text(
            'Outside Office Premises',
            style: textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
              letterSpacing: -0.3,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'You must be within the approved office zone to clock in.',
            style: textTheme.bodyMedium?.copyWith(color: AppColors.grey),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),

          // ── Distance vs. Radius Cards ─────────────────────────
          if (distanceMeters != null || radiusMeters != null)
            Row(
              children: [
                if (distanceMeters != null)
                  Expanded(
                    child: _MetricCard(
                      label: 'Your Distance',
                      value: _fmt(distanceMeters!),
                      icon: Iconsax.routing,
                      color: AppColors.warning,
                    ),
                  ),
                if (distanceMeters != null && radiusMeters != null)
                  const SizedBox(width: 12),
                if (radiusMeters != null)
                  Expanded(
                    child: _MetricCard(
                      label: 'Allowed Radius',
                      value: _fmt(radiusMeters!),
                      icon: Iconsax.location_tick,
                      color: AppColors.success,
                    ),
                  ),
              ],
            ),

          const SizedBox(height: 24),

          // ── Actions ───────────────────────────────────────────
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                onRefreshLocation();
              },
              icon: const Icon(Iconsax.refresh, size: 18),
              label: const Text('Refresh My Location'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                textStyle: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
                elevation: 0,
              ),
            ),
          ),
          const SizedBox(height: 10),
          if (onRequestOverride != null)
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.pop(context, true);
                  onRequestOverride?.call();
                },
                icon: const Icon(Iconsax.send_1, size: 18),
                label: const Text('Request Out-of-Office Approval'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.warning,
                  side: BorderSide(
                    color: AppColors.warning.withValues(alpha: 0.6),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  textStyle: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
              ),
            ),
          const SizedBox(height: 6),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }
}

// ── Metric card ────────────────────────────────────────────────────────────
class _MetricCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _MetricCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: color.withValues(alpha: 0.8),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: color,
              letterSpacing: -0.5,
            ),
          ),
        ],
      ),
    );
  }
}
