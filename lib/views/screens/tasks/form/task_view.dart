import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import '/constants/constants.dart';
import '/models/models.dart';
import '/services/services.dart';
import '/utils/utils.dart';
import '/views/views.dart';

class TaskViewColors {
  static const Color primary = Color(0xFF2563EB);
  static const Color secondary = Color(0xFF64748B);
  static const Color background = Color(0xFFF8FAFC);
  static const Color white = Colors.white;
  static const Color border = Color(0xFFE2E8F0);
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color danger = Color(0xFFEF4444);
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
}

class TaskView extends StatefulWidget {
  final String uid;
  const TaskView({super.key, required this.uid});

  @override
  State<TaskView> createState() => _TaskViewState();
}

class _TaskViewState extends State<TaskView> with TickerProviderStateMixin {
  late Future<TaskModel> _future;
  late TaskModel _taskModel;
  late TabController _tabController;
  final TextEditingController _commentController = TextEditingController();

  String? currentUid;
  bool _isSending = false;
  bool isParticipant = false;
  bool _isActionLoading = false;

  @override
  void initState() {
    super.initState();
    _future = TaskService.getTask(uid: widget.uid);
    _tabController = TabController(length: 3, vsync: this);
    Spdb.getUid().then((uid) => setState(() => currentUid = uid));
  }

  @override
  void dispose() {
    _tabController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _addComment(String taskId) async {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;
    setState(() => _isSending = true);
    try {
      await TaskService.addComment(taskId: taskId, comment: text);
      _commentController.clear();
    } catch (e) {
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
      setState(() => _taskModel.completed = true);
      FlushBar.show(context, "Task marked completed", isSuccess: true);
    } catch (e) {
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
        final String cid = snapshot.data ?? '';

        return FutureBuilder<TaskModel>(
          future: _future,
          builder: (context, taskSnap) {
            if (taskSnap.connectionState == ConnectionState.waiting) {
              return const WaitingLoading();
            }
            if (!taskSnap.hasData) return ErrorDisplay(error: "Task not found");

            _taskModel = taskSnap.data!;
            isParticipant =
                currentUid != null &&
                (_taskModel.assignees.contains(currentUid!) ||
                    _taskModel.createdBy.contains(currentUid!));

            return Scaffold(
              backgroundColor: TaskViewColors.background,
              appBar: AppBar(
                backgroundColor: TaskViewColors.white,
                elevation: 0,
                centerTitle: false,
                leading: const Padding(
                  padding: EdgeInsets.only(left: 8.0),
                  child: Back(),
                ),
                title: const Text(
                  "Task Details",
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: TaskViewColors.textPrimary,
                    fontSize: 18,
                  ),
                ),
                bottom: PreferredSize(
                  preferredSize: const Size.fromHeight(1),
                  child: Container(color: TaskViewColors.border, height: 1),
                ),
              ),
              body: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1400),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final isWide = constraints.maxWidth > 1000;
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: isWide ? 7 : 1,
                            child: SingleChildScrollView(
                              padding: const EdgeInsets.all(24),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [_buildMainContent(cid)],
                              ),
                            ),
                          ),
                          if (isWide)
                            Container(
                              width: 380,
                              decoration: const BoxDecoration(
                                border: Border(
                                  left: BorderSide(
                                    color: TaskViewColors.border,
                                  ),
                                ),
                                color: TaskViewColors.white,
                              ),
                              child: _buildSidePanel(),
                            ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildMainContent(String cid) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTaskHeader(),
        const SizedBox(height: 24),
        _buildInfoGrid(),
        const SizedBox(height: 32),
        _buildSectionLabel("TASK DESCRIPTION"),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: TaskViewColors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: TaskViewColors.border),
          ),
          child: Text(
            _taskModel.description.isNotEmpty
                ? _taskModel.description
                : "No description provided for this task.",
            style: const TextStyle(
              fontSize: 15,
              height: 1.6,
              color: TaskViewColors.textPrimary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const SizedBox(height: 32),
        if (_taskModel.attachments.isNotEmpty) ...[
          _buildSectionLabel("ATTACHMENTS"),
          const SizedBox(height: 12),
          _buildAttachmentsGrid(),
          const SizedBox(height: 32),
        ],
        _buildModernTabs(cid),
      ],
    );
  }

  Widget _buildTaskHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _taskModel.highPriority
                    ? TaskViewColors.danger.withValues(alpha: 0.1)
                    : TaskViewColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color:
                      (_taskModel.highPriority
                              ? TaskViewColors.danger
                              : TaskViewColors.primary)
                          .withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _taskModel.highPriority ? Iconsax.flash : Iconsax.task,
                    size: 14,
                    color: _taskModel.highPriority
                        ? TaskViewColors.danger
                        : TaskViewColors.primary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _taskModel.highPriority ? "URGENT" : "STANDARD",
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      color: _taskModel.highPriority
                          ? TaskViewColors.danger
                          : TaskViewColors.primary,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            _buildStatusBadge(),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          _taskModel.taskName,
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w900,
            color: TaskViewColors.textPrimary,
          ),
        ),
        if (_taskModel.tags.isNotEmpty) ...[
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: _taskModel.tags
                .map(
                  (tag) => Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: TaskViewColors.background,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: TaskViewColors.border),
                    ),
                    child: Text(
                      "#$tag",
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: TaskViewColors.textSecondary,
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ],
    );
  }

  Widget _buildStatusBadge() {
    final bool isCompleted = _taskModel.completed;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isCompleted
            ? TaskViewColors.success.withValues(alpha: 0.1)
            : TaskViewColors.warning.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: (isCompleted ? TaskViewColors.success : TaskViewColors.warning)
              .withValues(alpha: 0.2),
        ),
      ),
      child: Text(
        isCompleted
            ? "COMPLETED"
            : (_taskModel.hasStarted ? "IN PROGRESS" : "PENDING"),
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w900,
          color: isCompleted ? TaskViewColors.success : TaskViewColors.warning,
          letterSpacing: 1,
        ),
      ),
    );
  }

  Widget _buildInfoGrid() {
    final daysLeft =
        _taskModel.deadline?.difference(DateTime.now()).inDays ?? 0;
    return Row(
      children: [
        _infoBox(
          Iconsax.calendar_1,
          "Deadline",
          _taskModel.deadline?.formatDate ?? "No date",
          daysLeft < 0 ? TaskViewColors.danger : TaskViewColors.primary,
        ),
        const SizedBox(width: 16),
        _infoBox(
          Iconsax.timer_1,
          "Reminder",
          _taskModel.reminder?.listingDateTime ?? "Disabled",
          TaskViewColors.secondary,
        ),
      ],
    );
  }

  Widget _infoBox(IconData icon, String label, String val, Color accent) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: TaskViewColors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: TaskViewColors.border),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 20, color: accent),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: TaskViewColors.textSecondary,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  val,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: TaskViewColors.textPrimary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w900,
        color: TaskViewColors.textSecondary,
        letterSpacing: 1.5,
      ),
    );
  }

  Widget _buildAttachmentsGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.5,
      ),
      itemCount: _taskModel.attachments.length,
      itemBuilder: (context, index) {
        final file = _taskModel.attachments[index];
        return Container(
          decoration: BoxDecoration(
            color: TaskViewColors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: TaskViewColors.border),
          ),
          child: Row(
            children: [
              const SizedBox(width: 12),
              const Icon(
                Iconsax.document_text,
                color: TaskViewColors.primary,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      file.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      "${file.size} KB",
                      style: const TextStyle(
                        fontSize: 10,
                        color: TaskViewColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Iconsax.arrow_circle_down,
                size: 18,
                color: TaskViewColors.secondary,
              ),
              const SizedBox(width: 12),
            ],
          ),
        );
      },
    );
  }

  Widget _buildModernTabs(String cid) {
    return Column(
      children: [
        Container(
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: TaskViewColors.border)),
          ),
          child: TabBar(
            controller: _tabController,
            labelColor: TaskViewColors.primary,
            unselectedLabelColor: TaskViewColors.textSecondary,
            indicatorColor: TaskViewColors.primary,
            indicatorWeight: 3,
            labelStyle: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
            tabs: const [
              Tab(text: "Comments"),
              Tab(text: "Activity History"),
              Tab(text: "Time Tracking"),
            ],
          ),
        ),
        const SizedBox(height: 20),
        SizedBox(
          height: 500,
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildCommentsTab(cid),
              _buildHistoryTab(cid),
              _buildEmptyState(Iconsax.timer_1, "No time logs recorded."),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCommentsTab(String cid) {
    return StreamBuilder<List<TaskCommentModel>>(
      stream: TaskService.streamComments(cid: cid, taskId: _taskModel.uid!),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return WaitingLoading();
        }
        final comments = snapshot.data ?? [];

        return Column(
          children: [
            _buildCommentInput(),
            const SizedBox(height: 20),
            Expanded(
              child: comments.isEmpty
                  ? _buildEmptyState(Iconsax.slash, "No comments yet.")
                  : ListView.separated(
                      itemCount: comments.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 16),
                      itemBuilder: (context, index) =>
                          _buildCommentItem(comments[index]),
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCommentItem(TaskCommentModel comment) {
    final user = CacheService.getUserByUid(comment.userId);
    var userData = UserDataModel.fromEmptyMap();

    if (user is EmployeeModel) {
      userData = UserDataModel(
        name: user.name,
        uid: user.uid ?? '',
        profilePic: user.profileImageUrl,
        desc: CacheService.designationByUid(user.designation)?.name,
        userType: UserType.employee,
      );
    } else if (user is AdminModel) {
      userData = UserDataModel(
        name: user.name,
        uid: user.uid ?? '',
        profilePic: user.profileImageUrl,
        desc: user.email,
        userType: UserType.admin,
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        UserAvatar(userData: userData, size: 32),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: TaskViewColors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: TaskViewColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      user?.name ?? "Collaborator",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    Text(
                      comment.timestamp.listingDateTime,
                      style: const TextStyle(
                        fontSize: 11,
                        color: TaskViewColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  comment.comment,
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.4,
                    color: TaskViewColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCommentInput() {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _commentController,
            decoration: InputDecoration(
              hintText: "Add a progress update...",
              filled: true,
              fillColor: TaskViewColors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: TaskViewColors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: TaskViewColors.border),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        _isSending
            ? const CircularProgressIndicator()
            : IconButton(
                onPressed: () => _addComment(_taskModel.uid!),
                icon: const Icon(Iconsax.send_1, color: TaskViewColors.primary),
              ),
      ],
    );
  }

  Widget _buildHistoryTab(String cid) {
    return StreamBuilder<List<TaskHistoryModel>>(
      stream: TaskService.streamTaskHistory(cid: cid, taskId: _taskModel.uid!),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return WaitingLoading();
        }
        final history = snapshot.data ?? [];
        if (history.isEmpty) {
          return _buildEmptyState(Iconsax.activity, "No activity recorded.");
        }
        return ListView.builder(
          itemCount: history.length,
          itemBuilder: (context, index) =>
              _buildHistoryItem(history[index], index == history.length - 1),
        );
      },
    );
  }

  Widget _buildHistoryItem(TaskHistoryModel item, bool isLast) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: const BoxDecoration(
                  color: TaskViewColors.primary,
                  shape: BoxShape.circle,
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(width: 2, color: TaskViewColors.border),
                ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.updateDisposition,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    "By ${CacheService.getUserByUid(item.userId)?.name ?? 'User'} • ${item.timestamp.listingDateTime}",
                    style: const TextStyle(
                      fontSize: 12,
                      color: TaskViewColors.textSecondary,
                    ),
                  ),
                  if (item.update != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      item.update!,
                      style: const TextStyle(
                        fontSize: 13,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidePanel() {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        _buildSectionLabel("ASSIGNED TO"),
        const SizedBox(height: 16),
        ..._taskModel.assignees.map(
          (u) => _buildProfileTile(u, "Lead Execution"),
        ),
        const SizedBox(height: 32),
        _buildSectionLabel("COLLABORATORS"),
        const SizedBox(height: 16),
        if (_taskModel.participants.isEmpty)
          _buildEmptyStateSmall("No participants")
        else
          ..._taskModel.participants.map(
            (u) => _buildProfileTile(u, "Participant"),
          ),
        const SizedBox(height: 32),
        _buildSectionLabel("OBSERVERS"),
        const SizedBox(height: 16),
        if (_taskModel.observers.isEmpty)
          _buildEmptyStateSmall("No observers")
        else
          ..._taskModel.observers.map((u) => _buildProfileTile(u, "Viewer")),
        const SizedBox(height: 40),
        if (isParticipant) _buildActionButtons(),
      ],
    );
  }

  Widget _buildProfileTile(String uid, String role) {
    final user = CacheService.getUserByUid(uid);
    var userData = UserDataModel.fromEmptyMap();

    if (user is EmployeeModel) {
      userData = UserDataModel(
        name: user.name,
        uid: user.uid ?? '',
        profilePic: user.profileImageUrl,
        desc: CacheService.designationByUid(user.designation)?.name,
        userType: UserType.employee,
      );
    } else if (user is AdminModel) {
      userData = UserDataModel(
        name: user.name,
        uid: user.uid ?? '',
        profilePic: user.profileImageUrl,
        desc: user.email,
        userType: UserType.admin,
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          UserAvatar(userData: userData, size: 36),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                user?.name ?? "System User",
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
              Text(
                role,
                style: const TextStyle(
                  fontSize: 11,
                  color: TaskViewColors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    if (_taskModel.completed) {
      return const Center(
        child: Text(
          "Task successfully closed.",
          style: TextStyle(
            color: TaskViewColors.success,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!_taskModel.hasStarted)
          ElevatedButton.icon(
            onPressed: _isActionLoading ? null : _startTask,
            icon: const Icon(Iconsax.play),
            label: const Text("Activate Task"),
            style: ElevatedButton.styleFrom(
              backgroundColor: TaskViewColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.all(16),
              elevation: 0,
            ),
          ),
        if (_taskModel.hasStarted)
          ElevatedButton.icon(
            onPressed: _isActionLoading ? null : _completeTask,
            icon: const Icon(Iconsax.tick_circle),
            label: const Text("Mark as Completed"),
            style: ElevatedButton.styleFrom(
              backgroundColor: TaskViewColors.success,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.all(16),
              elevation: 0,
            ),
          ),
      ],
    );
  }

  Widget _buildEmptyState(IconData icon, String msg) => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 40, color: TaskViewColors.border),
        const SizedBox(height: 12),
        Text(msg, style: const TextStyle(color: TaskViewColors.textSecondary)),
      ],
    ),
  );
  Widget _buildEmptyStateSmall(String msg) => Text(
    msg,
    style: const TextStyle(
      color: TaskViewColors.textSecondary,
      fontSize: 12,
      fontStyle: FontStyle.italic,
    ),
  );
}
