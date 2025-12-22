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
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _future = _init();
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
    setState(() => _isLoading = true);

    try {
      final String authorName = _admin?.name ?? _employee?.name ?? 'Unknown';
      final String authorAvatar =
          _admin?.profileImageUrl ?? _employee?.profileImageUrl ?? '';

      final newComment = CommentModel(
        commentId: DateTime.now().millisecondsSinceEpoch.toString(),
        authorId: widget.currentUserUid!,
        authorName: authorName,
        authorAvatar: authorAvatar,
        content: content,
        createdAt: DateTime.now(),
      );

      await FeedService.addComment(feedId: widget.feedId, comment: newComment);
      setState(() {
        _comments.insert(0, newComment);
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      FlushBar.show(context, "Failed to post comment", isSuccess: false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const WaitingLoading();
        } else if (snapshot.hasError) {
          return ErrorDisplay(error: snapshot.error.toString());
        } else {
          return Container(
            height: MediaQuery.of(context).size.height * 0.75,
            decoration: const BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              children: [
                // Drag Handle
                Center(
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 12),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 8,
                  ),
                  child: Row(
                    children: [
                      Text(
                        "Comments",
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: kPrimaryColor,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: kBgColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          "${_comments.length}",
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: kPrimaryColor,
                              ),
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(),

                // Comments List
                Expanded(
                  child: _comments.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Iconsax.message,
                                size: 48,
                                color: Colors.grey.shade300,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                "No comments yet.\nBe the first to start the conversation!",
                                textAlign: TextAlign.center,
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(color: kTextSecondary),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          itemCount: _comments.length,
                          itemBuilder: (context, index) {
                            final comment = _comments[index];
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 20),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  CircleAvatar(
                                    radius: 18,
                                    backgroundColor: kBgColor,
                                    child: ClipOval(
                                      child: Image.network(
                                        comment.authorAvatar.isNotEmpty
                                            ? comment.authorAvatar
                                            : AppStrings.emptyProfilePhotoUrl,
                                        width: 36,
                                        height: 36,
                                        fit: BoxFit.cover,
                                        errorBuilder:
                                            (context, error, stackTrace) {
                                              return Image.network(
                                                PlaceholderImage.fetchImage(
                                                  comment.authorName.first,
                                                ),
                                                width: 36,
                                                height: 36,
                                                fit: BoxFit.cover,
                                              );
                                            },
                                        loadingBuilder:
                                            (context, child, loadingProgress) {
                                              if (loadingProgress == null) {
                                                return child;
                                              }
                                              return const Icon(
                                                Icons.account_circle,
                                                size: 36,
                                              );
                                            },
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: kBgColor,
                                        borderRadius: BorderRadius.only(
                                          topRight: const Radius.circular(16),
                                          bottomLeft: const Radius.circular(16),
                                          bottomRight: const Radius.circular(
                                            16,
                                          ),
                                          topLeft: index == 0
                                              ? const Radius.circular(4)
                                              : const Radius.circular(16),
                                        ),
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                comment.authorName,
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .bodySmall
                                                    ?.copyWith(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: kPrimaryColor,
                                                    ),
                                              ),
                                              Text(
                                                timeago.format(
                                                  comment.createdAt,
                                                  locale: 'en_short',
                                                ),
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .bodySmall
                                                    ?.copyWith(
                                                      color: kTextSecondary,
                                                    ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            comment.content,
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodyMedium
                                                ?.copyWith(
                                                  color: kPrimaryColor,
                                                  height: 1.4,
                                                ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ),

                // Input Area
                Container(
                  padding: EdgeInsets.only(
                    bottom: MediaQuery.of(context).viewInsets.bottom + 16,
                    top: 16,
                    left: 16,
                    right: 16,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        offset: const Offset(0, -4),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _commentController,
                          maxLines: 4,
                          minLines: 1,
                          textCapitalization: TextCapitalization.sentences,
                          decoration: InputDecoration(
                            hintText: "Write a comment...",
                            hintStyle: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: Colors.grey.shade400),
                            filled: true,
                            fillColor: kBgColor,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(24),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        decoration: const BoxDecoration(
                          color: kPrimaryColor,
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: _isLoading
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(
                                  Icons.send_rounded,
                                  color: Colors.white,
                                  size: 20,
                                ),
                          onPressed: _isLoading ? null : _addComment,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }
      },
    );
  }
}
