import 'package:flutter/material.dart';
import '../../../../constants/constants.dart';
import '/models/models.dart';
import '/services/services.dart';
import '/theme/theme.dart';
import '/utils/utils.dart';
import '/views/views.dart';

class TaskView extends StatefulWidget {
  final String uid;
  const TaskView({super.key, required this.uid});

  @override
  State<TaskView> createState() => _TaskViewState();
}

class _TaskViewState extends State<TaskView> {
  late Future<TaskModel> _future;
  late TaskModel _taskModel;
  List<TaskCommentModel>? cachedComments;
  List<TaskHistoryModel>? cachedHistory;
  int _commentCount = 0;
  String? currentUid;
  final TextEditingController _commentController = TextEditingController();

  bool _isSending = false;
  bool isParticipant = false;
  bool _isActionLoading = false;

  @override
  void initState() {
    super.initState();
    _future = TaskService.getTask(uid: widget.uid);

    Spdb.getUid().then((uid) {
      setState(() => currentUid = uid);
    });
  }

  Future<void> _addComment(String taskId) async {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;

    setState(() => _isSending = true);

    try {
      await TaskService.addComment(taskId: taskId, comment: text);
      _commentController.clear();
    } catch (e) {
      debugPrint("Failed to add comment: $e");

      FlushBar.show(context, 'Failed to add comment', isSuccess: false);
    }

    setState(() => _isSending = false);
  }

  Future<void> _startTask() async {
    if (_taskModel.uid == null) return;

    setState(() => _isActionLoading = true);

    try {
      await TaskService.startTask(taskId: _taskModel.uid!);

      setState(() {
        _taskModel.hasStarted = true;
        _taskModel.completed = false;
      });

      FlushBar.show(context, "Task started", isSuccess: true);
    } catch (e) {
      debugPrint("Start task failed: $e");
      FlushBar.show(context, "Failed to start task", isSuccess: false);
    } finally {
      setState(() => _isActionLoading = false);
    }
  }

  Future<void> _completeTask() async {
    if (_taskModel.uid == null) return;

    setState(() => _isActionLoading = true);

    try {
      await TaskService.completeTask(taskId: _taskModel.uid!);

      setState(() {
        _taskModel.completed = true;
        // _taskModel.hasStarted = false;
      });

      FlushBar.show(context, "Task marked completed", isSuccess: true);
    } catch (e) {
      debugPrint("Complete task failed: $e");
      FlushBar.show(context, "Failed to complete task", isSuccess: false);
    } finally {
      setState(() => _isActionLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: Spdb.getCid(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const WaitingLoading();
        }

        if (snapshot.hasError || !snapshot.hasData) {
          return ErrorDisplay(
            error: snapshot.error?.toString() ?? "Unable to fetch company ID",
          );
        }

        final String cid = snapshot.data!;
        final String taskId = widget.uid;

        return ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(16),
            bottomLeft: Radius.circular(16),
          ),
          child: FutureBuilder<TaskModel>(
            future: _future,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const WaitingLoading();
              } else if (snapshot.hasError || !snapshot.hasData) {
                return ErrorDisplay(
                  error: snapshot.error?.toString() ?? "Task not found",
                );
              }

              _taskModel = snapshot.data!;
              isParticipant =
                  currentUid != null &&
                  (_taskModel.assignees.contains(currentUid!) ||
                      _taskModel.createdBy.contains(currentUid!));

              return Scaffold(
                backgroundColor: const Color(0xFFF8F9FA),
                appBar: FormWidgets.buildHeader(
                  context: context,
                  title: "Task Details",
                ),
                body: LayoutBuilder(
                  builder: (context, constraints) {
                    if (kIsMobile) {
                      return ListView(
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              children: [
                                _sectionCard(child: _taskHeader()),
                                const SizedBox(height: 18),
                                _sectionCard(child: _statusSummary()),
                                const SizedBox(height: 18),
                                _sectionCard(
                                  color: AppColors.primary.withValues(
                                    alpha: 0.08,
                                  ),
                                  child: _startedBanner(),
                                ),
                                // const SizedBox(height: 18),
                                // _sectionCard(child: _subTasksSection()),
                                const SizedBox(height: 18),
                                _sectionCard(
                                  child: _commentsHistoryTabs(cid, taskId),
                                ),
                                const SizedBox(height: 18),

                                Padding(
                                  padding: const EdgeInsets.only(bottom: 20),
                                  child: _rightDetailsPanelMobile(),
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    }

                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 3,
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: ListView(
                              children: [
                                _sectionCard(child: _taskHeader()),
                                const SizedBox(height: 18),
                                _sectionCard(child: _statusSummary()),
                                const SizedBox(height: 18),
                                _sectionCard(
                                  color: AppColors.primary.withValues(
                                    alpha: 0.08,
                                  ),
                                  child: _startedBanner(),
                                ),
                                // const SizedBox(height: 18),
                                // _sectionCard(child: _subTasksSection()),
                                const SizedBox(height: 18),
                                _sectionCard(
                                  child: _commentsHistoryTabs(cid, taskId),
                                ),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(
                          width: 340,
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: _rightDetailsPanelDesktop(),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              );
            },
          ),
        );
      },
    );
  }

  // PreferredSizeWidget _buildAppBar() {
  //   return AppBar(
  //     backgroundColor: AppColors.white,
  //     elevation: 1,
  //     // leading: IconButton(
  //     //   onPressed: () {
  //     //     if (Navigator.canPop(context)) {
  //     //       Navigator.pop(context);
  //     //     }
  //     //   },
  //     //   icon: Icon(Icons.close, color: AppColors.black),
  //     // ),
  //     title: Text(
  //       "Task Details",
  //       style: Theme.of(context).textTheme.titleLarge?.copyWith(
  //         fontWeight: FontWeight.bold,
  //         color: AppColors.primary,
  //       ),
  //     ),
  //   );
  // }

  Widget _sectionCard({required Widget child, Color? color}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color ?? AppColors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.black12,
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _taskHeader() {
    final daysLeft = _taskModel.deadline?.difference(DateTime.now()).inDays;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                _taskModel.taskName,
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
            if (_taskModel.highPriority) _priorityBadge(),
            const SizedBox(width: 8),
            _statusBadge(),
          ],
        ),
        const SizedBox(height: 12),
        if (_taskModel.tags.isNotEmpty) _tagsWrap(),
        if (daysLeft != null) _deadlineText(daysLeft),
        const Divider(height: 20),
        Text(
          _taskModel.description,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: AppColors.grey700,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _priorityBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.danger,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Icon(Icons.priority_high, size: 16, color: AppColors.danger),
          SizedBox(width: 6),
          Text(
            "High Priority",
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppColors.danger),
          ),
        ],
      ),
    );
  }

  Widget _statusBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: _taskModel.completed ? AppColors.success : AppColors.accent,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        _taskModel.completed ? "Completed" : "In Progress",
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: _taskModel.completed ? AppColors.white : AppColors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _tagsWrap() {
    return Wrap(
      spacing: 8,
      runSpacing: 6,
      children: _taskModel.tags
          .map(
            (t) => Chip(
              label: Text(t, style: Theme.of(context).textTheme.bodySmall),
              backgroundColor: AppColors.primary.withValues(alpha: 0.1),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _deadlineText(int daysLeft) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        daysLeft >= 0 ? "Due in $daysLeft days" : "Overdue",
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: daysLeft >= 0 ? AppColors.blue : AppColors.danger,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _statusSummary() {
    final createdUser = CacheService.getUserByUid(_taskModel.createdBy.first);
    final UserDataModel userDataModel;

    if (createdUser is AdminModel) {
      userDataModel = UserDataModel(
        name: createdUser.name,
        profilePic: createdUser.profileImageUrl,
        uid: createdUser.uid ?? '',
        userType: UserType.admin,
        desc: createdUser.email,
      );
    } else {
      userDataModel = UserDataModel(
        name: createdUser.name,
        profilePic: createdUser.profileImageUrl,
        uid: createdUser.uid ?? '',
        userType: UserType.employee,
        desc: createdUser.email,
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.black12,
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              UserAvatar(userData: userDataModel),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      createdUser?.name ?? "Unknown User",
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _taskModel.createdAt.listingDateTime,
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: AppColors.grey600),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _statusBadge(),
                        const SizedBox(width: 8),
                        if (_taskModel.highPriority) _priorityBadge(),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          if (_taskModel.description.isNotEmpty)
            Text(
              _taskModel.description,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.grey700,
                height: 1.5,
              ),
            ),
          const SizedBox(height: 16),

          // Attachments
          if (_taskModel.attachments.isNotEmpty) ...[
            Text(
              "Attachments",
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            _attachmentsGrid(_taskModel.attachments),
          ],
        ],
      ),
    );
  }

  Widget _attachmentsGrid(List<FileModel> attachments) {
    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      padding: EdgeInsets.zero,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: 0.8,
      ),
      itemCount: attachments.length,
      itemBuilder: (context, index) {
        final file = attachments[index];
        final isImage =
            file.name.endsWith(".jpg") ||
            file.name.endsWith(".png") ||
            file.name.endsWith(".jpeg") ||
            file.name.endsWith(".gif");
        final isPdf = file.name.endsWith(".pdf");

        return GestureDetector(
          onTap: () {
            if (isImage) {
              Navigate.route(
                context,
                GalleryScreen(images: [file], initialIndex: 0),
              );
            } else if (isPdf) {
              // Navigator.push(
              //   context,
              //   MaterialPageRoute(
              //     builder: (_) => PdfPreviewScreen(url: file.url),
              //   ),
              // );
            }
          },
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.grey100,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.grey300),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isImage
                      ? Icons.image
                      : isPdf
                      ? Icons.picture_as_pdf
                      : Icons.insert_drive_file,
                  size: 36,
                  color: AppColors.primary,
                ),
                const SizedBox(height: 6),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Text(
                    file.name,
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _startedBanner() {
    String statusText;
    IconData statusIcon;

    if (_taskModel.completed) {
      statusText = "Completed";
      statusIcon = Icons.check_circle;
    } else if (_taskModel.hasStarted) {
      statusText = "Started";
      statusIcon = Icons.play_circle_fill;
    } else {
      statusText = "Not started";
      statusIcon = Icons.pause_circle_filled;
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(statusIcon, color: AppColors.white),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              statusText,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: AppColors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Text(
            _taskModel.createdAt.listingDateTime,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppColors.white70),
          ),
        ],
      ),
    );
  }

  // Widget _subTasksSection() {
  //   return Column(
  //     crossAxisAlignment: CrossAxisAlignment.start,
  //     children: [
  //       Text("Subtasks", style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold)),
  //       const SizedBox(height: 10),
  //       Container(
  //         padding: const EdgeInsets.all(12),
  //         decoration: BoxDecoration(
  //           color: AppColors.white,
  //           borderRadius: BorderRadius.circular(8),
  //         ),
  //         child: Text("No subtasks"),
  //       ),
  //     ],
  //   );
  // }

  Widget _commentsHistoryTabs(String cid, String taskId) {
    return DefaultTabController(
      length: 3,
      child: Column(
        children: [
          const TabBar(
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.grey,
            indicatorColor: AppColors.primary,
            tabs: [
              Tab(text: "Comments"),
              Tab(text: "History"),
              Tab(text: "Time"),
            ],
          ),
          SizedBox(
            height: 220,
            child: TabBarView(
              children: [
                _commentsTab(taskId, cid),
                _historyTab(taskId, cid),
                Center(
                  child: Text(
                    "00:00:00",
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _commentsTab(String taskId, String cid) {
    return StreamBuilder<List<TaskCommentModel>>(
      stream: TaskService.streamComments(cid: cid, taskId: taskId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: WaitingLoading());
        }

        final comments = snapshot.data ?? [];
        _commentCount = comments.length;

        return Column(
          children: [
            Expanded(
              child: comments.isEmpty
                  ? Center(
                      child: Text(
                        "No comments yet",
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: comments.length,
                      itemBuilder: (context, index) {
                        final c = comments[index];
                        final user = CacheService.getUserByUid(c.userId);

                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.grey100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                c.comment,
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                user?.name ?? c.userId,
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(color: AppColors.grey600),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                c.timestamp.listingDateTime,
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(color: AppColors.grey600),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),

            const Divider(height: 1),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _commentController,
                      decoration: const InputDecoration(
                        hintText: "Add a comment...",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(8)),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: _isSending ? null : () => _addComment(taskId),
                    icon: _isSending
                        ? const WaitingLoading()
                        : const Icon(Icons.send, color: AppColors.primary),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _historyTab(String taskId, String cid) {
    return StreamBuilder<List<TaskHistoryModel>>(
      stream: TaskService.streamTaskHistory(cid: cid, taskId: taskId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: WaitingLoading());
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
            child: Text(
              "No history available",
              style: Theme.of(context).textTheme.bodySmall,
            ),
          );
        }

        final history = snapshot.data!;

        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: history.length,
          itemBuilder: (context, index) {
            final h = history[index];
            final user = CacheService.getUserByUid(h.userId);

            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.grey100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    h.updateDisposition,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    user?.name ?? h.userId,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  if (h.update != null && h.update!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      "Info: ${h.update}",
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: AppColors.grey700),
                    ),
                  ],
                  const SizedBox(height: 4),
                  Text(
                    h.timestamp.listingDateTime,
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: AppColors.grey600),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _rightDetailsPanelDesktop() {
    return Container(
      decoration: _boxDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _panelHeader(),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: ListView(
                children: _panelContent(isParticipant: isParticipant),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _rightDetailsPanelMobile() {
    return Container(
      decoration: _boxDecoration(),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _panelHeader(),
            const SizedBox(height: 10),
            ..._panelContent(isParticipant: isParticipant),
          ],
        ),
      ),
    );
  }

  BoxDecoration _boxDecoration() => BoxDecoration(
    color: AppColors.white,
    borderRadius: BorderRadius.circular(12),
    boxShadow: [
      BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 3)),
    ],
  );

  Widget _panelHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _taskModel.completed
                ? "Completed"
                : (_taskModel.hasStarted ? "In Progress" : "Not started"),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _taskModel.updatedAt.listingDateTime,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: Colors.white70),
          ),
        ],
      ),
    );
  }

  List<Widget> _panelContent({required bool isParticipant}) {
    return [
      _detailItem("Deadline", _taskModel.deadline?.formatDate ?? "-"),
      const SizedBox(height: 6),
      _detailItem("Reminder", _taskModel.reminder?.listingDateTime ?? "-"),
      const Divider(),
      _sectionHeader("Created by"),
      for (var u in _taskModel.createdBy) _profileTile(u, subtitle: "Creator"),
      const Divider(),
      _sectionHeader("Assignee"),
      if (_taskModel.assignees.isEmpty)
        _emptyTile("No assignees")
      else
        for (var u in _taskModel.assignees)
          _profileTile(u, subtitle: "Assignee"),
      const Divider(),
      _sectionHeader("Participants"),
      if (_taskModel.participants.isEmpty)
        _emptyTile("No participants")
      else
        for (var u in _taskModel.participants)
          _profileTile(u, subtitle: "Participant"),
      const Divider(),
      _sectionHeader("Observers"),
      if (_taskModel.observers.isEmpty)
        _emptyTile("No observers")
      else
        for (var u in _taskModel.observers)
          _profileTile(u, subtitle: "Observer"),
      const SizedBox(height: 12),

      if (isParticipant) ...[
        const SizedBox(height: 12),
        if (!_taskModel.hasStarted && !_taskModel.completed)
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              foregroundColor: Colors.white,
              backgroundColor: AppColors.primary,
            ),
            onPressed: _isActionLoading ? null : () => _startTask(),
            icon: const Icon(Icons.play_arrow),
            label: _isActionLoading
                ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        "Start Task",
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      SizedBox(width: 10),
                      SizedBox(width: 16, height: 16, child: WaitingLoading()),
                    ],
                  )
                : Text(
                    "Start Task",
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
          ),
        if (_taskModel.hasStarted && !_taskModel.completed)
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              foregroundColor: Colors.white,
              backgroundColor: AppColors.primary,
            ),
            onPressed: _isActionLoading
                ? null
                : () {
                    if (_taskModel.statusSummaryRequired &&
                        _commentCount == 0) {
                      FlushBar.show(
                        context,
                        "Please add a comment before completing this task",
                        isSuccess: false,
                      );
                      return;
                    }
                    _completeTask();
                  },
            icon: const Icon(Icons.check_circle),
            label: _isActionLoading
                ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        "Mark as Completed",
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      SizedBox(width: 10),
                      SizedBox(width: 16, height: 16, child: WaitingLoading()),
                    ],
                  )
                : Text(
                    "Mark as Completed",
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
          ),
      ],
    ];
  }

  Widget _sectionHeader(String title) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Text(
      title,
      style: Theme.of(
        context,
      ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
    ),
  );

  Widget _profileTile(String uid, {String? subtitle}) {
    final emp = CacheService.getUserByUid(uid);
    final name = emp?.name ?? "Unknown";
    final photoUrl = emp?.profileImageUrl;

    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        radius: 20,
        backgroundImage: (photoUrl != null && photoUrl.isNotEmpty)
            ? NetworkImage(photoUrl)
            : null,
        child: (photoUrl == null || photoUrl.isEmpty)
            ? Text(
                name.isNotEmpty ? name.toString().capitalizeFirst : "?",
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold),
              )
            : null,
      ),
      title: Text(name, style: Theme.of(context).textTheme.bodySmall),
      subtitle: subtitle != null
          ? Text(subtitle, style: Theme.of(context).textTheme.bodySmall)
          : null,
    );
  }

  Widget _emptyTile(String text) => ListTile(
    dense: true,
    contentPadding: EdgeInsets.zero,
    leading: const CircleAvatar(radius: 18),
    title: Text(
      text,
      style: Theme.of(
        context,
      ).textTheme.bodySmall?.copyWith(color: AppColors.grey),
    ),
  );

  Widget _detailItem(String title, String value) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: AppColors.grey600),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
        ),
      ],
    ),
  );
}
