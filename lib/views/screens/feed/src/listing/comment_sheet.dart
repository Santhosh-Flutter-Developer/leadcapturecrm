part of 'feed_listing.dart';

class CommentSheet extends StatefulWidget {
  final String feedId;
  final String? currentUserUid;
  final List<CommentModel> initialComments;

  const CommentSheet({
    super.key,
    required this.feedId,
    this.currentUserUid,
    required this.initialComments,
  });

  @override
  State<CommentSheet> createState() => CommentSheetState();
}

class CommentSheetState extends State<CommentSheet> {
  final TextEditingController _commentController = TextEditingController();
  late List<CommentModel> _comments;
  late Future _future;
  EmployeeModel? _employee;
  AdminModel? _admin;
  bool _isPosting = false;
  CommentModel? _replyingTo;

  @override
  void initState() {
    super.initState();
    _future = _init();
  }

  void _setReply(CommentModel comment) {
    setState(() {
      _replyingTo = comment;
    });
  }

  void _clearReply() {
    setState(() => _replyingTo = null);
  }

  Future<void> _init() async {
    if (widget.currentUserUid == null) return;
    bool isAdmin = await Spdb.isAdminLoggedIn();
    if (isAdmin) {
      _admin = await AdminService.getAdmin(uid: widget.currentUserUid!);
    } else {
      _employee = await EmployeeService.getEmployee(
        uid: widget.currentUserUid!,
      );
    }
    var feedModel = await FeedService.getFeed(uid: widget.feedId);
    _comments = feedModel.comments ?? [];
    _comments.sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  Future<void> _addComment() async {
    if (_commentController.text.trim().isEmpty ||
        widget.currentUserUid == null) {
      return;
    }
    final content = _commentController.text.trim();
    _commentController.clear();
    setState(() => _isPosting = true);

    try {
      final String authorName = _admin?.name ?? _employee?.name ?? 'Anonymous';
      final String authorAvatar =
          _admin?.profileImageUrl ?? _employee?.profileImageUrl ?? '';

      final newComment = CommentModel(
        commentId: DateTime.now().millisecondsSinceEpoch.toString(),
        authorId: widget.currentUserUid!,
        authorName: authorName,
        authorAvatar: authorAvatar,
        content: content,
        replyToCommentId: _replyingTo?.commentId,
        createdAt: DateTime.now(),
      );

      await FeedService.addComment(feedId: widget.feedId, comment: newComment);
      setState(() {
        _comments.insert(0, newComment);
        _isPosting = false;
        _replyingTo = null;
      });
    } catch (e) {
      setState(() => _isPosting = false);
      if (mounted) {
        FlushBar.show(context, "Failed to post comment", isSuccess: false);
      }
    }
  }

  Future<void> _toggleReaction(CommentModel comment, String emoji) async {
    final uid = widget.currentUserUid!;
    final reactions = Map<String, List<String>>.from(comment.reactions);

    final users = reactions[emoji] ?? [];

    if (users.contains(uid)) {
      users.remove(uid);
    } else {
      users.add(uid);
    }

    if (users.isEmpty) {
      reactions.remove(emoji);
    } else {
      reactions[emoji] = users;
    }

    final updated = comment.copyWith(reactions: reactions);

    setState(() {
      final index = _comments.indexWhere(
        (c) => c.commentId == comment.commentId,
      );
      _comments[index] = updated;
    });

    await FeedService.updateCommentReaction(
      feedId: widget.feedId,
      commentId: comment.commentId,
      reactions: reactions,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: FeedAppColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Header / Drag Handle
          Center(
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: FeedAppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Comments",
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                    color: FeedAppColors.textPrimary,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(
                    Iconsax.close_circle,
                    color: FeedAppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Comments List
          Expanded(
            child: FutureBuilder(
              future: _future,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const WaitingLoading();
                }
                if (_comments.isEmpty) return _buildEmptyState();

                return ListView.separated(
                  padding: const EdgeInsets.all(20),
                  itemCount: _comments.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 24),
                  itemBuilder: (context, index) =>
                      _buildCommentItem(_comments[index]),
                );
              },
            ),
          ),

          if (_replyingTo != null)
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: FeedAppColors.background,
                borderRadius: BorderRadius.circular(12),
                border: Border(
                  left: BorderSide(color: FeedAppColors.primary, width: 4),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _replyingTo!.authorName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: FeedAppColors.primary,
                          ),
                        ),
                        Text(
                          _replyingTo!.content,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: _clearReply,
                  ),
                ],
              ),
            ),
          _buildInputArea(),
        ],
      ),
    );
  }

  Widget _buildCommentItem(CommentModel comment) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 16,
          backgroundColor: FeedAppColors.background,
          backgroundImage: NetworkImage(
            comment.authorAvatar.isNotEmpty
                ? comment.authorAvatar
                : AppStrings.emptyProfilePhotoUrl,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: GestureDetector(
            onDoubleTap: () => _toggleReaction(comment, "❤️"),
            onLongPress: () {
              showModalBottomSheet(
                context: context,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                ),
                builder: (_) => Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ListTile(
                      leading: const Icon(Icons.reply),
                      title: const Text("Reply"),
                      onTap: () {
                        Navigator.pop(context);
                        _setReply(comment);
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.favorite),
                      title: const Text("React ❤️"),
                      onTap: () {
                        Navigator.pop(context);
                        _toggleReaction(comment, "❤️");
                      },
                    ),
                  ],
                ),
              );
            },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      comment.authorName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                        color: FeedAppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      timeago.format(comment.createdAt, locale: 'en_short'),
                      style: const TextStyle(
                        color: FeedAppColors.textSecondary,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                if (comment.replyToCommentId != null)
                  _buildReplyPreview(comment),
                Text(
                  comment.content,
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.4,
                    color: FeedAppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => _toggleReaction(comment, "❤️"),
                      child: Text(
                        "Like",
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: FeedAppColors.textSecondary,
                        ),
                      ),
                    ),
                    SizedBox(width: 16),
                    GestureDetector(
                      onTap: () => _setReply(comment),
                      child: Text(
                        "Reply",
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: FeedAppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
                if (comment.reactions.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Wrap(
                      spacing: 6,
                      children: comment.reactions.entries.map((e) {
                        return GestureDetector(
                          onTap: () => _toggleReaction(comment, e.key),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: FeedAppColors.background,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: FeedAppColors.border),
                            ),
                            child: Text(
                              "${e.key} ${e.value.length}",
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildReplyPreview(CommentModel comment) {
    final replied = _comments.firstWhere(
      (c) => c.commentId == comment.replyToCommentId,
      orElse: () => CommentModel(
        commentId: '',
        authorId: '',
        authorName: 'Deleted',
        authorAvatar: '',
        content: 'Comment not found',
        createdAt: DateTime.now(),
      ),
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: FeedAppColors.background,
        borderRadius: BorderRadius.circular(8),
        border: Border(
          left: BorderSide(color: FeedAppColors.primary, width: 3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            replied.authorName,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 12,
              color: FeedAppColors.primary,
            ),
          ),
          Text(replied.content, maxLines: 1, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      decoration: BoxDecoration(
        color: FeedAppColors.white,
        border: const Border(top: BorderSide(color: FeedAppColors.border)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: TextField(
              controller: _commentController,
              maxLines: 4,
              minLines: 1,
              style: const TextStyle(fontSize: 14),
              decoration: InputDecoration(
                hintText: "Share your thoughts...",
                filled: true,
                fillColor: FeedAppColors.background,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          InkWell(
            onTap: _isPosting ? null : _addComment,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(
                color: FeedAppColors.primary,
                shape: BoxShape.circle,
              ),
              child: _isPosting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(Iconsax.send_1, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Iconsax.slash, size: 48, color: FeedAppColors.border),
          const SizedBox(height: 16),
          const Text(
            "No comments yet",
            style: TextStyle(
              color: FeedAppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
