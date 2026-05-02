import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:iconsax/iconsax.dart';
import 'package:shimmer/shimmer.dart';
import '/constants/constants.dart';
import '/services/services.dart';
import '/views/views.dart';
import '/models/models.dart';
import '/theme/theme.dart';
import '/utils/utils.dart';
import 'bloc/chat_bloc.dart';

const String _pageTitle = "Chat";

class ChatListing extends StatelessWidget {
  final String currentUserUid;
  final String? selectedChatUid;
  const ChatListing({
    super.key,
    required this.currentUserUid,
    this.selectedChatUid,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => ChatBloc()..add(StreamChat()),
      child: ChatListingView(
        currentUserUid: currentUserUid,
        selectedChatUid: selectedChatUid,
      ),
    );
  }
}

class ChatListingView extends StatefulWidget {
  final String currentUserUid;
  final String? selectedChatUid;

  const ChatListingView({
    super.key,
    required this.currentUserUid,
    this.selectedChatUid,
  });

  @override
  State<ChatListingView> createState() => _ChatListingViewState();
}

class _ChatListingViewState extends State<ChatListingView> {
  String? _selectedChatUid;

  @override
  void initState() {
    _selectedChatUid = widget.selectedChatUid;
    debugPrint("the chat id on the listing inside $_selectedChatUid");
    super.initState();
  }

  void _openChatFromMention(ChatModel chat, String opponentUid) {
    setState(() {
      _selectedChatUid = chat.uid;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: kIsMobile
          ? AppBar(leading: Back(), title: Text(_pageTitle))
          : null,
      body: BlocBuilder<ChatBloc, ChatState>(
        builder: (context, state) {
          if (state is ChatLoading) {
            return const WaitingLoading();
          } else if (state is ChatLoaded) {
            final selectedIndex = state.chats.indexWhere(
              (c) => c.uid == _selectedChatUid,
            );
            final selectedChat = selectedIndex != -1
                ? state.chats[selectedIndex]
                : null;
            return LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth < 900) {
                  print("the chats ${state.chats}");
                  if (state.chats.isNotEmpty) {
                    return ChatListPanel(
                      onSelect: (index) {
                        Navigate.route(
                          context,
                          ChatMessages(
                            chat: state.chats[index],
                            currentUser: widget.currentUserUid,
                            opponentUid: state.chats[index].participants
                                .firstWhere(
                                  (id) => id != widget.currentUserUid,
                                  orElse: () => '',
                                ),
                            onOpenChat: _openChatFromMention,
                          ),
                        );
                      },
                      chats: state.chats,
                      selectedChatUid: _selectedChatUid,
                      currentUserUid: widget.currentUserUid,
                    );
                  }
                  return _buildNoChatSelected();
                } else {
                  return Row(
                    children: [
                      ChatListPanel(
                        chats: state.chats,
                        selectedChatUid: _selectedChatUid,
                        onSelect: (index) {
                          setState(() {
                            _selectedChatUid = state.chats[index].uid;
                          });
                        },
                        currentUserUid: widget.currentUserUid,
                      ),
                      Expanded(
                        child: selectedChat != null
                            ? ChatMessages(
                                key: ValueKey(selectedChat.uid),
                                chat: selectedChat,
                                currentUser: widget.currentUserUid,
                                opponentUid: selectedChat.participants
                                    .firstWhere(
                                      (id) => id != widget.currentUserUid,
                                      orElse: () => '',
                                    ),
                                onOpenChat: _openChatFromMention,
                              )
                            : _buildNoChatSelected(),
                      ),
                    ],
                  );
                }
              },
            );
          } else if (state is ChatError) {
            return ErrorDisplay(error: state.message);
          }
          return Center(
            child: Text(
              "No chat found",
              style: Theme.of(context).textTheme.bodySmall,
            ),
          );
        },
      ),
      floatingActionButton: kIsMobile
          ? FloatingActionButton(
              heroTag: null,
              foregroundColor: AppColors.white,
              backgroundColor: AppColors.primary,
              tooltip: "Appeals",
              shape: const CircleBorder(),
              onPressed: () =>
                  Sheet.showSheet(context, widget: const CreateChat()),
              child: const Icon(Iconsax.message_add),
            )
          : null,
    );
  }

  Widget _buildNoChatSelected() {
    return Container(
      color: AppColors.grey100,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Iconsax.message_search, size: 80, color: AppColors.grey400),
            const SizedBox(height: 16),
            Text(
              "Select a Conversation",
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(color: AppColors.grey600),
            ),
            Text(
              "Click on a chat from the list to view messages.",
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.grey500),
            ),
          ],
        ),
      ),
    );
  }
}

class ChatListPanel extends StatefulWidget {
  final List<ChatModel> chats;
  final String? selectedChatUid;
  final ValueChanged<int> onSelect;
  final String currentUserUid;

  const ChatListPanel({
    super.key,
    required this.chats,
    this.selectedChatUid,
    required this.onSelect,
    required this.currentUserUid,
  });

  @override
  State<ChatListPanel> createState() => _ChatListPanelState();
}

class _ChatListPanelState extends State<ChatListPanel> {
  late final TextEditingController _searchController;
  late final ValueListenable<List<EmployeeModel>> _cacheListenable;
  List<ChatModel> _filteredChats = [];

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _cacheListenable = CacheService().getAllListenableEmployees();

    // Initialize the filtered list with all chats
    _filteredChats = widget.chats;

    // Add listeners to trigger filtering
    _searchController.addListener(_filterChats);
    _cacheListenable.addListener(_filterChats);
  }

  @override
  void dispose() {
    // Clean up listeners and controller
    _searchController.removeListener(_filterChats);
    _cacheListenable.removeListener(_filterChats);
    _searchController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant ChatListPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If the original chat list from the parent changes, re-apply the filter
    if (widget.chats != oldWidget.chats) {
      _filterChats();
    }
  }

  void _filterChats() {
    final query = _searchController.text.trim().toLowerCase();
    final cacheValue = _cacheListenable.value;

    setState(() {
      _filteredChats = widget.chats.where((chat) {
        if (chat.isDeletedForUser(widget.currentUserUid)) {
          return false;
        }
        String chatName = '';

        if (chat.isGroupChat) {
          chatName = chat.title ?? '';
        } else {
          final opponentUid = chat.participants.firstWhere(
            (id) => id != widget.currentUserUid,
            orElse: () => '',
          );

          if (opponentUid.isNotEmpty) {
            final employee = cacheValue.cast<EmployeeModel?>().firstWhere(
              (e) => e?.uid == opponentUid,
              orElse: () => null,
            );
            chatName = employee?.name ?? '';
          }
        }

        final lastMessage = chat.lastMessage?.message ?? '';

        if (query.isEmpty) return true;

        final q = query.trim().toLowerCase();
        final name = chatName.toLowerCase();
        final message = lastMessage.toLowerCase();

        return name.contains(q) || message.contains(q);
      }).toList();
      // keep pinned chats on top
      _filteredChats.sort((a, b) {
        final ap = a.isPinnedForUser(widget.currentUserUid) ? 1 : 0;
        final bp = b.isPinnedForUser(widget.currentUserUid) ? 1 : 0;
        return bp.compareTo(ap);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: kIsMobile ? double.infinity : 320,
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.grey300),
        color: AppColors.white,
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Find employee or chat',
                      prefixIcon: const Icon(Iconsax.search_normal, size: 18),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: AppColors.grey200,
                      isDense: true,
                    ),
                    onTapOutside: (_) => FocusScope.of(context).unfocus(),
                  ),
                ),

                if (kIsDesktop) ...[
                  const SizedBox(width: 8),
                  Material(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(10),
                    child: IconButton(
                      tooltip: "Create Chat",
                      icon: const Icon(
                        Iconsax.message_add,
                        color: AppColors.white,
                      ),
                      onPressed: () =>
                          Sheet.showSheet(context, widget: const CreateChat()),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView.builder(
              // Use the filtered list
              itemCount: _filteredChats.length,
              itemBuilder: (context, index) {
                final chat = _filteredChats[index];

                final originalIndex = widget.chats.indexOf(chat);
                final isSelected = chat.uid == widget.selectedChatUid;

                return _ChatListItem(
                  chat: chat,
                  isSelected: isSelected,
                  onTap: () => widget.onSelect(originalIndex),
                  currentUserUid: widget.currentUserUid,
                  onAction: (action) async {
                    switch (action) {
                      case ChatAction.pin:
                        await ChatService.toggleChatPin(
                          chatId: chat.uid!,
                          value: !chat.isPinnedForUser(widget.currentUserUid),
                        );
                        break;

                      case ChatAction.favorite:
                        await ChatService.toggleChatFavorite(
                          chatId: chat.uid!,
                          value: !chat.isFavoriteForUser(widget.currentUserUid),
                        );
                        break;
                      case ChatAction.delete:
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Delete chat'),
                            content: const Text(
                              'This chat will be deleted. You can undo this action.',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: const Text('Cancel'),
                              ),
                              ElevatedButton(
                                onPressed: () => Navigator.pop(context, true),
                                child: const Text('Delete'),
                              ),
                            ],
                          ),
                        );

                        if (confirm == true) {
                          final chatId = chat.uid!;
                          final deletedChat = chat; // ✅ backup

                          // ✅ DELETE
                          await ChatService.deleteChat(chatId: chatId);

                          if (!context.mounted) return;

                          // ✅ SHOW UNDO
                          FlushBar.show(
                            context,
                            'Chat deleted',
                            actionLabel: 'UNDO',
                            onActionPressed: () async {
                              await ChatService.restoreChat(deletedChat);
                              if (!context.mounted) return;
                              context.read<ChatBloc>().add(StreamChat());
                            },
                          );
                        }
                        break;
                    }
                  },
                );
              },
            ),
          ),

          // if (kIsDesktop) ...[
          //   SizedBox(
          //     width: double.infinity,
          //     child: Padding(
          //       padding: const EdgeInsets.symmetric(
          //         horizontal: 8.0,
          //         vertical: 4,
          //       ),
          //       child: ElevatedButton(
          //         onPressed: () =>
          //             Sheet.showSheet(context, widget: const CreateChat()),
          //         style: ElevatedButton.styleFrom(
          //           backgroundColor: AppColors.primary, // button color
          //           foregroundColor: AppColors.white, // text/icon color
          //           elevation: 3, // shadow
          //           padding: const EdgeInsets.symmetric(vertical: 16),
          //           shape: RoundedRectangleBorder(
          //             borderRadius: BorderRadius.circular(12),
          //           ),
          //         ),
          //         child: const Text("Create Chat"),
          //       ),
          //     ),
          //   ),
          // ],
        ],
      ),
    );
  }
}

class _ChatListItem extends StatelessWidget {
  final ChatModel chat;
  final bool isSelected;
  final VoidCallback onTap;
  final String currentUserUid;
  final void Function(ChatAction action) onAction;

  const _ChatListItem({
    required this.chat,
    required this.isSelected,
    required this.onTap,
    required this.currentUserUid,
    required this.onAction,
  });

  Future<dynamic> _resolveProfileByUid(String uid) async {
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
    final profile = await _resolveProfileByUid(uid);
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

  @override
  Widget build(BuildContext context) {
    String opponentUid = chat.participants.firstWhere(
      (id) => id != currentUserUid,
      orElse: () => '',
    );
    var user = CacheService.getUserByUid(opponentUid);
    // final user = employee ?? admin;
    final String name = user?.name ?? user?.name ?? '';
    final String imageUrl = user is EmployeeModel
        ? (user.profileImageUrl ?? '')
        : user is AdminModel
        ? (user.profileImageUrl ?? '')
        : '';

    final bool nameValid = name.isNotEmpty;
    final bool avatarValid = imageUrl.isNotEmpty;

    return Material(
      color: isSelected ? AppColors.blue50 : AppColors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              chat.isGroupChat
                  ? CircleAvatar(
                      backgroundColor: AppColors.blue,
                      foregroundColor: AppColors.white,
                      child: const Icon(Icons.group, size: 20),
                    )
                  : InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: () => _openChatUserProfile(context, opponentUid),
                      child: CircleAvatar(
                        backgroundColor: nameValid
                            ? LetterColors.getColor(name.first)
                            : AppColors.success,
                        foregroundColor: AppColors.white,
                        child: avatarValid
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(100),
                                child: CachedNetworkImage(
                                  imageUrl: imageUrl,
                                  placeholder: (context, url) =>
                                      Shimmer.fromColors(
                                        baseColor: AppColors.grey300,
                                        highlightColor: AppColors.grey100,
                                        child: Container(
                                          color: AppColors.white,
                                        ),
                                      ),
                                  errorWidget: (context, url, error) =>
                                      const Icon(Icons.error),
                                  height: 80,
                                  width: 80,
                                  fit: BoxFit.cover,
                                ),
                              )
                            : Text(
                                nameValid ? name.first : '',
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(color: AppColors.white),
                              ),
                      ),
                    ),
              const SizedBox(width: 12),
              Expanded(
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          chat.isGroupChat
                              ? Text(
                                  '${chat.title ?? ''} ${chat.isFavorite == true ? '❤️' : ''}',
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(fontWeight: FontWeight.bold),
                                  overflow: TextOverflow.ellipsis,
                                )
                              : InkWell(
                                  onTap: () => _openChatUserProfile(
                                    context,
                                    opponentUid,
                                  ),
                                  child: Text(
                                    '$name ${chat.isFavorite == true ? '❤️' : ''}',
                                    style: Theme.of(context).textTheme.bodySmall
                                        ?.copyWith(fontWeight: FontWeight.bold),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                          Text(
                            chat.lastMessage?.senderId == currentUserUid
                                ? ("You: ${chat.lastMessage?.message ?? ''}")
                                : (chat.lastMessage?.message ?? ''),
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: AppColors.grey600),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),

                    if (chat.isPinnedForUser(currentUserUid))
                      const Padding(
                        padding: EdgeInsets.only(left: 4),
                        child: Icon(
                          Icons.push_pin,
                          size: 14,
                          color: AppColors.grey,
                        ),
                      ),
                  ],
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        chat.lastMessage?.timestamp?.formatTime ?? '',
                        style: Theme.of(
                          context,
                        ).textTheme.bodySmall?.copyWith(color: AppColors.grey),
                      ),
                      const SizedBox(height: 4),
                      StreamBuilder<int>(
                        stream: ChatService.unviewedChatMessageCount(
                          chat.uid ?? '',
                        ),
                        builder: (context, snapshot) {
                          final count = snapshot.data ?? 0;
                          if (count == 0) return const SizedBox.shrink();
                          return CircleAvatar(
                            radius: 10,
                            backgroundColor: AppColors.blue.withValues(
                              alpha: 0.8,
                            ),
                            child: Text(
                              count.toString(),
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(color: AppColors.white),
                            ),
                          );
                        },
                      ),
                    ],
                  ),

                  const SizedBox(width: 4),

                  PopupMenuButton<ChatAction>(
                    padding: EdgeInsets.zero,
                    icon: const Icon(Icons.more_vert, size: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    onSelected: onAction,
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: ChatAction.pin,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        child: Row(
                          children: [
                            Icon(
                              chat.isPinnedForUser(currentUserUid)
                                  ? Icons.push_pin_rounded
                                  : Icons.push_pin_outlined,
                              size: 20,
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              chat.isPinnedForUser(currentUserUid)
                                  ? 'Unpin chat'
                                  : 'Pin chat',
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(color: AppColors.black),
                            ),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: ChatAction.favorite,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        child: Row(
                          children: [
                            Icon(
                              chat.isFavoriteForUser(currentUserUid)
                                  ? Iconsax.heart_remove
                                  : Iconsax.heart,
                              size: 20,
                              color: chat.isFavoriteForUser(currentUserUid)
                                  ? AppColors.danger
                                  : AppColors.primary,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              chat.isFavoriteForUser(currentUserUid)
                                  ? 'Remove from favorites'
                                  : 'Add to favorites',
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(color: AppColors.black),
                            ),
                          ],
                        ),
                      ),
                      if (!chat.isGroupChat || chat.createdBy == currentUserUid)
                        PopupMenuItem(
                          value: ChatAction.delete,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.delete_outline,
                                size: 20,
                                color: AppColors.danger,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'Delete chat',
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(color: AppColors.danger),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
