import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';
import '/models/models.dart';
import '/views/views.dart';
import '/utils/utils.dart';
import '/theme/theme.dart';
import '/services/services.dart';
import 'bloc/projects_bloc.dart';

const String _pageTitle = "Projects";

class ProjectsListing extends StatelessWidget {
  const ProjectsListing({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => ProjectsBloc()..add(StreamProjects()),
      child: ChangeNotifierProvider(
        create: (context) => PaginatedDataController<ProjectModel>(
          initialSortColumnIndex: 0,
          filterLogic: (project, query) {
            final q = query.toLowerCase();
            return project.projectName.toLowerCase().contains(q) ||
                project.projectName.toLowerCase().contains(q);
          },
          sortLogic: (a, b, col, asc) {
            int compare;
            switch (col) {
              case 0:
                //   compare = a.projectId
                //       .toLowerCase()
                //       .compareTo(b.projectId.toLowerCase());
                //   break;
                // case 1:
                compare = a.projectName.toLowerCase().compareTo(
                  b.projectName.toLowerCase(),
                );
                break;
              case 2:
                compare = (a.projectCode ?? '').toLowerCase().compareTo(
                  (b.projectCode ?? '').toLowerCase(),
                );
                break;

              default:
                compare = (a.projectName).compareTo(b.projectName);
                break;
            }
            return asc ? compare : -compare;
          },
          getItemId: (project) => project.uid ?? '',
        ),
        child: const ProjectsListingView(),
      ),
    );
  }
}

class ProjectsListingView extends StatefulWidget {
  const ProjectsListingView({super.key});

  @override
  State<ProjectsListingView> createState() => _ProjectsListingViewState();
}

class _ProjectsListingViewState extends State<ProjectsListingView> {
  final List<ProjectModel> _selectedProjects = [];
  PermissionModel? permissions;
  final ScrollController _hScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadPermissions();
  }

  Future<void> _loadPermissions() async {
    permissions = await PermissionService.getPermissions(_pageTitle);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final controllerRead = context
        .read<PaginatedDataController<ProjectModel>>();
    final controllerWatch = context
        .watch<PaginatedDataController<ProjectModel>>();

    return Scaffold(
      appBar: kIsMobile
          ? AppBar(leading: Back(), title: Text(_pageTitle))
          : null,
      body: BlocListener<ProjectsBloc, ProjectsState>(
        listenWhen: (previous, current) => current is ProjectsLoaded,
        listener: (context, state) {
          if (state is ProjectsLoaded) {
            controllerRead.setData(state.projects);
          }
        },
        child: BlocBuilder<ProjectsBloc, ProjectsState>(
          builder: (context, state) {
            if (state is ProjectsLoading) {
              return const WaitingLoading();
            }

            if (state is ProjectsLoaded) {
              if (!(permissions?.canView ?? false)) {
                return buildNoPermissionView(context);
              }
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
                      Container(
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
                                return Scrollbar(
                                  controller: _hScrollController,
                                  thumbVisibility: true,
                                  trackVisibility: true,
                                  thickness: 4,
                                  radius: const Radius.circular(6),
                                  scrollbarOrientation:
                                      ScrollbarOrientation.bottom,
                                  child: SingleChildScrollView(
                                    controller: _hScrollController,
                                    scrollDirection: Axis.horizontal,
                                    child: ConstrainedBox(
                                      constraints: BoxConstraints(
                                        minWidth: constraints.maxWidth,
                                      ),
                                      child: DataTable(
                                        showCheckboxColumn: true,
                                        sortColumnIndex:
                                            controllerWatch.sortColumnIndex,
                                        sortAscending:
                                            controllerWatch.sortAscending,
                                        headingRowColor:
                                            WidgetStateProperty.all(
                                              AppColors.grey100,
                                            ),
                                        headingTextStyle: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(
                                              fontWeight: FontWeight.bold,
                                              color: AppColors.black,
                                            ),
                                        columns: [
                                          // DataColumn(
                                          //   label: Row(
                                          //     children: [
                                          //       Text("Projects ID"),
                                          //       const SizedBox(width: 4),
                                          //       Icon(Icons.arrow_upward,
                                          //           size: 14,
                                          //           color: AppColors.grey400),
                                          //     ],
                                          //   ),
                                          //   onSort: controllerRead.setSort,
                                          // ),
                                          DataColumn(
                                            label: Row(
                                              children: [
                                                Text(
                                                  "Project Name",
                                                  style: Theme.of(
                                                    context,
                                                  ).textTheme.bodySmall,
                                                ),
                                                const SizedBox(width: 4),
                                                Icon(
                                                  Icons.arrow_upward,
                                                  size: 14,
                                                  color: AppColors.grey400,
                                                ),
                                              ],
                                            ),
                                            onSort: controllerRead.setSort,
                                          ),
                                          DataColumn(
                                            label: Row(
                                              children: [
                                                Text(
                                                  "Project Code",
                                                  style: Theme.of(
                                                    context,
                                                  ).textTheme.bodySmall,
                                                ),
                                                const SizedBox(width: 4),
                                                Icon(
                                                  Icons.arrow_upward,
                                                  size: 14,
                                                  color: AppColors.grey400,
                                                ),
                                              ],
                                            ),
                                            onSort: controllerRead.setSort,
                                          ),
                                          DataColumn(
                                            label: Text(
                                              "Lead",
                                              style: Theme.of(
                                                context,
                                              ).textTheme.bodySmall,
                                            ),
                                          ),
                                          DataColumn(
                                            label: Row(
                                              children: [
                                                Text(
                                                  "Deadline",
                                                  style: Theme.of(
                                                    context,
                                                  ).textTheme.bodySmall,
                                                ),
                                                const SizedBox(width: 4),
                                                Icon(
                                                  Icons.arrow_upward,
                                                  size: 14,
                                                  color: AppColors.grey400,
                                                ),
                                              ],
                                            ),
                                            onSort: controllerRead.setSort,
                                          ),
                                          DataColumn(
                                            label: Text(
                                              "Created By",
                                              style: Theme.of(
                                                context,
                                              ).textTheme.bodySmall,
                                            ),
                                          ),
                                          DataColumn(
                                            label: Text(
                                              "Action",
                                              style: Theme.of(
                                                context,
                                              ).textTheme.bodySmall,
                                            ),
                                          ),
                                        ],
                                        rows: controllerWatch.paginatedItems
                                            .map(
                                              (project) => _buildDataRow(
                                                context,
                                                project,
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
                              padding: EdgeInsets.symmetric(
                                horizontal: 16.0,
                                vertical: 12.0,
                              ),
                              child: PaginationControls<ProjectModel>(),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            if (state is ProjectsError) {
              return Center(
                child: Text(
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

  Widget _buildFilterRow({required ValueChanged<String> onSearchChanged}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [_searchBox(onSearchChanged: onSearchChanged)],
    );
  }

  Widget _buildActionRow(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            if (permissions?.canCreate ?? false) ...[
              ElevatedButton.icon(
                onPressed: () {
                  if (kIsMobile) {
                    Sheet.showSheet(context, widget: const ProjectCreate());
                  } else {
                    GeneralDialog.showRTLSheet(context, const ProjectCreate());
                  }
                },
                icon: const Icon(Icons.add, size: 18),
                label: Text(
                  "Add $_pageTitle",
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: Colors.white),
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
              if (_selectedProjects.isNotEmpty) ...[
                ElevatedButton.icon(
                  label: Text(
                    "Delete",
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: Colors.white),
                  ),
                  icon: const Icon(Iconsax.trash),
                  onPressed: () async {
                    if (_selectedProjects.isEmpty) return;

                    for (var project in _selectedProjects) {
                      final isAssigned = await ProjectService.isProjectAssigned(
                        project.uid ?? '',
                      );

                      if (isAssigned) {
                        await showDialog(
                          context: context,
                          builder: (_) => AlertDialog(
                            title: Text(
                              'Cannot Delete',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            content: Text(
                              'One or more selected projects are associated with tasks and cannot be deleted.',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            actions: [
                              TextButton(
                                onPressed: () {
                                  if (Navigator.canPop(context)) {
                                    Navigator.pop(context);
                                  }
                                },
                                child: Text(
                                  'OK',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ),
                            ],
                          ),
                        );
                        return;
                      }
                    }
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (context) => ConfirmDialog(
                        title: 'Delete',
                        content:
                            'Are you sure want to delete this $_pageTitle?',
                      ),
                      barrierDismissible: false,
                    );

                    if (confirm == true) {
                      context.read<ProjectsBloc>().add(
                        DeleteProjects(uid: 'uid'),
                      );
                      FlushBar.show(
                        context,
                        'Projects deleted successfully',
                        isSuccess: true,
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.danger,
                    foregroundColor: AppColors.white,
                  ),
                ),
              ],
            ] else ...[
              ElevatedButton.icon(
                label: Text(
                  "Delete",
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: Colors.white),
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
        ),
      ],
    );
  }

  DataRow _buildDataRow(
    BuildContext context,
    ProjectModel project,
    PaginatedDataController<ProjectModel> controllerWatch,
    PaginatedDataController<ProjectModel> controllerRead,
  ) {
    bool isSelected = controllerWatch.selectedIds.contains(project.uid);
    return DataRow(
      selected: isSelected,
      onSelectChanged: (selected) {
        controllerRead.onSelected(project.uid ?? '', selected);
        if (selected ?? false) {
          _selectedProjects.add(project);
        } else {
          _selectedProjects.remove(project);
        }
        setState(() {});
      },
      cells: [
        DataCell(
          Text(
            project.projectName,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
        DataCell(
          Text(
            project.projectCode ?? '',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
        DataCell(
          Text(
            CacheService.getUserByUid(project.projectOwner)?.name ?? '',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
        DataCell(
          Text(
            project.deadline != null ? project.deadline!.listingDateTime : '',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
        DataCell(CreatedByWidget(userData: project.createdBy)),
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
                        widget: ProjectEdit(uid: project.uid ?? ''),
                      );
                    } else {
                      GeneralDialog.showRTLSheet(
                        context,
                        ProjectEdit(uid: project.uid ?? ''),
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
                  onPressed: () async {
                    final isAssigned = await ProjectService.isProjectAssigned(
                      project.uid ?? '',
                    );

                    if (isAssigned) {
                      await showDialog(
                        context: context,
                        builder: (_) => AlertDialog(
                          title: Text(
                            'Cannot Delete',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          content: Text(
                            'This project is associated with one or more task and cannot be deleted.',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          actions: [
                            TextButton(
                              onPressed: () {
                                if (Navigator.canPop(context)) {
                                  Navigator.pop(context);
                                }
                              },
                              child: Text(
                                'OK',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ),
                          ],
                        ),
                      );
                      return;
                    }

                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (_) => ConfirmDialog(
                        title: 'Delete $_pageTitle',
                        content:
                            'Are you sure you want to delete this $_pageTitle?',
                      ),
                    );

                    if (confirm == true) {
                      context.read<ProjectsBloc>().add(
                        DeleteProjects(uid: 'uid'),
                      );
                      FlushBar.show(
                        context,
                        'Projects deleted successfully',
                        isSuccess: true,
                      );
                    }
                  },
                  color: AppColors.danger,
                  splashRadius: 20,
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

  Widget _searchBox({required ValueChanged<String> onSearchChanged}) {
    return SizedBox(
      width: 200,
      child: ListingSearchField(
        onChanged: onSearchChanged,
        pageTitle: _pageTitle,
      ),
    );
  }
}
