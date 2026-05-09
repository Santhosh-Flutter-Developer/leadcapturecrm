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

  const ChatTopBar({
    super.key,
    required this.userUid,
    required this.lastSeen,
    this.onBack,
    required this.chat,
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
      title: Row(
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
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: AppColors.primary),
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
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.white,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${chat.participants.length} Members',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.grey200,
                      ),
                    ),
                  ] else ...[
                    Text(
                      userName ?? '',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
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
          icon: const Icon(Iconsax.search_normal, color: AppColors.primary),
          onPressed: () {
            if (kIsMobile) {
              Sheet.showSheet(context, widget: SearchChat(chat: chat));
            } else {
              GeneralDialog.showRTLSheet(context, SearchChat(chat: chat));
            }
          },
        ),
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
}

class ChatTopBarDesktop extends StatefulWidget implements PreferredSizeWidget {
  final String userUid;
  final String lastSeen;
  final VoidCallback? onBack;
  final ChatModel chat;

  const ChatTopBarDesktop({
    super.key,
    required this.userUid,
    required this.lastSeen,
    this.onBack,
    required this.chat,
  });

  @override
  State<ChatTopBarDesktop> createState() => _ChatTopBarDesktopState();
  @override
  Size get preferredSize => const Size.fromHeight(70);
}

class _ChatTopBarDesktopState extends State<ChatTopBarDesktop> {
  bool isSearching = false;
  final TextEditingController searchController = TextEditingController();
  Timer? debounce;
  List<MessagesModel> results = [];

  @override
  Widget build(BuildContext context) {
    final dynamic user = CacheService.getUserByUid(widget.userUid);

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
      toolbarHeight: 56, // optional: reduce height
      leadingWidth: 38,
      titleSpacing: 0,

      leading: Padding(
        padding: const EdgeInsets.only(left: 8),
        child: _buildLeadingAvatar(context, user, userName, userImage),
      ),

      title: _buildTitle(context, user, userName, userImage),
    );
  }

  Widget _buildLeadingAvatar(
    BuildContext context,
    dynamic user,
    String? userName,
    String? userImage,
  ) {
    if (widget.chat.isGroupChat) {
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
    bool isSearching = false;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (widget.chat.isGroupChat) ...[
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.chat.title ?? '',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.black,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '${widget.chat.participants.length} Members',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: AppColors.grey500),
                ),
              ],
            ),
            Row(
              children: [
                IconButton(
                  icon: const Icon(
                    Iconsax.search_normal,
                    color: AppColors.primary,
                  ),
                  onPressed: () {
                    if (kIsMobile) {
                      Sheet.showSheet(
                        context,
                        widget: SearchChat(chat: widget.chat),
                      );
                    } else {
                      GeneralDialog.showRTLSheet(
                        context,
                        SearchChat(chat: widget.chat),
                      );
                    }
                  },
                ),
                IconButton(
                  icon: const Icon(
                    Iconsax.info_circle,
                    color: AppColors.primary,
                  ),
                  onPressed: () {
                    if (kIsMobile) {
                      Sheet.showSheet(
                        context,
                        widget: AboutChat(
                          chat: widget.chat,
                          userUid: widget.userUid,
                        ),
                      );
                    } else {
                      GeneralDialog.showRTLSheet(
                        context,
                        AboutChat(chat: widget.chat, userUid: widget.userUid),
                      );
                    }
                  },
                ),
              ],
            ),
          ] else ...[
            GestureDetector(
              onTap: () => openUser(context, user),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    userName ?? "",
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.black,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  StreamBuilder<UserStatusModel?>(
                    stream: UserStatusService.streamStatus(widget.userUid),
                    builder: (context, snapshot) {
                      if (widget.userUid.isEmpty) {
                        return Text(
                          "Last seen: ",
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: AppColors.grey500),
                        );
                      }
                      if (!snapshot.hasData) {
                        return Text(
                          "",
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: AppColors.grey500),
                        );
                      }
                      final status = snapshot.data!;
                      return Text(
                        status.isOnline
                            ? "Online"
                            : "Last seen: ${formatLastSeen(status.lastSeen)}",
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.grey500,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            // Actions
            Row(
              children: [
                IconButton(
                  icon: const Icon(
                    Iconsax.search_normal,
                    color: AppColors.primary,
                  ),
                  onPressed: () {
                    if (kIsMobile) {
                      Sheet.showSheet(
                        context,
                        widget: SearchChat(chat: widget.chat),
                      );
                    } else {
                      GeneralDialog.showRTLSheet(
                        context,
                        SearchChat(chat: widget.chat),
                      );
                    }
                  },
                ),
                IconButton(
                  icon: const Icon(
                    Iconsax.info_circle,
                    color: AppColors.primary,
                  ),
                  onPressed: () {
                    if (kIsMobile) {
                      Sheet.showSheet(
                        context,
                        widget: AboutChat(
                          chat: widget.chat,
                          userUid: widget.userUid,
                        ),
                      );
                    } else {
                      GeneralDialog.showRTLSheet(
                        context,
                        AboutChat(chat: widget.chat, userUid: widget.userUid),
                      );
                    }
                  },
                ),
              ],
            ),
          ],
        ],
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
