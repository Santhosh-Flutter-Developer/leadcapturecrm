import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:iconsax/iconsax.dart';
import 'package:timeago/timeago.dart' as timeago;
import '/views/views.dart';
import '/models/models.dart';
import '/constants/constants.dart';
import '/services/services.dart';
import '/theme/theme.dart';
import '/utils/utils.dart';

part 'comment_sheet.dart';

// --- Theme Constants ---
const Color kFBgColor = Color(0xFFF0F4F8);
const Color _kCardColor = AppColors.white;
const Color _kTextPrimary = Color(0xFF1B2559);
const Color kFTextSecondary = Color(0xFF8F9BB3);
const Color kPrimaryColor = AppColors.primary;
const double _kBorderRadius = 18.0;

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
    // Determine if the screen is wide (desktop/tablet)
    final isDesktop = MediaQuery.of(context).size.width > 768;

    return Scaffold(
      backgroundColor: kFBgColor,
      appBar: AppBar(
        backgroundColor: kFBgColor,
        elevation: 0,
        title: Text(
          "Community Feed",
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: _kTextPrimary,
            fontWeight: FontWeight.bold,
            fontSize: isDesktop ? 28 : 24, // Larger title for desktop
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Iconsax.refresh, color: _kTextPrimary),
            onPressed: _refreshFeed,
          ),
          const SizedBox(width: 8),
        ],
      ),

      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: kPrimaryColor,
        icon: const Icon(Icons.edit, color: Colors.white),
        label: Text(
          "New Post",
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        onPressed: () async {
          _refreshFeed();
        },
      ),

      body: BlocBuilder<FeedBloc, FeedState>(
        builder: (context, state) {
          // --- Mock State Handling for Demo ---
          List<FeedModel> feeds = [];
          bool isLoading = false;
          String? errorMessage;

          if (state is FeedLoading) {
            isLoading = true;
          } else if (state is FeedError) {
            errorMessage = state.message;
          } else if (state is FeedLoaded) {
            feeds = state.feeds;
          }
          // End Mock State Handling

          if (isLoading) {
            return WaitingLoading();
          }

          if (errorMessage != null) {
            return ErrorDisplay(error: errorMessage);
          }

          if (feeds.isEmpty) {
            return const Center(child: Text("No posts yet. Be the first!"));
          }

          // --- Desktop/Mobile Layout Handling ---
          Widget feedList = RefreshIndicator(
            onRefresh: () async => _refreshFeed(),
            child: ListView.separated(
              padding: EdgeInsets.fromLTRB(
                isDesktop ? 0 : 16,
                16,
                isDesktop ? 0 : 16,
                100,
              ),
              itemCount: feeds.length,
              separatorBuilder: (context, index) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                return FeedCard(
                  key: ValueKey(feeds[index].uid),
                  feed: feeds[index],
                  currentUserUid: _currentUserUid,
                  onRefresh: _refreshFeed,
                );
              },
            ),
          );

          // Center the list on desktop and constrain its width
          if (isDesktop) {
            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: 800,
                ), // Optimal reading width for desktop
                child: feedList,
              ),
            );
          }

          return feedList;
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

  @override
  void didUpdateWidget(covariant FeedCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.feed != widget.feed) {
      setState(() {
        _isLiked = widget.feed.reactions.any(
          (r) => r.userId == widget.currentUserUid,
        );
        _likeCount = widget.feed.reactions.length;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAuthor = widget.currentUserUid == widget.feed.authorId;

    return Container(
      decoration: BoxDecoration(
        color: _kCardColor,
        borderRadius: BorderRadius.circular(_kBorderRadius),
        border: Border.all(
          color: Colors.grey.shade100,
          width: 1,
        ), // Subtle border
        boxShadow: [
          BoxShadow(
            color: _kTextPrimary.withValues(
              alpha: 0.05,
            ), // Lighter, wider shadow
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(
              20,
              16,
              16,
              8,
            ), // Adjusted padding
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20, // Slightly larger avatar
                  backgroundColor: kFBgColor,
                  child: ClipOval(
                    child: Image.network(
                      widget.feed.authorAvatar.isNotEmpty
                          ? widget.feed.authorAvatar
                          : AppStrings.emptyProfilePhotoUrl,
                      width: 40,
                      height: 40,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Image.network(
                          PlaceholderImage.fetchImage(
                            widget.feed.authorName.isNotEmpty
                                ? widget.feed.authorName.substring(0, 1)
                                : 'U',
                          ),
                          width: 40,
                          height: 40,
                          fit: BoxFit.cover,
                        );
                      },
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) {
                          return child;
                        }
                        return const Icon(
                          Iconsax.user,
                          size: 24,
                          color: kFTextSecondary,
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.feed.authorName,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: _kTextPrimary,
                        ),
                      ),
                      Text(
                        timeago.format(widget.feed.createdAt),
                        style: Theme.of(
                          context,
                        ).textTheme.bodySmall?.copyWith(color: kFTextSecondary),
                      ),
                    ],
                  ),
                ),
                if (isAuthor)
                  PopupMenuButton<String>(
                    icon: const Icon(
                      Iconsax.more,
                      color: kFTextSecondary,
                      size: 20,
                    ), // Use Iconsax more icon
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    // ... Pop up menu logic remains the same ...
                    onSelected: (value) async {
                      if (value == 'edit') {
                        // ... navigation logic ...
                      } else if (value == 'delete') {
                        // ... deletion logic ...
                      }
                      widget.onRefresh();
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Iconsax.edit, size: 18, color: _kTextPrimary),
                            SizedBox(width: 8),
                            Text(
                              "Edit Post",
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(color: _kTextPrimary),
                            ),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Iconsax.trash, color: Colors.red, size: 18),
                            SizedBox(width: 8),
                            Text(
                              "Delete",
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(color: Colors.red),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),

          // Content
          if (widget.feed.content.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Text(
                widget.feed.content,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: _kTextPrimary,
                  height: 1.6,
                ),
              ),
            ),

          const SizedBox(height: 12),

          // Files
          if (widget.feed.attachments.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ...widget.feed.attachments.map(
                    (file) => _buildFileTile(file),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 12),

          // Images
          if (widget.feed.mediaImages.isNotEmpty)
            Column(
              children: [
                CarouselSlider(
                  options: CarouselOptions(
                    height: 300,
                    viewportFraction: 1,
                    enableInfiniteScroll: false,
                    enlargeCenterPage: false,
                    onPageChanged: (index, reason) {
                      setState(() => _currentImageIndex = index);
                    },
                  ),
                  items: widget.feed.mediaImages.map((media) {
                    return GestureDetector(
                      onTap: () {
                        // ... existing gallery navigation logic ...
                      },
                      child: Container(
                        color: Colors.grey.shade100,
                        width: MediaQuery.of(context).size.width,
                        child: Image.network(
                          media.url,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: Colors.grey.shade200,
                              alignment: Alignment.center,
                              child: const Icon(
                                Iconsax.gallery_slash,
                                size: 40,
                                color: kFTextSecondary,
                              ),
                            );
                          },
                        ),
                      ),
                    );
                  }).toList(),
                ),

                // Indicators
                if (widget.feed.mediaImages.length > 1)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        widget.feed.mediaImages.length,
                        (index) => AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          width: _currentImageIndex == index
                              ? 20
                              : 8, // Animated width change
                          height: 8,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(4),
                            color: _currentImageIndex == index
                                ? kPrimaryColor
                                : Colors.grey.shade300,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),

          // Poll
          if (widget.feed.poll != null)
            _buildPoll(widget.feed.poll!, widget.feed.uid ?? ''),

          const SizedBox(height: 12),
          const Divider(
            height: 1,
            color: Color(0xFFE5E7EB),
            thickness: 1,
          ), // Lighter divider
          // Actions
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 8,
              vertical: 0,
            ), // Removed vertical padding from card level
            child: Row(
              children: [
                ActionButton(
                  icon: _isLiked ? Iconsax.heart5 : Iconsax.heart,
                  label: _likeCount > 0 ? "$_likeCount" : "Like",
                  color: _isLiked
                      ? Colors.red.shade600
                      : kFTextSecondary, // Stronger red
                  onTap: _handleLike,
                ),

                ActionButton(
                  icon: Iconsax.message,
                  label: widget.feed.commentsCount > 0
                      ? "${widget.feed.commentsCount}"
                      : "Comment",
                  onTap: _showCommentSheet,
                  color: kFTextSecondary, // Consistent secondary color
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFileTile(FileModel file) {
    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(14), // Increased padding
      decoration: BoxDecoration(
        color: kFBgColor,
        borderRadius: BorderRadius.circular(14), // Slightly more rounded
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: kPrimaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Iconsax.document_text, // More modern icon
              color: kPrimaryColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  file.name,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: _kTextPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  "${file.extension.toUpperCase()} File",
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: kFTextSecondary),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(
              Iconsax.arrow_circle_down, // More modern download icon
              color: kPrimaryColor,
            ),
            onPressed: () async {
              // await Download.downloadFromUrl(context, file.url, file.name);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPoll(PollModel poll, String feedId) {
    int totalVotes = poll.options.fold(0, (sum, item) => sum + item.votes);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            poll.question,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: _kTextPrimary,
            ),
          ),
          const SizedBox(height: 16),

          ...poll.options.map((option) {
            double percent = totalVotes == 0 ? 0 : option.votes / totalVotes;

            return GestureDetector(
              onTap: () async {
                await FeedService.votePoll(
                  feedId: feedId,
                  optionId: option.optionId,
                );
                setState(() {});
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.only(bottom: 12),
                height: 48, // Taller poll bar
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                  color: _kCardColor,
                ),
                child: Stack(
                  children: [
                    // --- Animated Progress Bar with Gradient ---
                    FractionallySizedBox(
                      widthFactor: percent,
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          gradient: LinearGradient(
                            colors: [
                              kPrimaryColor.withValues(alpha: 0.1),
                              kPrimaryColor.withValues(alpha: 0.25),
                            ],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                        ),
                      ),
                    ),

                    // --- Text Content Layer ---
                    Positioned.fill(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Flexible(
                              child: Text(
                                option.title,
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(
                                      color: _kTextPrimary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Text(
                              "${(percent * 100).toStringAsFixed(0)}%",
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color: kPrimaryColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),

          Align(
            alignment: Alignment.centerRight,
            child: Text(
              "$totalVotes votes • Poll ends soon", // Added extra info
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: kFTextSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const ActionButton({
    super.key,
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Material(
        color: AppColors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          // Added a slight horizontal margin to separate buttons visually
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: color, size: 22),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
