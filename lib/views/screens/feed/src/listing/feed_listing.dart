import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:iconsax/iconsax.dart';
import 'package:timeago/timeago.dart' as timeago;
import '/utils/utils.dart';
import '/views/views.dart';
import '/models/models.dart';
import '/constants/constants.dart';
import '/services/services.dart';
import '/theme/theme.dart';

part 'comment_sheet.dart';

// --- Unified Dashboard Palette ---
class FeedAppColors {
  static const Color primary = Color(0xFF2563EB);
  static const Color background = Color(0xFFF8FAFC);
  static const Color white = Colors.white;
  static const Color border = Color(0xFFE2E8F0);
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF64748B);
}

class FeedListing extends StatefulWidget {
  const FeedListing({super.key});

  @override
  State<FeedListing> createState() => _FeedListingState();
}

class _FeedListingState extends State<FeedListing> {
  String? _currentUserUid;

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
    context.read<FeedBloc>().add(LoadFeeds());
  }

  Future<void> _loadCurrentUser() async {
    _currentUserUid = await Spdb.getUid();
    setState(() {});
  }

  void _refreshFeed() {
    context.read<FeedBloc>().add(RefreshFeeds());
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 900;
    final crossAxisCount = isDesktop
        ? 3
        : 2; // Pro dashboard often uses 3 on wide screens

    return Scaffold(
      backgroundColor: FeedAppColors.background,
      appBar: AppBar(
        leading: kIsMobile ? Back(color: FeedAppColors.textPrimary) : null,
        backgroundColor: FeedAppColors.white,
        elevation: 0,
        centerTitle: false,
        title: const Text(
          "Community Feed",
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: FeedAppColors.textPrimary,
            fontSize: 18,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Iconsax.refresh,
              color: FeedAppColors.primary,
              size: 20,
            ),
            onPressed: _refreshFeed,
          ),
          const SizedBox(width: 8),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: FeedAppColors.border, height: 1),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: FeedAppColors.primary,
        elevation: 4,
        onPressed: () {
          if (kIsMobile) {
            Sheet.showSheet(context, widget: const FeedCreate());
          } else {
            GeneralDialog.showRTLSheet(context, const FeedCreate());
          }
        },
        child: const Icon(Iconsax.add, color: Colors.white),
      ),
      body: BlocBuilder<FeedBloc, FeedState>(
        builder: (context, state) {
          if (state is FeedLoading) {
            return const Center(child: WaitingLoading());
          }
          if (state is FeedError) return ErrorDisplay(error: state.message);

          if (state is FeedLoaded) {
            if (state.feeds.isEmpty) {
              return const Center(child: Text("No posts in the stream."));
            }

            return RefreshIndicator(
              onRefresh: () async => _refreshFeed(),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1200),
                  child: GridView.builder(
                    padding: const EdgeInsets.all(12),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio:
                          0.72, // Taller aspect ratio for Instagram-like feel with text
                    ),
                    itemCount: state.feeds.length,
                    itemBuilder: (context, index) {
                      return FeedCard(
                        key: ValueKey(state.feeds[index].uid),
                        feed: state.feeds[index],
                        currentUserUid: _currentUserUid,
                        onRefresh: _refreshFeed,
                      );
                    },
                  ),
                ),
              ),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}

class FeedCard extends StatefulWidget {
  final FeedModel feed;
  final String? currentUserUid;
  final VoidCallback onRefresh;

  const FeedCard({
    super.key,
    required this.feed,
    this.currentUserUid,
    required this.onRefresh,
  });

  @override
  State<FeedCard> createState() => FeedCardState();
}

class FeedCardState extends State<FeedCard> {
  int _currentImageIndex = 0;
  late bool _isLiked;
  late int _likeCount;

  @override
  void initState() {
    super.initState();
    _isLiked = widget.feed.reactions.any(
      (r) => r.userId == widget.currentUserUid,
    );
    _likeCount = widget.feed.reactions.length;
  }

  void _handleLike() {
    if (widget.currentUserUid == null) return;
    setState(() {
      if (_isLiked) {
        _isLiked = false;
        _likeCount--;
      } else {
        _isLiked = true;
        _likeCount++;
      }
    });
    context.read<FeedBloc>().add(
      ToggleLike(feedId: widget.feed.uid!, userId: widget.currentUserUid!),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: FeedAppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: FeedAppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header - Condensed
          Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 14,
                  backgroundColor: FeedAppColors.background,
                  backgroundImage: NetworkImage(
                    widget.feed.authorAvatar.isNotEmpty
                        ? widget.feed.authorAvatar
                        : AppStrings.emptyProfilePhotoUrl,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.feed.authorName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                          color: FeedAppColors.textPrimary,
                        ),
                      ),
                      Text(
                        _formatShortTime(widget.feed.createdAt),
                        style: const TextStyle(
                          color: FeedAppColors.textSecondary,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
                InkWell(
                  onTap: () {
                    if (kIsMobile) {
                      Sheet.showSheet(
                        context,
                        widget: FeedEdit(uid: widget.feed.uid ?? ''),
                      );
                    } else {
                      GeneralDialog.showRTLSheet(
                        context,
                        FeedEdit(uid: widget.feed.uid ?? ''),
                      );
                    }
                  },
                  child: const Icon(
                    Iconsax.more,
                    size: 16,
                    color: FeedAppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),

          // Media Section - Instagram Like
          Expanded(
            child: Stack(
              children: [
                if (widget.feed.mediaImages.isNotEmpty)
                  CarouselSlider(
                    options: CarouselOptions(
                      height: double.infinity,
                      viewportFraction: 1,
                      enableInfiniteScroll: false,
                      onPageChanged: (index, _) =>
                          setState(() => _currentImageIndex = index),
                    ),
                    items: widget.feed.mediaImages
                        .map(
                          (m) => Image.network(
                            m.url,
                            fit: BoxFit.cover,
                            width: double.infinity,
                          ),
                        )
                        .toList(),
                  )
                else if (widget.feed.content.isNotEmpty)
                  Container(
                    width: double.infinity,
                    color: FeedAppColors.background,
                    padding: const EdgeInsets.all(12),
                    alignment: Alignment.center,
                    child: Text(
                      widget.feed.content,
                      maxLines: 5,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 13,
                        height: 1.4,
                        color: FeedAppColors.textPrimary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  )
                else
                  const Center(
                    child: Icon(
                      Iconsax.document_text,
                      color: FeedAppColors.border,
                      size: 40,
                    ),
                  ),

                // Pagination Indicator Overlay
                if (widget.feed.mediaImages.length > 1)
                  Positioned(
                    bottom: 8,
                    left: 0,
                    right: 0,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        widget.feed.mediaImages.length,
                        (index) => Container(
                          width: 4,
                          height: 4,
                          margin: const EdgeInsets.symmetric(horizontal: 2),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _currentImageIndex == index
                                ? Colors.white
                                : Colors.white54,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Lower Content area
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (widget.feed.mediaImages.isNotEmpty &&
                    widget.feed.content.isNotEmpty)
                  Text(
                    widget.feed.content,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      color: FeedAppColors.textPrimary,
                    ),
                  ),
                const SizedBox(height: 6),

                // Interaction Bar
                Row(
                  children: [
                    _interactionIcon(
                      _isLiked ? Iconsax.heart5 : Iconsax.heart,
                      _isLiked ? Colors.red : FeedAppColors.textSecondary,
                      _likeCount > 0 ? _likeCount.toString() : "",
                      _handleLike,
                    ),
                    const SizedBox(width: 12),
                    _interactionIcon(
                      Iconsax.message,
                      FeedAppColors.textSecondary,
                      widget.feed.commentsCount > 0
                          ? widget.feed.commentsCount.toString()
                          : "",
                      () => _showCommentSheet(),
                    ),
                    const Spacer(),
                    const Icon(
                      Iconsax.archive_add,
                      size: 18,
                      color: FeedAppColors.textSecondary,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
        ],
      ),
    );
  }

  Widget _interactionIcon(
    IconData icon,
    Color color,
    String count,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: color),
          if (count.isNotEmpty) ...[
            const SizedBox(width: 4),
            Text(
              count,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: FeedAppColors.textPrimary,
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatShortTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    return '${diff.inDays}d';
  }

  void _showCommentSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.transparent,
      builder: (context) => CommentSheet(
        feedId: widget.feed.uid!,
        currentUserUid: widget.currentUserUid,
        initialComments: widget.feed.comments ?? [],
      ),
    );
  }
}
