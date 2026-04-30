import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';
import '/models/models.dart';
import '/theme/theme.dart';
import '/utils/utils.dart';
import '/views/views.dart';
import '/services/services.dart';
import 'bloc/tasks_bloc.dart';

const String _pageTitle = "Tasks";

class TasksListing extends StatelessWidget {
  const TasksListing({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => TaskBloc()..add(StreamTasks()),
      child: const TaskListView(),
    );
  }
}

class TaskListView extends StatelessWidget {
  const TaskListView({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => PaginatedDataController<TaskModel>(
        initialSortColumnIndex: 1,
        filterLogic: (task, query) {
          final q = query.toLowerCase();
          return task.taskName.toLowerCase().contains(q) ||
              (task.tags.map((e) => e.toLowerCase()).contains(q));
        },
        sortLogic: (a, b, col, asc) {
          int compare;
          switch (col) {
            case 0:
              compare = a.taskName.toLowerCase().compareTo(
                b.taskName.toLowerCase(),
              );
              break;
            case 2:
              compare = (a.deadline ?? DateTime.now()).compareTo(
                (b.deadline ?? DateTime.now()),
              );
              break;
            default:
              compare = (a.uid ?? '').compareTo(b.uid ?? '');
          }
          return asc ? compare : -compare;
        },
        getItemId: (task) => task.uid ?? '',
      ),
      child: const TaskListingView(),
    );
  }
}

class TaskListingView extends StatefulWidget {
  const TaskListingView({super.key});

  @override
  State<TaskListingView> createState() => _TaskListingViewState();
}

class _TaskListingViewState extends State<TaskListingView> {
  final List<TaskModel> _selectedTasks = [];
  PermissionModel? permissions;
  String _selectedView = 'Grid';

  @override
  void initState() {
    super.initState();
    _loadPermissions();
  }

  Future<void> _loadPermissions() async {
    permissions = await PermissionService.getPermissions(_pageTitle);
    setState(() {});
  }

  final ScrollController _hScrollController = ScrollController();

  @override
  Widget build(BuildContext context) {
    final controllerRead = context.read<PaginatedDataController<TaskModel>>();
    final controllerWatch = context.watch<PaginatedDataController<TaskModel>>();

    return Scaffold(
      appBar: kIsMobile
          ? AppBar(leading: Back(), title: Text(_pageTitle))
          : null,
      body: BlocListener<TaskBloc, TaskState>(
        listenWhen: (previous, current) => current is TaskLoaded,
        listener: (context, state) {
          if (state is TaskLoaded) {
            controllerRead.setData(state.tasks);
          }
        },
        child: BlocBuilder<TaskBloc, TaskState>(
          builder: (context, state) {
            if (state is TaskLoading) return const WaitingLoading();

            if (state is TaskLoaded) {
              if (!(permissions?.canView ?? false)) {
                return buildNoPermissionView(context);
              }
              // final tasks = state.tasks;

              return SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    children: [
                      _buildFilterRow(
                        onSearchChanged: controllerRead.setSearch,
                      ),
                      const SizedBox(height: 10),
                      _buildActionRow(context),
                      const SizedBox(height: 20),
                      if (_selectedView == 'Calendar') ...[
                        TaskCalendarListing(tasks: state.tasks),
                      ] else ...[
                        _buildMainBody(controllerWatch, controllerRead),
                      ],
                    ],
                  ),
                ),
              );
            }

            if (state is TaskError) {
              return Center(
                child: SelectableText(
                  state.message,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              );
            }
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }

  Container _buildMainBody(
    PaginatedDataController<TaskModel> controllerWatch,
    PaginatedDataController<TaskModel> controllerRead,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: AppColors.grey.withValues(alpha: 0.1),
            spreadRadius: 2,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              // if (tasks.isEmpty) {
              //   return const Padding(
              //     padding: EdgeInsets.all(20.0),
              //     child: Center(
              //       child: Text(
              //         "No tasks found.",
              //         style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.grey),
              //       ),
              //     ),
              //   );
              // }

              return Scrollbar(
                controller: _hScrollController,
                thumbVisibility: true,
                trackVisibility: true,
                thickness: 4,
                radius: const Radius.circular(6),
                scrollbarOrientation: ScrollbarOrientation.bottom,
                child: SingleChildScrollView(
                  controller: _hScrollController,
                  scrollDirection: Axis.horizontal,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minWidth: constraints.maxWidth),
                    child: DataTable(
                      showCheckboxColumn: true,
                      columnSpacing: 12,
                      horizontalMargin: 8,
                      sortColumnIndex: controllerWatch.sortColumnIndex,
                      sortAscending: controllerWatch.sortAscending,
                      headingRowColor: WidgetStateProperty.all(
                        AppColors.grey100,
                      ),
                      headingTextStyle: Theme.of(context).textTheme.bodySmall
                          ?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.black,
                          ),
                      columns: [
                        DataColumn(
                          label: _sortableHeader("Task No", controllerRead),
                          onSort: controllerRead.setSort,
                        ),
                        DataColumn(
                          label: _sortableHeader("Name", controllerRead),
                          onSort: controllerRead.setSort,
                        ),
                        DataColumn(
                          label: Text(
                            "Active",
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                        DataColumn(
                          label: _sortableHeader("Deadline", controllerRead),
                          onSort: controllerRead.setSort,
                        ),
                        DataColumn(
                          label: Text(
                            "Task Created By",
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                        DataColumn(
                          label: Text(
                            "Assignee",
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),

                        DataColumn(
                          label: Text(
                            "Created By",
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                        DataColumn(
                          label: Text(
                            "Action",
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                      ],
                      rows: controllerWatch.paginatedItems
                          .map(
                            (task) => _buildDataRow(
                              context,
                              task,
                              controllerWatch,
                              controllerRead,
                            ),
                          )
                          .toList(),
                    ),
                  ),
                ),
              );
            },
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            child: PaginationControls<TaskModel>(),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterRow({required ValueChanged<String> onSearchChanged}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        SizedBox(
          width: 250,
          child: TextField(
            onChanged: onSearchChanged,
            decoration: InputDecoration(
              hintText: 'Search',
              prefixIcon: const Icon(
                Icons.search,
                size: 20,
                color: Colors.grey,
              ),
              filled: true,
              fillColor: AppColors.white,
              contentPadding: const EdgeInsets.symmetric(
                vertical: 12.0,
                horizontal: 16.0,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.0),
                borderSide: BorderSide(color: AppColors.grey, width: 1),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.0),
                borderSide: BorderSide(color: AppColors.blue, width: 1.5),
              ),
              hintStyle: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
            style: const TextStyle(fontSize: 14, color: Colors.black87),
          ),
        ),
      ],
    );
  }

  Widget _buildActionRow(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // final bool isMobile = constraints.maxWidth < 600;

        final addDeleteButtons = Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (permissions?.canCreate ?? false) ...[
              ElevatedButton.icon(
                onPressed: () {
                  if (kIsMobile) {
                    Sheet.showSheet(context, widget: const TaskCreate());
                  } else {
                    GeneralDialog.showRTLSheet(context, const TaskCreate());
                  }
                },
                icon: const Icon(Icons.add, size: 18),
                label: Text(
                  "Add $_pageTitle",
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: AppColors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.success,
                  foregroundColor: AppColors.white,
                ),
              ),
              const SizedBox(width: 10),
            ] else ...[
              ElevatedButton.icon(
                onPressed: null,
                icon: Icon(Icons.add, size: 18, color: AppColors.grey600),
                label: Text(
                  "Add $_pageTitle",
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: AppColors.grey600),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.grey300,
                  foregroundColor: AppColors.grey600,
                ),
              ),
            ],
            if (permissions?.canDelete ?? false) ...[
              if (_selectedTasks.isNotEmpty)
                ElevatedButton.icon(
                  label: Text(
                    "Delete",
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: AppColors.white),
                  ),
                  icon: const Icon(Iconsax.trash),
                  onPressed: () async {
                    final result = await showDialog(
                      context: context,
                      builder: (context) => ConfirmDialog(
                        title: 'Delete',
                        content:
                            'Are you sure want to delete this $_pageTitle?',
                      ),
                      barrierDismissible: false,
                    );

                    if (result != true) return;

                    try {
                      // ✅ STEP 1: backup
                      final deletedTasks = List<TaskModel>.from(_selectedTasks);

                      futureLoading(context);

                      // ✅ STEP 2: delete
                      for (var task in deletedTasks) {
                        await TaskService.deleteTask(uid: task.uid ?? '');
                      }

                      if (Navigator.canPop(context)) {
                        Navigator.pop(context);
                      }

                      // ✅ STEP 3: clear selection
                      _selectedTasks.clear();
                      setState(() {});

                      // ✅ STEP 4: UNDO
                      FlushBar.show(
                        context,
                        '$_pageTitle deleted successfully',
                        actionLabel: 'UNDO',
                        onActionPressed: () async {
                          for (var task in deletedTasks) {
                            await TaskService.restoreTask(task);
                          }

                          // 🔥 refresh list
                          context.read<TaskBloc>().add(StreamTasks());
                        },
                      );
                    } catch (e) {
                      if (Navigator.canPop(context)) {
                        Navigator.pop(context);
                      }
                      FlushBar.show(context, e.toString(), isSuccess: false);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.danger,
                    foregroundColor: AppColors.white,
                  ),
                ),
            ] else ...[
              ElevatedButton.icon(
                label: Text(
                  "Delete",
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: AppColors.white),
                ),
                icon: Icon(Iconsax.trash),
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.grey400,
                  foregroundColor: AppColors.white,
                ),
              ),
            ],
          ],
        );

        final viewToggle = Container(
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                onPressed: () {
                  _selectedView = 'List';
                  setState(() {});
                },
                icon: const Icon(Icons.list),
                color: _selectedView == 'List'
                    ? AppColors.blue
                    : AppColors.grey700,
              ),
              Container(width: 1, color: Colors.grey.shade300),
              IconButton(
                onPressed: () {
                  _selectedView = 'Calendar';
                  setState(() {});
                },
                icon: const Icon(Iconsax.calendar_1, size: 18),
                color: _selectedView == 'Calendar'
                    ? AppColors.blue
                    : AppColors.grey700,
              ),
            ],
          ),
        );

        if (kIsMobile) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: addDeleteButtons,
              ),
              const SizedBox(height: 8),
              viewToggle,
            ],
          );
        } else {
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [addDeleteButtons, viewToggle],
          );
        }
      },
    );
  }

  Widget _sortableHeader(String label, controllerRead) {
    return Row(
      children: [
        Text(label, style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(width: 4),
        Icon(Icons.arrow_upward, size: 14, color: AppColors.grey400),
      ],
    );
  }

  DataRow _buildDataRow(
    BuildContext context,
    TaskModel task,
    PaginatedDataController<TaskModel> controllerWatch,
    PaginatedDataController<TaskModel> controllerRead,
  ) {
    bool isSelected = controllerWatch.selectedIds.contains(task.uid);
    void openTask(BuildContext context, String uid) {
      if (kIsMobile) {
        Sheet.showSheet(context, widget: TaskView(uid: uid));
      } else {
        GeneralDialog.showRTLSheet(context, TaskView(uid: uid));
      }
    }

    DataCell dataCell(BuildContext context, Widget child, String uid) {
      return DataCell(
        InkWell(
          onTap: () => openTask(context, uid),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: child,
          ),
        ),
      );
    }

    return DataRow(
      selected: isSelected,
      onSelectChanged: (selected) {
        controllerRead.onSelected(task.uid ?? '', selected);
        if (selected ?? false) {
          _selectedTasks.add(task);
        } else {
          _selectedTasks.remove(task);
        }
        setState(() {});
      },
      cells: [
        dataCell(
          context,
          SelectableText(
            task.taskNumber?.toString() ?? '-',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(fontSize: 11),
          ),
          task.uid ?? '',
        ),

        dataCell(
          context,
          Text(
            task.taskName,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w500),
          ),
          task.uid ?? '',
        ),

        dataCell(
          context,
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(5),
              color: task.completed
                  ? AppColors.success
                  : task.hasStarted
                  ? AppColors.blue
                  : AppColors.danger,
            ),
            child: Text(
              task.completed
                  ? 'Completed'
                  : task.hasStarted
                  ? 'Started'
                  : 'Not Started',
              style: Theme.of(
                context,
              ).textTheme.bodySmall!.copyWith(color: AppColors.white),
            ),
          ),
          task.uid ?? '',
        ),

        dataCell(
          context,
          Text(
            task.deadline?.listingDateTime ?? '',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          task.uid ?? '',
        ),

        dataCell(
          context,
          Text(
            task.createdBy
                .map((e) => CacheService.getUserByUid(e)?.name ?? '')
                .toList()
                .join(',\n'),
            softWrap: true,
            maxLines: null,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          task.uid ?? '',
        ),

        dataCell(
          context,
          SizedBox(
            width: 120,
            child: Text(
              task.assignees
                  .map((e) => CacheService.getUserByUid(e)?.name ?? '')
                  .where((name) => name.isNotEmpty)
                  .join(',\n'),
              softWrap: true,
              maxLines: null,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
          task.uid ?? '',
        ),

        dataCell(
          context,
          CreatedByWidget(userData: task.taskCreatedBy),
          task.uid ?? '',
        ),
        DataCell(
          Row(
            children: [
              if ((permissions?.canEdit ?? false)) ...[
                IconButton(
                  icon: const Icon(Iconsax.edit),
                  onPressed: () {
                    if (kIsMobile) {
                      Sheet.showSheet(
                        context,
                        widget: TaskEdit(uid: task.uid ?? ''),
                      );
                    } else {
                      GeneralDialog.showRTLSheet(
                        context,
                        TaskEdit(uid: task.uid ?? ''),
                      );
                    }
                  },
                  color: AppColors.info,
                  splashRadius: 20,
                ),
              ] else ...[
                IconButton(
                  icon: Icon(Iconsax.edit, color: AppColors.grey400),
                  onPressed: null,
                ),
              ],
              if ((permissions?.canDelete ?? false)) ...[
                IconButton(
                  icon: const Icon(Iconsax.trash),
                  color: AppColors.danger,
                  splashRadius: 20,
                  tooltip: 'Delete $_pageTitle',
                  onPressed: () async {
                    final result = await showDialog<bool>(
                      context: context,
                      builder: (context) => ConfirmDialog(
                        title: 'Delete $_pageTitle',
                        content: 'Are you sure you want to delete this task?',
                      ),
                    );

                    if (result != true) return;

                    try {
                      final deletedTask = task;

                      await TaskService.deleteTask(uid: task.uid ?? '');

                      if (!mounted) return;

                      FlushBar.show(
                        context,
                        '$_pageTitle deleted successfully',
                        actionLabel: 'UNDO',
                        onActionPressed: () async {
                          await TaskService.restoreTask(deletedTask);

                          // ✅ refresh AFTER undo
                          context.read<TaskBloc>().add(StreamTasks());
                        },
                        // onDismissed: () {
                        //   // ✅ refresh AFTER snackbar disappears (no undo)
                        //   context.read<TaskBloc>().add(StreamTasks());
                        // },
                      );
                    } catch (e, st) {
                      await ErrorService.recordError(e, st);
                      FlushBar.show(context, e.toString(), isSuccess: false);
                    }
                  },
                ),
              ] else ...[
                IconButton(
                  icon: Icon(Iconsax.trash, color: AppColors.grey400),
                  onPressed: null,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  // Widget _searchBox({required ValueChanged<String> onSearchChanged}) {
  //   return SizedBox(
  //     width: 200,
  //     child: ListingSearchField(
  //       onChanged: onSearchChanged,
  //       pageTitle: _pageTitle,
  //     ),
  //   );
  // }
}
