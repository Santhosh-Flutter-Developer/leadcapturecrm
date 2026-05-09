part of 'chat_messages.dart';

void openUser(BuildContext context, dynamic user) {
  if (user == null) return;

  if (kIsMobile) {
    Sheet.showSheet(
      context,
      widget: user is AdminModel
          ? AdminProfile(admin: user)
          : EmployeeDetails(employee: user),
    );
  } else {
    GeneralDialog.showRTLSheet(
      context,
      user is AdminModel
          ? AdminProfile(admin: user)
          : EmployeeDetails(employee: user),
    );
  }
}

class ChatTopBar extends StatelessWidget implements PreferredSizeWidget {
  final String userUid;
  final String lastSeen;
  final VoidCallback? onBack;
  final ChatModel chat;
  final ValueChanged<String>? onSearchChanged;
  final VoidCallback? onSearchClose;
  final bool isSearching;

  const ChatTopBar({
    super.key,
    required this.userUid,
    required this.lastSeen,
    this.onBack,
    required this.chat,
    this.onSearchChanged,
    this.onSearchClose,
    this.isSearching = false,
  });

  @override
  Size get preferredSize => const Size.fromHeight(70);
  @override
  Widget build(BuildContext context) {
    final dynamic user = CacheService.getUserByUid(userUid);

    String? userName;
    String? userImage;

    if (user is AdminModel) {
      userName = user.name;
      userImage = user.profileImageUrl;
    } else if (user is EmployeeModel) {
      userName = user.name;
      userImage = user.profileImageUrl;
    } else {
      userName = null;
      userImage = null;
    }

    return AppBar(
      backgroundColor: AppColors.primary,
      elevation: 2,
      titleSpacing: 0,
      title: isSearching
          ? _buildSearchField()
          : Row(
              children: [
                if (onBack != null)
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: AppColors.black),
                    onPressed: onBack,
                  ),
                if (chat.isGroupChat) ...[
                  const CircleAvatar(
                    backgroundColor: AppColors.grey200,
                    radius: 22,
                    child: Icon(Icons.group, size: 20),
                  ),
                ] else ...[
                  if (userImage != null && userImage.isNotEmpty) ...[
                    GestureDetector(
                      onTap: () => openUser(context, user),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(100),
                        child: CachedNetworkImage(
                          imageUrl: userImage,
                          placeholder: (context, url) => Shimmer.fromColors(
                            baseColor: AppColors.grey300,
                            highlightColor: AppColors.grey100,
                            child: Container(color: AppColors.white),
                          ),
                          errorWidget: (context, url, error) =>
                              const Icon(Icons.error),
                          height: 35,
                          width: 35,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ] else ...[
                    GestureDetector(
                      onTap: () => openUser(context, user),
                      child: CircleAvatar(
                        backgroundColor: AppColors.grey200,
                        radius: 22,
                        child: Text(
                          (userName ?? '?').capitalizeFirst,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: AppColors.primary),
                        ),
                      ),
                    ),
                  ],
                ],
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: () => openUser(context, user),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (chat.isGroupChat) ...[
                          Text(
                            chat.title ?? '',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.white,
                                ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${chat.participants.length} Members',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: AppColors.grey200),
                          ),
                        ] else ...[
                          Text(
                            userName ?? '',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.white,
                                ),
                          ),
                          const SizedBox(height: 2),

                          StreamBuilder<UserStatusModel?>(
                            stream: UserStatusService.streamStatus(userUid),
                            builder: (context, snapshot) {
                              if (userUid.isEmpty) {
                                return Text(
                                  "Last seen: Unknown",
                                  style: Theme.of(context).textTheme.bodyMedium
                                      ?.copyWith(color: AppColors.grey200),
                                );
                              }

                              if (!snapshot.hasData) {
                                return Text(
                                  "Last seen: loading...",
                                  style: Theme.of(context).textTheme.bodyMedium
                                      ?.copyWith(color: AppColors.grey200),
                                );
                              }

                              final status = snapshot.data!;

                              return Text(
                                status.isOnline
                                    ? "Online"
                                    : "Last seen: ${formatLastSeen(status.lastSeen)}",
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(color: AppColors.grey200),
                              );
                            },
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
      actions: [
        IconButton(
          icon: Icon(
            isSearching ? Icons.close : Iconsax.search_normal,
            color: AppColors.white,
          ),
          onPressed: () {
            if (isSearching) {
              onSearchClose?.call();
            } else {
              onSearchChanged?.call('');
            }
          },
        ),

        if (!isSearching)
          IconButton(
            icon: const Icon(Icons.info_outline, color: AppColors.white),
            onPressed: () {
              showModalBottomSheet(
                context: context,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                ),
                builder: (_) => AboutChat(chat: chat, userUid: userUid),
              );
            },
          ),
      ],
    );
  }

  Widget _buildSearchField() {
    return Align(
      alignment: Alignment.centerLeft,
      child: SizedBox(
        width: 220, // adjust width here
        child: Container(
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: AppColors.white.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: TextField(
            autofocus: true,
            onChanged: onSearchChanged,
            decoration: InputDecoration(
              hintText: 'Search...',
              hintStyle: TextStyle(
                color: AppColors.white.withValues(alpha: 0.7),
                fontSize: 14,
              ),
              border: InputBorder.none,
              isDense: true,
              icon: Icon(
                Iconsax.search_normal,
                size: 18,
                color: AppColors.white.withValues(alpha: 0.8),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class ChatTopBarDesktop extends StatelessWidget implements PreferredSizeWidget {
  final String userUid;
  final String lastSeen;
  final VoidCallback? onBack;
  final ChatModel chat;
  final ValueChanged<String>? onSearchChanged;
  final VoidCallback? onSearchClose;
  final bool isSearching;

  const ChatTopBarDesktop({
    super.key,
    required this.userUid,
    required this.lastSeen,
    this.onBack,
    required this.chat,
    this.onSearchChanged,
    this.onSearchClose,
    this.isSearching = false,
  });

  @override
  Size get preferredSize => const Size.fromHeight(70);

  @override
  Widget build(BuildContext context) {
    final dynamic user = CacheService.getUserByUid(userUid);

    String? userName;
    String? userImage;

    if (user is AdminModel) {
      userName = user.name;
      userImage = user.profileImageUrl;
    } else if (user is EmployeeModel) {
      userName = user.name;
      userImage = user.profileImageUrl;
    } else {
      userName = null;
      userImage = null;
    }

    return AppBar(
      centerTitle: false,
      backgroundColor: AppColors.white,
      elevation: 0,
      toolbarHeight: 56,
      leadingWidth: 48,
      titleSpacing: 0,

      leading: isSearching
          ? const SizedBox.shrink()
          : Padding(
              padding: const EdgeInsets.only(left: 8),
              child: _buildLeadingAvatar(context, user, userName, userImage),
            ),

      title: isSearching
          ? _buildSearchField(context)
          : _buildTitle(context, user, userName, userImage),

      actions: [
        IconButton(
          icon: Icon(
            isSearching ? Icons.close : Iconsax.search_normal,
            color: AppColors.primary,
          ),
          onPressed: () {
            if (isSearching) {
              onSearchClose?.call();
            } else {
              onSearchChanged?.call('');
            }
          },
        ),

        if (!isSearching)
          IconButton(
            icon: const Icon(Iconsax.info_circle, color: AppColors.primary),
            onPressed: () {
              GeneralDialog.showRTLSheet(
                context,
                AboutChat(chat: chat, userUid: userUid),
              );
            },
          ),
      ],
    );
  }

  Widget _buildLeadingAvatar(
    BuildContext context,
    dynamic user,
    String? userName,
    String? userImage,
  ) {
    if (chat.isGroupChat) {
      return const CircleAvatar(
        radius: 15,
        backgroundColor: AppColors.primary,
        child: Icon(Icons.group, size: 18, color: AppColors.white),
      );
    }

    if (userImage != null && userImage.isNotEmpty) {
      return GestureDetector(
        onTap: () => openUser(context, user),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(100),
          child: CachedNetworkImage(
            imageUrl: userImage,
            height: 32,
            width: 32,
            fit: BoxFit.cover,
          ),
        ),
      );
    }

    return GestureDetector(
      onTap: () => openUser(context, user),
      child: CircleAvatar(
        radius: 15,
        backgroundColor: LetterColors.getColor((userName ?? '?').first),
        child: Text(
          (userName ?? '?').first,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: AppColors.white),
        ),
      ),
    );
  }

  Widget _buildTitle(
    BuildContext context,
    dynamic user,
    String? userName,
    String? userImage,
  ) {
    if (isSearching) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          Expanded(
            child: chat.isGroupChat
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        chat.title ?? '',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        '${chat.participants.length} Members',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.grey500,
                        ),
                      ),
                    ],
                  )
                : GestureDetector(
                    onTap: () => openUser(context, user),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          userName ?? "",
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        StreamBuilder<UserStatusModel?>(
                          stream: UserStatusService.streamStatus(userUid),
                          builder: (context, snapshot) {
                            if (!snapshot.hasData) {
                              return const SizedBox.shrink();
                            }

                            final status = snapshot.data!;
                            return Text(
                              status.isOnline
                                  ? "Online"
                                  : "Last seen: ${formatLastSeen(status.lastSeen)}",
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(color: AppColors.grey500),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchField(BuildContext context) {
    return Container(
      height: 38,
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.grey100,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.grey300),
      ),
      child: TextField(
        autofocus: true,
        onChanged: onSearchChanged,
        decoration: InputDecoration(
          hintText: 'Search messages...',
          border: InputBorder.none,
          isDense: true,
          icon: const Icon(Iconsax.search_normal, size: 18),
        ),
      ),
    );
  }
}

Future<dynamic> _resolveChatProfileByUid(String uid) async {
  if (uid.trim().isEmpty) return null;

  final cached = CacheService.getUserByUid(uid);
  if (cached is EmployeeModel || cached is AdminModel) {
    return cached;
  }

  try {
    final employee = await EmployeeService.getEmployee(uid: uid);
    if (employee != null) return employee;
  } catch (_) {}

  try {
    final admin = await AdminService.getAdmin(uid: uid);
    if (admin != null) return admin;
  } catch (_) {}

  return null;
}

Future<void> _openChatUserProfile(BuildContext context, String uid) async {
  final profile = await _resolveChatProfileByUid(uid);
  if (!context.mounted) return;

  if (profile is EmployeeModel) {
    if (kIsMobile) {
      await Sheet.showSheet(
        context,
        widget: EmployeeDetails(employee: profile),
      );
    } else {
      await GeneralDialog.showRTLSheet(
        context,
        EmployeeDetails(employee: profile),
      );
    }
    return;
  }

  if (profile is AdminModel) {
    if (kIsMobile) {
      await Sheet.showSheet(context, widget: AdminProfile(admin: profile));
    } else {
      await GeneralDialog.showRTLSheet(context, AdminProfile(admin: profile));
    }
    return;
  }

  FlushBar.show(context, 'User profile not found', isSuccess: false);
}

String formatLastSeen(DateTime? time) {
  if (time == null) return "Unknown";

  final now = DateTime.now();
  final diff = now.difference(time);

  String formatTime12(DateTime t) {
    final hour = t.hour % 12 == 0 ? 12 : t.hour % 12;
    final minute = t.minute.toString().padLeft(2, '0');
    final period = t.hour >= 12 ? 'PM' : 'AM';
    return "$hour:$minute $period";
  }

  if (diff.inMinutes < 1) {
    return "Just now";
  } else if (diff.inMinutes < 60) {
    return "${diff.inMinutes} min ago";
  } else if (diff.inHours < 24) {
    return "${diff.inHours} hours ago";
  } else if (diff.inDays == 1) {
    return "Yesterday, ${formatTime12(time)}";
  } else {
    return "${time.day}-${time.month}-${time.year}, ${formatTime12(time)}";
  }
}
