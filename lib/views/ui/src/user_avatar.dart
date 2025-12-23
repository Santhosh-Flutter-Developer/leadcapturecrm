import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import '/constants/constants.dart';
import '/views/views.dart';
import '/models/models.dart';
import '/services/services.dart';
import '/theme/theme.dart';
import '/utils/utils.dart';

class UserAvatar extends StatelessWidget {
  final UserDataModel userData;
  final double size;
  final bool showCrown;

  const UserAvatar({
    super.key,
    required this.userData,
    this.size = 32, // IMPORTANT for rail
    this.showCrown = true,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: userData.name,
      child: InkWell(
        onTap: () async {
          var chatId = await ChatService.getChatUid(userData.uid);
          var currentUserUid = await Spdb.getUid();
          if (chatId != null && currentUserUid != null) {
            GeneralDialog.showRTLSheet(
              context,
              ChatListing(
                currentUserUid: currentUserUid,
                selectedChatUid: chatId,
              ),
            );
          }
        },
        child: SizedBox(
          width: size,
          height: size,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              /// Avatar
              ClipOval(
                child: Container(
                  width: size,
                  height: size,
                  decoration: BoxDecoration(
                    color: LetterColors.getColor(userData.name.first),
                  ),
                  child:
                      userData.profilePic != null &&
                          userData.profilePic!.isNotEmpty
                      ? Image.network(userData.profilePic!, fit: BoxFit.cover)
                      : Center(
                          child: Text(
                            _getInitials(userData.name),
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                          ),
                        ),
                ),
              ),

              if (userData.userType == UserType.admin && showCrown)
                Positioned(
                  top: -3,
                  right: -3,
                  child: Icon(
                    Iconsax.crown_15,
                    color: Color(0xFFFFC107),
                    size: 15,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _getInitials(String name) {
    if (name.isEmpty) return '';
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return '';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }
}
