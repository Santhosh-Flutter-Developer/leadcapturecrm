import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:shimmer/shimmer.dart';
import '/models/models.dart';
import '/services/services.dart';
import '/theme/theme.dart';
import '/utils/utils.dart';
import '/views/views.dart';

class AboutChat extends StatelessWidget {
  final ChatModel chat;
  final String userUid;

  const AboutChat({super.key, required this.chat, required this.userUid});

  @override
  Widget build(BuildContext context) {
    final title = chat.isGroupChat
        ? chat.title ?? 'Group'
        : CacheService.getUserByUid(userUid)?.name ?? '';

    return SafeArea(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: AppColors.grey300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              /// Header avatar + title
              Center(
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 36,
                      backgroundColor: AppColors.primary.withValues(
                        alpha: 0.12,
                      ),
                      child: chat.isGroupChat
                          ? const Icon(
                              Icons.group,
                              size: 34,
                              color: AppColors.primary,
                            )
                          : Text(
                              title.isNotEmpty
                                  ? title.toString().capitalizeFirst
                                  : '?',
                              style: Theme.of(context).textTheme.bodyLarge
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primary,
                                  ),
                            ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (chat.isGroupChat)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          '${chat.participants.length} members',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: AppColors.grey500),
                        ),
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              /// Members
              if (chat.isGroupChat) ...[
                Text('Members', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),

                Container(
                  decoration: BoxDecoration(
                    color: AppColors.grey50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.grey200),
                  ),
                  child: SizedBox(
                    height: 260,
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: chat.participants.length,
                      separatorBuilder: (_, _) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final uid = chat.participants[index];
                        final user = CacheService.getUserByUid(uid);

                        String name = 'Unknown';
                        String? image;

                        if (user is AdminModel) {
                          name = user.name;
                          image = user.profileImageUrl;
                        } else if (user is EmployeeModel) {
                          name = user.name;
                          image = user.profileImageUrl;
                        }

                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          leading: CircleAvatar(
                            radius: 22,
                            backgroundColor: (image == null || image.isEmpty)
                                ? LetterColors.getColor(
                                    name.isNotEmpty
                                        ? name.capitalizeFirst
                                        : 'U',
                                  )
                                : AppColors.grey200,
                            foregroundColor: AppColors.white,
                            child: image != null && image.isNotEmpty
                                ? ClipOval(
                                    child: CachedNetworkImage(
                                      imageUrl: image,
                                      height: 44,
                                      width: 44,
                                      fit: BoxFit.cover,
                                      placeholder: (_, _) => Shimmer.fromColors(
                                        baseColor: AppColors.grey300,
                                        highlightColor: AppColors.grey100,
                                        child: Container(
                                          color: AppColors.white,
                                        ),
                                      ),
                                      errorWidget: (_, _, _) =>
                                          const Icon(Icons.person, size: 20),
                                    ),
                                  )
                                : Text(
                                    name.isNotEmpty
                                        ? name.capitalizeFirst
                                        : '?',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(fontWeight: FontWeight.w600),
                                  ),
                          ),

                          /// Name
                          title: Text(
                            name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(fontWeight: FontWeight.w500),
                          ),

                          /// Role badge
                          subtitle: uid == chat.createdBy
                              ? Padding(
                                  padding: const EdgeInsets.only(top: 2),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary.withValues(
                                        alpha: 0.1,
                                      ),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      'Admin',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                            color: AppColors.primary,
                                            fontWeight: FontWeight.w500,
                                          ),
                                    ),
                                  ),
                                )
                              : null,

                          visualDensity: VisualDensity.compact,
                        );
                      },
                    ),
                  ),
                ),

                const SizedBox(height: 20),
              ],

              /// Actions
              // Text('Actions', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),

              ListTile(
                leading: Icon(
                  chat.isPinned == true
                      ? Icons.push_pin
                      : Icons.push_pin_outlined,
                  color: AppColors.primary,
                ),
                title: Text(
                  chat.isPinned == true ? 'Unpin chat' : 'Pin chat',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                onTap: () async {
                  await ChatService.toggleChatPin(
                    chatId: chat.uid!,
                    value: !chat.isPinned,
                  );
                  Navigator.pop(context);
                },
              ),

              ListTile(
                leading: Icon(
                  chat.isFavorite == true
                      ? Iconsax.heart_remove
                      : Iconsax.heart,
                  color: chat.isFavorite == true
                      ? AppColors.danger
                      : AppColors.primary,
                ),
                title: Text(
                  chat.isFavorite == true
                      ? 'Remove from favorites'
                      : 'Add to favorites',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                onTap: () async {
                  await ChatService.toggleChatFavorite(
                    chatId: chat.uid!,
                    value: !chat.isFavorite,
                  );
                  Navigator.pop(context);
                },
              ),

              const Divider(),

              /// Attachments
              ListTile(
                leading: const Icon(
                  Icons.attach_file,
                  color: AppColors.primary,
                ),
                title: Text(
                  'Media, links & documents',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.pop(context);

                  if (kIsMobile) {
                    Sheet.showSheet(
                      context,
                      widget: ChatAttachment(messages: []),
                    );
                  } else {
                    GeneralDialog.showRTLSheet(
                      context,
                      ChatAttachment(messages: []),
                    );
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
