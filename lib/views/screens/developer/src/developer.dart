import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import '/utils/utils.dart';
import '/services/services.dart';
import '/views/views.dart';

class DevAppColors {
  static const Color primary = Color(0xFF2563EB);
  static const Color background = Color(0xFFF8FAFC);
  static const Color white = Colors.white;
  static const Color border = Color(0xFFE2E8F0);
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color danger = Color(0xFFEF4444);
}

class Developer extends StatefulWidget {
  final bool showAppbar;
  const Developer({super.key, this.showAppbar = true});

  @override
  State<Developer> createState() => _DeveloperState();
}

class _DeveloperState extends State<Developer> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DevAppColors.background,
      appBar: widget.showAppbar
          ? AppBar(
              backgroundColor: DevAppColors.white,
              elevation: 0,
              centerTitle: false,
              leading: const Padding(
                padding: EdgeInsets.only(left: 8.0),
                child: Back(),
              ),
              title: const Text(
                "Developer Console",
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  color: DevAppColors.textPrimary,
                  fontSize: 18,
                ),
              ),
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(1),
                child: Container(color: DevAppColors.border, height: 1),
              ),
            )
          : null,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1000),
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              _buildSectionHeader("Tools & Debugging", Iconsax.setting_4),
              const SizedBox(height: 16),
              _buildToolGrid([
                _toolCard(
                  context,
                  "Notification Test",
                  "Trigger and verify push notification flows",
                  Iconsax.notification,
                  () async {
                    if (kIsDesktop) {
                      try {
                        await FirestoreNotificationListener.sendTestNotification();
                      } catch (e) {
                        FlushBar.show(context, e.toString(), isSuccess: true);
                      }
                    } else {
                      Navigate.route(context, const NotificationTestPage());
                    }
                  },
                ),
                _toolCard(
                  context,
                  "Shared Prefs",
                  "Inspect and edit local key-value storage",
                  Iconsax.data,
                  () => Navigate.route(context, const SharedprefsData()),
                ),
              ]),
              const SizedBox(height: 32),
              _buildSectionHeader("System & Stability", Iconsax.status),
              const SizedBox(height: 16),
              _buildToolGrid([
                _toolCard(
                  context,
                  "App Errors",
                  "Review recorded crashes and system logs",
                  Iconsax.close_circle,
                  () => Navigate.route(context, const AppErrors()),
                  isWarning: true,
                ),
                _toolCard(
                  context,
                  "Backup Listing",
                  "Manage cloud backups and data snapshots",
                  Iconsax.cloud,
                  () => Navigate.route(context, const BackupListing()),
                ),
              ]),
              const SizedBox(height: 40),
              _buildFooter(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 18, color: DevAppColors.textSecondary),
        const SizedBox(width: 8),
        Text(
          title.toUpperCase(),
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: DevAppColors.textSecondary,
            letterSpacing: 1.2,
          ),
        ),
      ],
    );
  }

  Widget _buildToolGrid(List<Widget> cards) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 600;
        return Wrap(
          spacing: 16,
          runSpacing: 16,
          children: cards.map((card) {
            return SizedBox(
              width: isWide
                  ? (constraints.maxWidth / 2) - 8
                  : constraints.maxWidth,
              child: card,
            );
          }).toList(),
        );
      },
    );
  }

  Widget _toolCard(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    VoidCallback onTap, {
    bool isWarning = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: DevAppColors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: DevAppColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isWarning
                    ? DevAppColors.danger.withValues(alpha: 0.1)
                    : DevAppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: isWarning ? DevAppColors.danger : DevAppColors.primary,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                      color: DevAppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: DevAppColors.textSecondary,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Iconsax.arrow_right_3,
              size: 16,
              color: DevAppColors.border,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: DevAppColors.border.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Text(
            "Debug Mode Active",
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: DevAppColors.textSecondary,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          "Version ${VersionService.version?.version ?? 'N/A'} (Stable Build)",
          style: TextStyle(fontSize: 11, color: DevAppColors.textSecondary),
        ),
      ],
    );
  }
}
