import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:iconsax/iconsax.dart';
import '/app/app.dart';
import '/theme/theme.dart';
import '/utils/utils.dart';
import '/views/views.dart';

class Settings extends StatelessWidget {
  final bool showAppbar;
  final Function(bool)? onThemeChanged;

  const Settings({super.key, this.showAppbar = true, this.onThemeChanged});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => SettingsBloc()..add(LoadSettingsEvent())),
      ],
      child: SettingsListing(
        showAppbar: showAppbar,
        onThemeChanged: onThemeChanged,
      ),
    );
  }
}

class SettingsListing extends StatefulWidget {
  final bool showAppbar;
  final Function(bool)? onThemeChanged;

  const SettingsListing({
    super.key,
    this.showAppbar = true,
    this.onThemeChanged,
  });

  @override
  State<SettingsListing> createState() => _SettingsListingState();
}

class _SettingsListingState extends State<SettingsListing> {
  @override
  Widget build(BuildContext context) {
    final themeProvider = context.read<ThemeProvider>();
    bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: widget.showAppbar
          ? AppBar(
              leading: const Back(), // Assuming 'Back' is a defined widget
              title: Text(
                "Settings",
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              backgroundColor: AppColors.white,
              foregroundColor: AppColors.black,
              elevation: 0,
              centerTitle: true,
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(1),
                child: Container(
                  color: Colors.grey.withValues(alpha: 0.1),
                  height: 1,
                ),
              ),
            )
          : null,
      body: BlocConsumer<SettingsBloc, SettingsState>(
        listener: (context, state) {},
        builder: (context, state) {
          if (state is SettingsLoading) {
            return const Center(child: WaitingLoading());
          }

          if (state is SettingsLoaded) {
            final settings = state.settings;
            return ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
              children: [
                SettingsSection(
                  title: "NOTIFICATIONS",
                  children: [
                    SettingsSwitchTile(
                      icon: Iconsax.sms,
                      iconColor: Colors.blueAccent,
                      title: "Email Notifications",
                      value: settings.emailNotification,
                      onChanged: (val) {
                        context.read<SettingsBloc>().add(
                          UpdateSettingsEvent("emailNotification", val),
                        );
                      },
                    ),
                    SettingsSwitchTile(
                      icon: Iconsax.notification,
                      iconColor: Colors.orangeAccent,
                      title: "Push Notifications",
                      value: settings.pushNotification,
                      onChanged: (val) {
                        context.read<SettingsBloc>().add(
                          UpdateSettingsEvent("pushNotification", val),
                        );
                      },
                    ),
                    SettingsSwitchTile(
                      icon: Iconsax.message,
                      iconColor: Colors.greenAccent,
                      title: "In-App Notifications",
                      value: settings.inAppNotification,
                      onChanged: (val) {
                        context.read<SettingsBloc>().add(
                          UpdateSettingsEvent("inAppNotification", val),
                        );
                      },
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                SettingsSection(
                  title: "APPLICATION",
                  children: [
                    SettingsTile(
                      icon: Iconsax.mobile_programming,
                      iconColor: Colors.purpleAccent,
                      title: "App Name",
                      trailing: SizedBox(
                        width: 150,
                        child: TextField(
                          controller: TextEditingController(
                            text: settings.appName,
                          ),
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: AppColors.grey700),
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            isDense: true,
                            hintText: "Enter Name",
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 6,
                            ),
                          ),
                          onChanged: (val) {
                            context.read<SettingsBloc>().add(
                              UpdateSettingsEvent("appName", val),
                            );
                          },
                        ),
                      ),
                    ),
                    SettingsTile(
                      icon: Iconsax.clock,
                      iconColor: Colors.tealAccent,
                      title: "Timezone",
                      trailing: _buildDropdown(
                        value: settings.timezone,
                        options: [
                          "UTC",
                          "IST (India)",
                          "PST (US Pacific)",
                          "EST (US Eastern)",
                          "CET (Central Europe)",
                          "GST (UAE)",
                        ],
                        onChanged: (val) {
                          context.read<SettingsBloc>().add(
                            UpdateSettingsEvent("timezone", val),
                          );
                        },
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                SettingsSection(
                  title: "PREFERENCES",
                  children: [
                    SettingsSwitchTile(
                      icon: Iconsax.moon,
                      iconColor: const Color(0xFF34495E),
                      title: "Dark Theme",
                      value: isDark,
                      onChanged: (value) {
                        themeProvider.setDarkMode(value);
                      },
                    ),
                    SettingsSwitchTile(
                      icon: Iconsax.message_2,
                      iconColor: Colors.pinkAccent,
                      title: "Show Chats",
                      value: settings.showChats,
                      onChanged: (val) {
                        context.read<SettingsBloc>().add(
                          UpdateSettingsEvent("showChats", val),
                        );
                      },
                    ),
                    SettingsTile(
                      icon: Iconsax.global,
                      iconColor: Colors.indigoAccent,
                      title: "Language",
                      trailing: _buildDropdown(
                        value: settings.language,
                        options: ["English", "Hindi", "Tamil", "Telugu"],
                        onChanged: (val) {
                          context.read<SettingsBloc>().add(
                            UpdateSettingsEvent("language", val),
                          );
                        },
                      ),
                    ),
                    SettingsTile(
                      icon: Iconsax.music_dashboard,
                      iconColor: Colors.deepOrangeAccent,
                      title: "Layout",
                      trailing: _buildDropdown(
                        value: settings.dashboardLayout,
                        options: ["Default", "Compact", "Analytics"],
                        onChanged: (val) {
                          context.read<SettingsBloc>().add(
                            UpdateSettingsEvent("dashboardLayout", val),
                          );
                        },
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                SettingsSection(
                  title: "SYSTEM",
                  children: [
                    SettingsSwitchTile(
                      icon: Iconsax.cloud_notif,
                      iconColor: Colors.cyan,
                      title: "Auto Backup",
                      value: settings.autoBackup,
                      onChanged: (val) {
                        context.read<SettingsBloc>().add(
                          UpdateSettingsEvent("autoBackup", val),
                        );
                      },
                    ),
                    SettingsTile(
                      icon: Iconsax.cloud_remove,
                      iconColor: Colors.redAccent,
                      title: "Backup Now",
                      trailing: const Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 14,
                        color: Colors.grey,
                      ),
                      onTap: () => Navigate.route(context, BackupListing()),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                SettingsSection(
                  title: "DATA",
                  children: [
                    SettingsTile(
                      icon: Iconsax.trash,
                      iconColor: Colors.red,
                      title: "Trash",
                      trailing: const Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 14,
                        color: Colors.grey,
                      ),
                      onTap: () => Navigate.route(
                        context,
                        TrashScreen(),
                      ), // Assuming TrashScreen exists
                    ),
                  ],
                ),

                const SizedBox(height: 40),
              ],
            );
          }

          return const ErrorDisplay(error: "Error loading settings");
        },
      ),
    );
  }

  // Helper to build a clean dropdown
  Widget _buildDropdown({
    required String value,
    required List<String> options,
    required ValueChanged<String?> onChanged,
  }) {
    // Ensure value is in options, fallback to first if not
    final validValue = options.contains(value) ? value : options.first;

    return DropdownButtonHideUnderline(
      child: DropdownButton<String>(
        value: validValue,
        icon: const Padding(
          padding: EdgeInsets.only(left: 4),
          child: Icon(
            Icons.keyboard_arrow_down_rounded,
            size: 18,
            color: Colors.grey,
          ),
        ),
        isDense: true,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: context.colors.textPrimary,
          fontWeight: FontWeight.w500,
        ),
        items: options
            .map(
              (e) => DropdownMenuItem(
                value: e,
                child: Text(e, style: Theme.of(context).textTheme.bodySmall),
              ),
            )
            .toList(),
        onChanged: onChanged,
      ),
    );
  }
}

// --- Components ---

class SettingsSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const SettingsSection({
    super.key,
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8, bottom: 8),
          child: Text(
            title,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: context.colors.textSecondary,
              letterSpacing: 1.1,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: context.colors.cardColor,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
            border: Border.all(color: Colors.grey.withValues(alpha: 0.05)),
          ),
          child: Column(
            children: [
              for (int i = 0; i < children.length; i++) ...[
                children[i],
                if (i != children.length - 1)
                  Divider(
                    height: 1,
                    indent: 56,
                    color: Colors.grey.withValues(alpha: 0.1),
                  ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class SettingsTile extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color iconColor;
  final Widget? trailing;
  final VoidCallback? onTap;

  const SettingsTile({
    super.key,
    required this.title,
    required this.icon,
    this.iconColor = AppColors.primary,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16), // Match section border
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w500,
                  color: context.colors.textPrimary,
                ),
              ),
            ),
            if (trailing != null) trailing!,
          ],
        ),
      ),
    );
  }
}

class SettingsSwitchTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final bool value;
  final ValueChanged<bool> onChanged;

  const SettingsSwitchTile({
    super.key,
    required this.icon,
    this.iconColor = AppColors.primary,
    required this.title,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              title,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w500,
                color: context.colors.textSecondary,
              ),
            ),
          ),
          MorphSwitch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}

// --- Custom Animated Switch ---
class MorphSwitch extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;

  const MorphSwitch({super.key, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        width: 46,
        height: 26,
        decoration: BoxDecoration(
          color: value ? AppColors.primary : Colors.grey.shade300,
          borderRadius: BorderRadius.circular(20),
        ),
        padding: const EdgeInsets.all(2),
        child: Align(
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: 22,
            height: 22,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
