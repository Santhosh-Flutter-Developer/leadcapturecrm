part of 'chat_messages.dart';

// --- UTILITY WIDGETS (Unchanged, but kept in file) ---

/// Renders markdown-formatted text.
class MarkdownText extends StatelessWidget {
  final String message;

  const MarkdownText({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return MarkdownBody(
      data: message,
      onTapLink: (text, href, title) {
        if (href != null) {
          launchUrl(Uri.parse(href));
        }
      },
      styleSheet: MarkdownStyleSheet(
        p: Theme.of(context).textTheme.bodyMedium,
        a: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: AppColors.blue,
          // decoration: TextDecoration.underline,
        ),
        code: Theme.of(
          context,
        ).textTheme.bodySmall?.copyWith(fontFamily: 'Manrope'),
        strong: Theme.of(
          context,
        ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold),
        em: Theme.of(
          context,
        ).textTheme.bodySmall?.copyWith(fontStyle: FontStyle.italic),
        blockquote: Theme.of(context).textTheme.bodySmall?.copyWith(
          fontStyle: FontStyle.italic,
          color: AppColors.grey,
        ),
      ),
    );
  }
}

/// Renders a preview for a URL.
class UrlPreview extends StatelessWidget {
  final String url;
  final bool isSender;
  const UrlPreview({super.key, required this.url, required this.isSender});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 300),
      margin: EdgeInsets.only(
        left: isSender ? 40 : 0,
        right: isSender ? 0 : 40,
      ),
      child: Padding(
        padding: const EdgeInsets.only(top: 6),
        child: AnyLinkPreview(
          link: url,
          displayDirection: UIDirection.uiDirectionHorizontal,
          showMultimedia: true,
          bodyMaxLines: 5,
          bodyTextOverflow: TextOverflow.ellipsis,
          titleStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: AppColors.black,
            fontWeight: FontWeight.bold,
          ),
          bodyStyle: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: AppColors.grey),
          cache: const Duration(days: 7),
          backgroundColor: AppColors.white,
          borderRadius: 12,
          removeElevation: false,
          boxShadow: const [BoxShadow(blurRadius: 3, color: AppColors.grey)],
          onTap: () => launchUrl(Uri.parse(url)),
        ),
      ),
    );
  }
}

/// Renders a preview for file attachments (images, videos, audio, etc.).
class AttachmentPreview extends StatelessWidget {
  final List<FileModel> attachments;
  const AttachmentPreview({super.key, required this.attachments});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 300),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: attachments.map((e) {
            if (e.mimeType.contains('image')) {
              return GestureDetector(
                onTap: () {
                  final imageAttachments = attachments
                      .where((a) => a.mimeType.contains('image'))
                      .toList();
                  final initialIndex = imageAttachments.indexOf(e);

                  Navigate.route(
                    context,
                    GalleryScreen(
                      images: imageAttachments,
                      initialIndex: initialIndex,
                    ),
                  );
                },
                child: Container(
                  width: 100,
                  height: 100,
                  margin: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 4,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: CachedNetworkImage(
                      imageUrl: e.url,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Shimmer.fromColors(
                        baseColor: AppColors.grey300,
                        highlightColor: AppColors.grey100,
                        child: Container(color: AppColors.white),
                      ),
                      errorWidget: (context, url, error) =>
                          const Icon(Icons.error),
                    ),
                  ),
                ),
              );
            } else {
              return Stack(
                children: [
                  GestureDetector(
                    onTap: () {
                      if (e.mimeType.contains('audio')) {
                        Navigate.route(context, AudioPlay(file: e));
                      } else if (e.mimeType.contains('video')) {
                        Navigate.route(context, VideoPlay(file: e));
                      }
                    },
                    child: Container(
                      width: 100,
                      height: 100,
                      margin: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        color: AppColors.grey200,
                      ),
                      child: Center(
                        child: Text(
                          e.extension,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: e.extension.getColorForFile,
                              ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: IconButton(
                      tooltip: "Download",
                      icon: Container(
                        padding: const EdgeInsets.all(5),
                        decoration: const BoxDecoration(
                          color: AppColors.white,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Iconsax.document_download,
                          size: 18,
                          color: AppColors.primary,
                        ),
                      ),
                      onPressed: () =>
                          Download.downloadFromUrl(context, e.url, e.name),
                    ),
                  ),
                ],
              );
            }
          }).toList(),
        ),
      ),
    );
  }
}

/// A tile that displays the content of a message being replied to.
class ReplyTile extends StatefulWidget {
  final MessagesModel? message;
  const ReplyTile({super.key, this.message});

  @override
  State<ReplyTile> createState() => _ReplyTileState();
}

class _ReplyTileState extends State<ReplyTile> {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: SizedBox(
        height: 50,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 5,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      // Avatar
                      ClipRRect(
                        borderRadius: BorderRadius.circular(100),
                        child: CachedNetworkImage(
                          imageUrl:
                              CacheService.getUserByUid(
                                        widget.message?.senderId ?? '',
                                      )?.profileImageUrl !=
                                      null &&
                                  (CacheService.getUserByUid(
                                    widget.message?.senderId ?? '',
                                  )?.profileImageUrl)!.isNotEmpty
                              ? (CacheService.getUserByUid(
                                  widget.message?.senderId ?? '',
                                )?.profileImageUrl)!
                              : AppStrings.emptyProfilePhotoUrl,
                          placeholder: (context, url) => Shimmer.fromColors(
                            baseColor: AppColors.grey300,
                            highlightColor: AppColors.grey100,
                            child: Container(color: AppColors.white),
                          ),
                          errorWidget: (context, url, error) =>
                              const Icon(Icons.error),
                          height: 20,
                          width: 20,
                          fit: BoxFit.cover,
                        ),
                      ),

                      const SizedBox(width: 5),
                      // Name
                      Text(
                        CacheService.getUserByUid(
                              widget.message?.senderId ?? '',
                            )?.name ??
                            '',
                        style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 4),
                  // Message with ellipsis
                  SizedBox(
                    width: double.infinity, // Force width constraint
                    child: Text(
                      widget.message?.message ?? '',
                      style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                        color: AppColors.grey700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A full-screen audio player.
class AudioPlay extends StatefulWidget {
  final FileModel file;

  const AudioPlay({super.key, required this.file});

  @override
  State<AudioPlay> createState() => _AudioPlayState();
}

class _AudioPlayState extends State<AudioPlay> {
  late AudioPlayer _player;
  bool isPlaying = false;

  @override
  void initState() {
    super.initState();
    _player = AudioPlayer();
    if (widget.file.mimeType.contains('audio')) {
      _initializePlayer();
    }
  }

  Future<void> _initializePlayer() async {
    try {
      await _player.setUrl(widget.file.url);
    } catch (e, st) {
      await ErrorService.recordError(e, st);
      debugPrint("${e.toString()}, ${st.toString()}");
      FlushBar.show(
        context,
        e.toString(),
        isSuccess: false,
        error: e,
        stackTrace: st,
      );
    }
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  void _togglePlayPause() {
    setState(() {
      isPlaying = !isPlaying;
    });
    if (isPlaying) {
      _player.play();
    } else {
      _player.pause();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.black,
      body: Stack(
        children: [
          if (widget.file.mimeType.contains('audio'))
            Center(
              child: Row(
                children: [
                  IconButton(
                    iconSize: 24, // smaller size
                    padding: EdgeInsets.zero, // no extra padding
                    constraints:
                        const BoxConstraints(), // remove default button constraints
                    color: AppColors.white,
                    icon: Icon(isPlaying ? Icons.pause : Icons.play_arrow),
                    onPressed: _togglePlayPause,
                  ),
                  Expanded(
                    child: StreamBuilder<Duration>(
                      stream: _player.positionStream,
                      builder: (context, snapshot) {
                        final position = snapshot.data ?? Duration.zero;
                        final total = _player.duration ?? Duration.zero;
                        final totalSeconds = total.inSeconds > 0
                            ? total.inSeconds
                            : 1;

                        return Row(
                          children: [
                            Expanded(
                              child: SliderTheme(
                                data: SliderTheme.of(context).copyWith(
                                  trackHeight: 2.5, // thinner track
                                  thumbShape: const RoundSliderThumbShape(
                                    enabledThumbRadius: 6,
                                  ), // smaller thumb
                                  overlayShape: const RoundSliderOverlayShape(
                                    overlayRadius: 12,
                                  ), // small touch ripple
                                ),
                                child: Slider(
                                  value: position.inSeconds
                                      .clamp(0, totalSeconds)
                                      .toDouble(),
                                  max: totalSeconds.toDouble(),
                                  onChanged: (value) {
                                    _player.seek(
                                      Duration(seconds: value.toInt()),
                                    );
                                  },
                                  activeColor: AppColors.white,
                                  inactiveColor: AppColors.grey,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              "${position.inMinutes}:${(position.inSeconds % 60).toString().padLeft(2, '0')}",
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(color: AppColors.white),
                            ),
                            Text(
                              " / ${total.inMinutes}:${(total.inSeconds % 60).toString().padLeft(2, '0')}",
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(color: AppColors.grey),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            left: 0,
            right: 0, // <-- add this to make the Row take full width
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(
                          Iconsax.close_circle,
                          color: AppColors.white,
                        ),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      const SizedBox(width: 5),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.file.name,
                            style: Theme.of(context).textTheme.bodyMedium!
                                .copyWith(color: AppColors.white),
                          ),
                          Text(
                            "${(widget.file.size / 1000000).toStringAsFixed(2)} MB",
                            style: Theme.of(context).textTheme.bodySmall!
                                .copyWith(color: AppColors.white),
                          ),
                        ],
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.file_download_outlined,
                      color: AppColors.white,
                    ),
                    onPressed: () async {
                      futureLoading(context);
                      await Download.downloadFromUrl(
                        context,
                        widget.file.url,
                        widget.file.name,
                      );
                      if (Navigator.canPop(context)) {
                        Navigator.pop(context);
                      }
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
}

/// A full-screen video player.
class VideoPlay extends StatefulWidget {
  final FileModel file;
  const VideoPlay({super.key, required this.file});

  @override
  State<VideoPlay> createState() => _VideoPlayState();
}

class _VideoPlayState extends State<VideoPlay> {
  late VideoPlayerController _controller;
  // ignore: unused_field
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.file.url))
      ..initialize().then((_) {
        setState(() {});
      });
    _controller.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _togglePlayPause() {
    if (_controller.value.isPlaying) {
      _controller.pause();
    } else {
      _controller.play();
    }
    setState(() {
      _isPlaying = _controller.value.isPlaying;
    });
  }

  String _formatTime(Duration duration) {
    return "${duration.inMinutes}:${(duration.inSeconds % 60).toString().padLeft(2, '0')}";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.black,
      body: Stack(
        children: [
          _controller.value.isInitialized
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      AspectRatio(
                        aspectRatio: _controller.value.aspectRatio,
                        child: VideoPlayer(_controller),
                      ),
                      const SizedBox(height: 10),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: Row(
                          children: [
                            IconButton(
                              iconSize: 20,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              color: AppColors.white,
                              icon: Icon(
                                _controller.value.isPlaying
                                    ? Icons.pause
                                    : Icons.play_arrow,
                              ),
                              onPressed: _togglePlayPause,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: SliderTheme(
                                data: SliderTheme.of(context).copyWith(
                                  trackHeight: 2.5,
                                  thumbShape: const RoundSliderThumbShape(
                                    enabledThumbRadius: 6,
                                  ),
                                  overlayShape: const RoundSliderOverlayShape(
                                    overlayRadius: 12,
                                  ),
                                ),
                                child: Slider(
                                  value: _controller.value.position.inSeconds
                                      .toDouble()
                                      .clamp(
                                        0.0,
                                        _controller.value.duration.inSeconds
                                            .toDouble(),
                                      ),
                                  max: _controller.value.duration.inSeconds
                                      .toDouble(),
                                  onChanged: (value) {
                                    _controller.seekTo(
                                      Duration(seconds: value.toInt()),
                                    );
                                  },
                                  activeColor: AppColors.white,
                                  inactiveColor: AppColors.grey,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              "${_formatTime(_controller.value.position)} / ${_formatTime(_controller.value.duration)}",
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(color: AppColors.white),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                )
              : const WaitingLoading(),
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            left: 0,
            right: 0,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(
                          Iconsax.close_circle,
                          color: AppColors.white,
                        ),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      const SizedBox(width: 5),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.file.name,
                            style: Theme.of(context).textTheme.bodyMedium!
                                .copyWith(color: AppColors.white),
                          ),
                          Text(
                            "${(widget.file.size / 1000000).toStringAsFixed(2)} MB",
                            style: Theme.of(context).textTheme.bodySmall!
                                .copyWith(color: AppColors.white),
                          ),
                        ],
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.file_download_outlined,
                      color: AppColors.white,
                    ),
                    onPressed: () async {
                      futureLoading(context);
                      await Download.downloadFromUrl(
                        context,
                        widget.file.url,
                        widget.file.name,
                      );
                      if (Navigator.canPop(context)) {
                        Navigator.pop(context);
                      }
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
}
