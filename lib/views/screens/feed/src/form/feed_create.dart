import 'dart:io';
import 'package:flutter/material.dart';
import 'package:mime/mime.dart';
import 'package:path/path.dart' as path;
import '/constants/constants.dart';
import '/services/services.dart';
import '/theme/theme.dart';
import '/utils/utils.dart';
import '/views/views.dart';
import '/models/models.dart';

class FeedCreate extends StatefulWidget {
  const FeedCreate({super.key});

  @override
  State<FeedCreate> createState() => _FeedCreateState();
}

class _FeedCreateState extends State<FeedCreate> {
  final TextEditingController _contentController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  // Media & Attachments State
  final List<File> _selectedMedia = []; // Mock list of file paths/URLs
  final List<File> _selectedFiles = []; // Mock list of file names

  // Poll State
  bool _isPollActive = false;
  final TextEditingController _pollQuestionController = TextEditingController();
  List<TextEditingController> _pollOptionControllers = [];

  late Future _future;
  EmployeeModel? _employee;
  AdminModel? _admin;

  @override
  void initState() {
    super.initState();
    _resetPoll();
    _future = _init();
  }

  Future<void> _init() async {
    var isAdmin = await Spdb.isAdminLoggedIn();
    var uid = await Spdb.getUid();
    if (uid != null) {
      if (isAdmin) {
        _admin = await AdminService.getAdmin(uid: uid);
      } else {
        _employee = await EmployeeService.getEmployee(uid: uid);
      }
    }
    setState(() {});
  }

  void _resetPoll() {
    _pollQuestionController.clear();
    for (var c in _pollOptionControllers) {
      c.dispose();
    }
    _pollOptionControllers = [TextEditingController(), TextEditingController()];
  }

  void _togglePoll() {
    setState(() {
      _isPollActive = !_isPollActive;
      if (!_isPollActive) {
        _resetPoll();
      } else {
        // Scroll to bottom when poll is activated
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        });
      }
    });
  }

  void _addPollOption() {
    if (_pollOptionControllers.length < 5) {
      setState(() {
        _pollOptionControllers.add(TextEditingController());
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Maximum 5 options allowed",
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
      );
    }
  }

  void _removePollOption(int index) {
    if (_pollOptionControllers.length > 2) {
      setState(() {
        final controller = _pollOptionControllers.removeAt(index);
        controller.dispose();
      });
    }
  }

  // Mock function to simulate picking an image
  void _pickImage() async {
    List<File> selectedImages = [];

    if (kIsDesktop) {
      selectedImages =
          await FilePick.pickFileWithExtensions(
            context,
            allowedExtensions: ['jpg', 'png', 'jpeg'],
          ) ??
          [];
    } else {
      selectedImages = await PickImage.pickMultipleImages();
    }
    if (selectedImages.isNotEmpty) {
      _selectedMedia.addAll(selectedImages);
    }
    setState(() {});
  }

  void _pickFile() async {
    List<File> selectedFiles = [];
    selectedFiles = await FilePick.pickFiles(context) ?? [];
    if (selectedFiles.isNotEmpty) {
      _selectedFiles.addAll(selectedFiles);
    }
    setState(() {});
  }

  void _handleSubmit() async {
    try {
      if (_contentController.text.isEmpty &&
          _selectedMedia.isEmpty &&
          !_isPollActive) {
        return;
      }

      futureLoading(context);

      // Construct PollModel if active
      PollModel? poll;
      if (_isPollActive && _pollQuestionController.text.isNotEmpty) {
        List<PollOption> options = [];
        for (int i = 0; i < _pollOptionControllers.length; i++) {
          if (_pollOptionControllers[i].text.isNotEmpty) {
            options.add(
              PollOption(
                optionId: 'opt_$i',
                title: _pollOptionControllers[i].text,
              ),
            );
          }
        }
        if (options.length >= 2) {
          poll = PollModel(
            pollId: 'poll_${DateTime.now().millisecondsSinceEpoch}',
            question: _pollQuestionController.text,
            options: options,
          );
        }
      }

      List<FileModel> mediaImages = [];

      if (_selectedMedia.isNotEmpty) {
        for (var i = 0; i < _selectedMedia.length; i++) {
          var file = _selectedMedia[i];
          var mimeType = lookupMimeType(file.path) ?? '';

          mediaImages.add(
            FileModel(
              name: path.basename(file.path),
              extension: path.extension(file.path).replaceAll('.', ''),
              size: file.lengthSync(),
              url: await StorageService.uploadFile(
                file: _selectedMedia[i],
                folder: StorageFolder.feedAttachments,
              ),
              mimeType: mimeType,
            ),
          );
        }
      }

      List<FileModel> fileUrls = [];

      if (_selectedFiles.isNotEmpty) {
        for (var i = 0; i < _selectedFiles.length; i++) {
          var file = _selectedFiles[i];
          var mimeType = lookupMimeType(file.path) ?? '';

          fileUrls.add(
            FileModel(
              name: path.basename(file.path),
              extension: path.extension(file.path).replaceAll('.', ''),
              size: file.lengthSync(),
              url: await StorageService.uploadFile(
                file: _selectedFiles[i],
                folder: StorageFolder.feedAttachments,
              ),
              mimeType: mimeType,
            ),
          );
        }
      }

      // Construct FeedModel
      final feedModel = FeedModel(
        authorId: _admin?.uid ?? _employee?.uid ?? '',
        authorName: _admin?.name ?? _employee?.name ?? '',
        authorAvatar:
            _admin?.profileImageUrl ?? _employee?.profileImageUrl ?? '',
        content: _contentController.text,
        createdAt: DateTime.now(),
        mediaImages: mediaImages,
        attachments: fileUrls,
        taggedUsers: [],
        reactions: [],
        poll: poll,
      );

      await FeedService.createFeed(feed: feedModel);

      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }

      if (mounted && Navigator.canPop(context)) {
        Navigator.pop(context, true);
      } // Navigator.pop(context, true);

      return;
    } catch (e, st) {
      debugPrint("$e, $st");
      await ErrorService.recordError(e, st);
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }
      FlushBar.show(context, e.toString(), isSuccess: false);
    }
  }

  @override
  void dispose() {
    _contentController.dispose();
    _scrollController.dispose();
    _pollQuestionController.dispose();
    for (var c in _pollOptionControllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        // leading: IconButton(
        //   icon: const Icon(Icons.close, color: kTextPrimary),
        //   onPressed: () {
        //     if (Navigator.canPop(context)) {
        //       Navigator.pop(context);
        //     }
        //   },
        // ),
        title: Text(
          "Create Post",
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: kTextPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16, top: 10, bottom: 10),
            child: ElevatedButton(
              onPressed: _handleSubmit,
              style: ElevatedButton.styleFrom(
                backgroundColor: FeedAppColors.primary,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 24),
              ),
              child: Text(
                "Post",
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.white,
                ),
              ),
            ),
          ),
        ],
      ),

      body: FutureBuilder(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const WaitingLoading();
          } else if (snapshot.hasError) {
            return ErrorDisplay(error: snapshot.error.toString());
          } else {
            return Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 22,
                              backgroundImage: NetworkImage(
                                _admin?.profileImageUrl ??
                                    _employee?.profileImageUrl ??
                                    AppStrings.emptyProfilePhotoUrl,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              _admin?.name ?? _employee?.name ?? 'N/A',
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: kTextPrimary,
                                  ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 20),

                        // Main Content Input
                        TextField(
                          controller: _contentController,
                          maxLines: null,
                          decoration: InputDecoration(
                            hintText: "What's on your mind?",
                            border: InputBorder.none,
                            hintStyle: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: kTextSecondary),
                          ),
                          style: Theme.of(
                            context,
                          ).textTheme.bodyMedium?.copyWith(color: kTextPrimary),
                        ),

                        const SizedBox(height: 20),

                        // Selected Media Grid
                        if (_selectedMedia.isNotEmpty)
                          Container(
                            height: 200,
                            margin: const EdgeInsets.only(bottom: 20),
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              itemCount: _selectedMedia.length,
                              separatorBuilder: (_, _) =>
                                  const SizedBox(width: 10),
                              itemBuilder: (context, index) {
                                return Stack(
                                  children: [
                                    Container(
                                      width: 200,
                                      decoration: BoxDecoration(
                                        color: AppColors.grey200,
                                        borderRadius: BorderRadius.circular(12),
                                        image: DecorationImage(
                                          image: FileImage(
                                            _selectedMedia[index],
                                          ),
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      top: 8,
                                      right: 8,
                                      child: GestureDetector(
                                        onTap: () {
                                          setState(() {
                                            _selectedMedia.removeAt(index);
                                          });
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.all(4),
                                          decoration: BoxDecoration(
                                            color: Colors.black.withValues(
                                              alpha: 0.5,
                                            ),
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(
                                            Icons.close,
                                            size: 16,
                                            color: AppColors.white,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                          ),

                        // Selected Files List
                        if (_selectedFiles.isNotEmpty)
                          ..._selectedFiles.map(
                            (file) => Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: kBgColor,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppColors.grey200),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.description,
                                    color: FeedAppColors.primary,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      path.basename(file.path),
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                            fontWeight: FontWeight.w500,
                                            color: kTextPrimary,
                                          ),
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.close,
                                      color: kTextSecondary,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _selectedFiles.remove(file);
                                      });
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ),

                        // Poll Creation Section
                        if (_isPollActive) _buildPollCreator(),
                      ],
                    ),
                  ),
                ),

                // Bottom Toolbar
                _buildBottomToolbar(context),
              ],
            );
          }
        },
      ),
    );
  }

  Widget _buildPollCreator() {
    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kBgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Create Poll",
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: kTextPrimary,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: kTextSecondary),
                onPressed: _togglePoll,
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _pollQuestionController,
            decoration: InputDecoration(
              hintText: "Ask a question...",
              fillColor: AppColors.white,
              filled: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
            ),
          ),
          const SizedBox(height: 16),
          ...List.generate(_pollOptionControllers.length, (index) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _pollOptionControllers[index],
                      decoration: InputDecoration(
                        hintText: "Option ${index + 1}",
                        fillColor: AppColors.white,
                        filled: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                      ),
                    ),
                  ),
                  if (_pollOptionControllers.length > 2)
                    IconButton(
                      icon: const Icon(
                        Icons.remove_circle_outline,
                        color: Colors.red,
                      ),
                      onPressed: () => _removePollOption(index),
                    ),
                ],
              ),
            );
          }),
          if (_pollOptionControllers.length < 5)
            TextButton.icon(
              onPressed: _addPollOption,
              icon: const Icon(Icons.add, size: 18),
              label: Text(
                "Add Option",
                style: Theme.of(context).textTheme.bodySmall,
              ),
              style: TextButton.styleFrom(
                foregroundColor: FeedAppColors.primary,
                padding: EdgeInsets.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBottomToolbar(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).padding.bottom + 10,
        top: 10,
        left: 20,
        right: 20,
      ),
      decoration: BoxDecoration(
        color: AppColors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            offset: const Offset(0, -4),
            blurRadius: 10,
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            "Add to your post",
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: kTextSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          Row(
            children: [
              _ToolbarIcon(
                icon: Icons.image_outlined,
                color: Colors.green,
                onTap: _pickImage,
              ),
              const SizedBox(width: 16),
              _ToolbarIcon(
                icon: Icons.attach_file,
                color: Colors.blue,
                onTap: _pickFile,
              ),
              const SizedBox(width: 16),
              _ToolbarIcon(
                icon: Icons.poll_outlined,
                color: Colors.orange,
                onTap: _isPollActive ? null : _togglePoll,
                isActive: _isPollActive,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ToolbarIcon extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;
  final bool isActive;

  const _ToolbarIcon({
    required this.icon,
    required this.color,
    this.onTap,
    this.isActive = false,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(
        icon,
        color: isActive ? color : color.withValues(alpha: 0.8),
        size: 24,
      ),
      onPressed: onTap,
    );
  }
}
