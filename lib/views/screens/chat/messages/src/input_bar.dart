part of 'chat_messages.dart';

class ChatInputBar extends StatefulWidget {
  const ChatInputBar({super.key});

  @override
  State<ChatInputBar> createState() => _ChatInputBarState();
}

class _ChatInputBarState extends State<ChatInputBar> {
  final TextEditingController _controller = TextEditingController();
  final List<File> _pickedFiles = [];

  bool get hasText => _controller.text.trim().isNotEmpty;

  Future<void> _pickFiles() async {
    final files = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.custom,
      allowedExtensions: [
        'png', 'jpg', 'jpeg', 'webp', 'bmp', 'gif', 'tiff', // images
        'mp4', 'mov', 'avi', 'mkv', 'webm', // videos
        'mp3', 'wav', 'aac', // audio
        'pdf', 'doc', 'docx', 'xls', 'xlsx', 'ppt', 'pptx', // documents
      ],
    );

    if (files != null && files.files.isNotEmpty) {
      setState(() {
        _pickedFiles.addAll(files.files.map((f) => File(f.path!)));
      });
    }
  }

  void _removeFile(int index) {
    setState(() {
      _pickedFiles.removeAt(index);
    });
  }

  MessageProvider? _messageProvider;
  bool _isReply = false;
  bool _isEdit = false;
  bool _isRecording = false;
  MessagesModel? _chat;
  // String? replyForName;
  // String? replyForAvatar;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _messageProvider = Provider.of<MessageProvider>(context, listen: false);
      _messageProvider?.addListener(_onMessageProviderChange);
    });
  }

  void _onMessageProviderChange() {
    if (!mounted) return;

    setState(() {
      _isReply = _messageProvider?.isReply ?? false;
      _isEdit = _messageProvider?.isEdit ?? false;
      _isRecording = _messageProvider?.isRecording ?? false;
      _chat = _messageProvider?.chat;
    });

    if (_isEdit && _chat != null) {
      // Wait until the widget is ready before updating controller
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _controller.value = TextEditingValue(
          text: _chat?.message ?? '',
          selection: TextSelection.collapsed(
            offset: _chat?.message.length ?? 0,
          ),
        );
      });
    }
  }

  @override
  void dispose() {
    _messageProvider?.removeListener(_onMessageProviderChange);
    _controller.dispose();
    super.dispose();
  }

  Timer? _timer;

  String _formatDuration(int seconds) {
    final duration = Duration(seconds: seconds);
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final secs = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$secs';
  }

  void _startRecording() async {
    var messageProvider = Provider.of<MessageProvider>(context, listen: false);
    messageProvider.startRecording();
    await AudioRecorder.startRecording();
    _startTimer();
  }

  void _stopRecording() async {
    var messageProvider = Provider.of<MessageProvider>(context, listen: false);
    messageProvider.stopRecording();
    var output = await AudioRecorder.stopRecording();
    if (output != null && output.isNotEmpty) {
      _pickedFiles.add(File(output));
    }
    _stopTimer();
    setState(() {});
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {});
    });
  }

  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
  }

  FocusNode focusNode = FocusNode();

  @override
  Widget build(BuildContext context) {
    return KeyboardListener(
      focusNode: focusNode,
      onKeyEvent: (event) {
        if (event is KeyDownEvent &&
            event.logicalKey == LogicalKeyboardKey.enter) {
          _sendMessage();
        }
      },
      child: Column(
        children: [
          if (_isReply) _replyMessage(_chat, context, _messageProvider),
          if (_isEdit) _editMessage(_chat, context, _messageProvider),
          if (_isRecording) _recording(),
          if (_pickedFiles.isNotEmpty) _pickedFilesView(),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.add_circle_outline),
                onPressed: () async {
                  // var result = await Sheet.showSheet(context,
                  //     widget: const PickOption(uploadDoc: true), size: 0.3);
                  // if (result != null) {
                  //   if (result == 1) {
                  //     var image = await PickImage.captureImage();
                  //     if (image != null) {
                  //       _pickedFiles.add(image);
                  //       setState(() {});
                  //     }
                  //   } else if (result == 2) {
                  //     var images = await PickImage.pickMultipleImages();
                  //     if (images.isNotEmpty) {
                  //       _pickedFiles.addAll(images);
                  //       setState(() {});
                  //     }
                  //   } else {
                  var files = await FilePick.pickFiles(context);
                  if (files != null) {
                    if (files.isNotEmpty) {
                      _pickedFiles.addAll(files);
                      setState(() {});
                    }
                  }
                  //   }
                  // }
                },
              ),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppColors.white, AppColors.grey50],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(25),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.black.withValues(alpha: 0.05),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                    border: Border.all(color: AppColors.black45, width: 1.2),
                  ),
                  child: TextField(
                    keyboardType: TextInputType.multiline,
                    textInputAction: TextInputAction.newline,
                    textCapitalization: TextCapitalization.sentences,
                    controller: _controller,
                    minLines: 1,
                    maxLines: 5,
                    onChanged: (value) async {
                      setState(() {});
                      // if (value.isNotEmpty) {
                      //   await ChatService.updateTypingOnChat(
                      //     chatId: uid,
                      //     status: true,
                      //   );
                      // } else {
                      //   await ChatService.updateTypingOnChat(
                      //     chatId: uid,
                      //     status: false,
                      //   );
                      // }
                    },
                    onEditingComplete: () async {
                      // await ChatService.updateTypingOnChat(
                      //   chatId: uid,
                      //   status: false,
                      // );
                    },
                    onTapOutside: (event) async {
                      // await ChatService.updateTypingOnChat(
                      //   chatId: uid,
                      //   status: false,
                      // );
                    },
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 10,
                      ),
                      hintText: "Send a message...",
                      border: InputBorder.none,
                      filled: true,
                      fillColor: AppColors.transparent,
                      suffixIcon: !hasText && _pickedFiles.isEmpty
                          ? IconButton(
                              icon: const Icon(Icons.image_outlined),
                              onPressed: _pickFiles,
                            )
                          : null,
                    ),
                  ),
                ),
              ),
              if (!hasText && _pickedFiles.isEmpty) ...[
                if (kIsMobile) ...[
                  if (!_isRecording) ...[
                    IconButton(
                      icon: const Icon(Icons.mic_rounded),
                      onPressed: _startRecording,
                    ),
                  ] else ...[
                    IconButton(
                      icon: const Icon(Icons.stop_rounded),
                      onPressed: _stopRecording,
                    ),
                  ],
                ],
              ] else
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(
                      Iconsax.send_2,
                      color: AppColors.white,
                      size: 18,
                    ),
                    onPressed: () async => await _sendMessage(),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _sendMessage() async {
    final chatData = ChatData.of(context);
    final uid = chatData.uid;

    var message = _controller.text.trim();

    if (_pickedFiles.isEmpty && message.isEmpty) return;

    if (_pickedFiles.isNotEmpty) {
      futureLoading(context);
    }
    if (_isEdit) {
      await ChatService.editChatMessage(
        uid: uid,
        chatId: _chat?.uid ?? '',
        message: message,
        attachments: _pickedFiles,
      );
    } else {
      await ChatService.sendChatMessage(
        chatId: uid,
        message: message,
        attachments: _pickedFiles,
        replyFor: _isReply ? _chat?.uid : null,
      );
    }
    _messageProvider?.clearMessage();

    if (_pickedFiles.isNotEmpty) {
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }
    }
    _controller.clear();
    _pickedFiles.clear();
    setState(() {});

    ChatService.sendNotification(chatId: uid, message: message, isChat: true);
  }

  final imageExtensions = ["png", "jpg", "jpeg", "webp", "bmp", "gif", "tiff"];
  final videoExtensions = ['mp4', 'mov', 'avi', 'mkv', 'webm'];
  final audioExtensions = ['mp3', 'wav', 'aac'];
  final docExtensions = ['pdf', 'doc', 'docx', 'xls', 'xlsx', 'ppt', 'pptx'];

  Padding _pickedFilesView() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: SizedBox(
        height: 110,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: List.generate(_pickedFiles.length, (index) {
              final file = _pickedFiles[index];
              final ext = file.path.split('.').last.toLowerCase();

              return Stack(
                children: [
                  _buildFilePreview(file, ext),
                  Positioned(
                    top: 2,
                    right: 2,
                    child: GestureDetector(
                      onTap: () => _removeFile(index),
                      child: const CircleAvatar(
                        radius: 12,
                        backgroundColor: Colors.black54,
                        child: Icon(Icons.close, size: 16, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              );
            }),
          ),
        ),
      ),
    );
  }

  Widget _buildFilePreview(File file, String ext) {
    const size = 100.0;

    if (["jpg", "jpeg", "png", "gif", "webp"].contains(ext)) {
      return Container(
        width: size,
        height: size,
        margin: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          image: DecorationImage(image: FileImage(file), fit: BoxFit.cover),
        ),
      );
    }

    if (["mp4", "mov", "avi", "mkv"].contains(ext)) {
      return Container(
        width: size,
        height: size,
        margin: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: Colors.black,
        ),
        child: const Icon(Icons.videocam, color: Colors.white),
      );
    }

    if (["mp3", "aac", "wav", "m4a"].contains(ext)) {
      return Container(
        width: size,
        height: size,
        margin: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: Colors.orange,
        ),
        child: const Icon(Icons.audiotrack, color: Colors.white),
      );
    }

    if (ext == "pdf") {
      return Container(
        width: size,
        height: size,
        margin: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: Colors.red.shade400,
        ),
        child: const Icon(Icons.picture_as_pdf, size: 40, color: Colors.white),
      );
    }

    if (["doc", "docx"].contains(ext)) {
      return _iconPreview(size, Colors.blue, Icons.description, ext);
    }

    if (["xls", "xlsx"].contains(ext)) {
      return _iconPreview(size, Colors.green, Icons.table_chart, ext);
    }

    if (["ppt", "pptx"].contains(ext)) {
      return _iconPreview(size, Colors.deepOrange, Icons.slideshow, ext);
    }

    if (["zip", "rar", "7z"].contains(ext)) {
      return _iconPreview(size, Colors.grey, Icons.archive, ext);
    }

    if (["txt", "csv", "json"].contains(ext)) {
      return _iconPreview(size, Colors.brown, Icons.notes, ext);
    }

    return _iconPreview(size, Colors.black45, Icons.insert_drive_file, ext);
  }

  Widget _iconPreview(double size, Color color, IconData icon, String ext) {
    return Container(
      width: size,
      height: size,
      margin: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: color,
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 32),
            const SizedBox(height: 4),
            Text(
              ext.toUpperCase(),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Padding _replyMessage(
    MessagesModel? chat,
    BuildContext context,
    MessageProvider? messageProvider,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: SizedBox(
        height: 70,
        child: Container(
          decoration: const BoxDecoration(
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(10),
              topRight: Radius.circular(10),
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.black26,
                offset: Offset(0, -3),
                blurRadius: 6,
                spreadRadius: -1,
              ),
            ],
            color: AppColors.white,
          ),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 6,
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
                          ((CacheService.getUserByUid(
                                        chat?.senderId ?? '',
                                      )?.profileImageUrl) !=
                                      null &&
                                  (CacheService.getUserByUid(
                                    chat?.senderId ?? '',
                                  )?.profileImageUrl)!.isNotEmpty)
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(100),
                                  child: CachedNetworkImage(
                                    imageUrl: (CacheService.getUserByUid(
                                      chat?.senderId ?? '',
                                    )?.profileImageUrl)!,
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
                                    height: 20,
                                    width: 20,
                                    fit: BoxFit.cover,
                                  ),
                                )
                              : CircleAvatar(
                                  radius: 8,
                                  backgroundColor: AppColors.grey200,
                                  child:
                                      ((CacheService.getUserByUid(
                                                chat?.senderId ?? '',
                                              )?.profileImageUrl) ==
                                              null ||
                                          (CacheService.getUserByUid(
                                            chat?.senderId ?? '',
                                          )?.profileImageUrl)!.isEmpty)
                                      ? const Icon(Iconsax.user, size: 12)
                                      : null,
                                ),

                          const SizedBox(width: 5),
                          // Name
                          Text(
                            CacheService.getUserByUid(
                                  chat?.senderId ?? '',
                                )?.name ??
                                '',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      // Message with ellipsis
                      SizedBox(
                        width: double.infinity, // Force width constraint
                        child: Text(
                          chat?.message ?? '',
                          style: Theme.of(context).textTheme.bodyMedium!
                              .copyWith(color: AppColors.grey700),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: AppColors.grey),
                  onPressed: () =>
                      setState(() => messageProvider?.clearMessage()),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Padding _editMessage(
    MessagesModel? chat,
    BuildContext context,
    MessageProvider? messageProvider,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: SizedBox(
        height: 70,
        child: Container(
          decoration: const BoxDecoration(
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(10),
              topRight: Radius.circular(10),
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.black26,
                offset: Offset(0, -3),
                blurRadius: 6,
                spreadRadius: -1,
              ),
            ],
            color: AppColors.white,
          ),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 6,
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
                          Text(
                            "You",
                            style: Theme.of(context).textTheme.bodyMedium!
                                .copyWith(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      // Message with ellipsis
                      SizedBox(
                        width: double.infinity, // Force width constraint
                        child: Text(
                          chat?.message ?? '',
                          style: Theme.of(context).textTheme.bodyMedium!
                              .copyWith(color: AppColors.grey700),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: AppColors.grey),
                  onPressed: () =>
                      setState(() => messageProvider?.clearMessage()),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Padding _recording() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: SizedBox(
        height: 70,
        child: Container(
          decoration: const BoxDecoration(
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(10),
              topRight: Radius.circular(10),
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.black26,
                offset: Offset(0, -3),
                blurRadius: 6,
                spreadRadius: -1,
              ),
            ],
            color: AppColors.white,
          ),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 6,
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
                      Text(
                        "Recording Audio",
                        style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      // Timer display
                      SizedBox(
                        width: double.infinity, // Force width constraint
                        child: Text(
                          _formatDuration(_timer?.tick ?? 0),
                          style: Theme.of(context).textTheme.bodyMedium!
                              .copyWith(color: AppColors.grey700),
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
        ),
      ),
    );
  }
}
