// ─────────────────────────────────────────────────────────────────────────────
// notification_service_web.dart  — NEW FILE
// Used on web via conditional import. No local filesystem on web, so all
// avatar/cache helpers return null or do nothing.
// ─────────────────────────────────────────────────────────────────────────────

/// On web: no local filesystem — avatar caching is not possible.
/// Returns null so the notification falls back to a text-only display.
Future<String?> downloadAvatarCircular(
  String? url,
  String name, {
  int size = 192,
  Duration ttl = const Duration(days: 7),
  bool forceRefresh = false,
}) async {
  return null;
}

/// No-op on web.
Future<void> clearAvatarCacheNative() async {}
