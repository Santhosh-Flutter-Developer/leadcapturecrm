import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';
import '/models/models.dart';
import '/views/views.dart';
import '/utils/utils.dart';
import '/theme/theme.dart';
import '/services/services.dart';
import 'bloc/department_bloc.dart';

const String _pageTitle = "Department";

class DepartmentListing extends StatelessWidget {
  const DepartmentListing({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => DepartmentBloc()..add(StreamDepartment()),
      child: ChangeNotifierProvider(
        create: (context) => PaginatedDataController<DepartmentModel>(
          initialSortColumnIndex: 1,
          filterLogic: (department, query) {
            final q = query.toLowerCase();
            return department.name.toLowerCase().contains(q) ||
                department.name.toLowerCase().contains(q);
          },
          sortLogic: (a, b, col, asc) {
            int compare;
            switch (col) {
              case 2:
                compare = a.name.toLowerCase().compareTo(b.name.toLowerCase());
                break;
              case 3:
                compare = a.description.toLowerCase().compareTo(
                  b.description.toLowerCase(),
                );
                break;
              default:
                compare = (a.uid ?? '').compareTo(b.uid ?? '');
                break;
            }
            return asc ? compare : -compare;
          },
          getItemId: (department) => department.uid ?? '',
        ),
        child: const DepartmentListingView(),
      ),
    );
  }
}

class DepartmentListingView extends StatefulWidget {
  const DepartmentListingView({super.key});

  @override
  State<DepartmentListingView> createState() => _DepartmentListingViewState();
}

class _DepartmentListingViewState extends State<DepartmentListingView> {
  final List<DepartmentModel> _selectedDepartments = [];
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

  Future<void> _refreshDepartments(BuildContext context) async {
    context.read<DepartmentBloc>().add(StreamDepartment());
  }

  @override
  Widget build(BuildContext context) {
    final controllerRead = context
        .read<PaginatedDataController<DepartmentModel>>();
    final controllerWatch = context
        .watch<PaginatedDataController<DepartmentModel>>();

    return Scaffold(
      appBar: kIsMobile
          ? AppBar(leading: Back(), title: Text(_pageTitle))
          : null,
      body: BlocListener<DepartmentBloc, DepartmentState>(
        listenWhen: (previous, current) => current is DepartmentLoaded,
        listener: (context, state) {
          if (state is DepartmentLoaded) {
            controllerRead.setData(state.department);
          }
        },
        child: BlocBuilder<DepartmentBloc, DepartmentState>(
          builder: (context, state) {
            if (state is DepartmentLoading) {
              return const WaitingLoading();
            }

            if (state is DepartmentLoaded) {
              if (!(permissions?.canView ?? false)) {
                return buildNoPermissionView(context);
              }
              return RefreshIndicator(
                onRefresh: () => _refreshDepartments(context),
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(24.0),
                  children: [
                    _buildFilterRow(onSearchChanged: controllerRead.setSearch),
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
                                      headingRowColor: WidgetStateProperty.all(
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
                                        DataColumn(
                                          label: Row(
                                            children: [
                                              Text("Name"),
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
                                              Text("Desc"),
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
                                              Text("Created"),
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
                                        const DataColumn(
                                          label: Text("Created By"),
                                        ),
                                        const DataColumn(label: Text("Action")),
                                      ],
                                      rows: controllerWatch.paginatedItems
                                          .map(
                                            (department) => _buildDataRow(
                                              context,
                                              department,
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
                            child: PaginationControls<DepartmentModel>(),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }

            if (state is DepartmentError) {
              return Center(child: Text(state.message));
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

  Widget _buildActionRow(context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            (permissions?.canCreate ?? false)
                ? ElevatedButton.icon(
                    onPressed: () {
                      if (kIsMobile) {
                        Sheet.showSheet(
                          context,
                          widget: const DepartmentCreate(),
                        );
                      } else {
                        GeneralDialog.showRTLSheet(
                          context,
                          const DepartmentCreate(),
                        );
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
                  )
                : ElevatedButton.icon(
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
            const SizedBox(width: 10),
            if (_selectedDepartments.isNotEmpty) ...[
              (permissions?.canDelete ?? false)
                  ? ElevatedButton.icon(
                      label: Text(
                        "Delete",
                        style: Theme.of(
                          context,
                        ).textTheme.bodySmall?.copyWith(color: AppColors.white),
                      ),
                      icon: const Icon(Iconsax.trash),
                      onPressed: () async {
                        if (_selectedDepartments.isEmpty) return;

                        final result = await showDialog<bool>(
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
                          // ✅ STEP 1: BACKUP
                          final deletedDepartments = _selectedDepartments
                              .map((e) => e.copyWith())
                              .toList();

                          // ✅ STEP 2: loader
                          futureLoading(context);

                          // ✅ STEP 3: DELETE
                          for (var dept in deletedDepartments) {
                            await DepartmentService.deleteDepartment(
                              uid: dept.uid ?? '',
                            );
                          }

                          // ✅ STEP 4: close loader
                          if (Navigator.canPop(context)) Navigator.pop(context);

                          // ✅ STEP 5: clear selection
                          _selectedDepartments.clear();
                          setState(() {});

                          // ✅ STEP 6: UNDO
                          FlushBar.show(
                            context,
                            '$_pageTitle deleted successfully',
                            actionLabel: 'UNDO',
                            onActionPressed: () async {
                              for (var dept in deletedDepartments) {
                                if (dept.uid == null) continue;

                                await DepartmentService.restoreDepartment(dept);
                              }

                              if (!context.mounted) return;

                              // ✅ refresh UI
                              context.read<DepartmentBloc>().add(
                                StreamDepartment(),
                              );
                            },
                          );
                        } catch (e, st) {
                          if (Navigator.canPop(context)) Navigator.pop(context);

                          await ErrorService.recordError(e, st);

                          FlushBar.show(
                            context,
                            e.toString(),
                            isSuccess: false,
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.danger,
                        foregroundColor: AppColors.white,
                      ),
                    )
                  : ElevatedButton.icon(
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
        ),
      ],
    );
  }

  DataRow _buildDataRow(
    BuildContext context,
    DepartmentModel department,
    PaginatedDataController<DepartmentModel> controllerWatch,
    PaginatedDataController<DepartmentModel> controllerRead,
  ) {
    bool isSelected = controllerWatch.selectedIds.contains(department.uid);
    return DataRow(
      selected: isSelected,
      onSelectChanged: (selected) {
        controllerRead.onSelected(department.uid ?? '', selected);

        if (selected ?? false) {
          _selectedDepartments.add(department);
        } else {
          _selectedDepartments.remove(department);
        }
        setState(() {});
      },
      cells: [
        DataCell(
          Text(
            department.name,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w500),
          ),
        ),
        DataCell(Text(department.description)),
        DataCell(Text(department.createdAt.listingDateTime)),
        DataCell(CreatedByWidget(userData: department.createdBy)),
        DataCell(
          Row(
            children: [
              (permissions?.canEdit ?? false)
                  ? IconButton(
                      icon: const Icon(Iconsax.edit),
                      onPressed: () {
                        if (kIsMobile) {
                          Sheet.showSheet(
                            context,
                            widget: DepartmentEdit(uid: department.uid ?? ''),
                          );
                        } else {
                          GeneralDialog.showRTLSheet(
                            context,
                            DepartmentEdit(uid: department.uid ?? ''),
                          );
                        }
                      },
                      color: AppColors.info,
                      splashRadius: 20,
                    )
                  : IconButton(
                      icon: Icon(Iconsax.edit, color: AppColors.grey400),
                      onPressed: null,
                    ),
              (permissions?.canDelete ?? false)
                  ? IconButton(
                      icon: const Icon(Iconsax.trash),
                      color: AppColors.danger,
                      splashRadius: 20,
                      onPressed: () async {
                        final result = await showDialog<bool>(
                          context: context,
                          builder: (context) => ConfirmDialog(
                            title: 'Delete $_pageTitle',
                            content:
                                'Are you sure want to delete this $_pageTitle',
                          ),
                        );

                        if (result != true) return;

                        try {
                          // ✅ STEP 1: BACKUP
                          final deletedDepartment = department.copyWith();

                          // ✅ STEP 2: DELETE
                          await DepartmentService.deleteDepartment(
                            uid: department.uid ?? '',
                          );

                          if (!context.mounted) return;

                          // ✅ STEP 3: SHOW UNDO
                          FlushBar.show(
                            context,
                            '$_pageTitle deleted successfully',
                            actionLabel: 'UNDO',
                            onActionPressed: () async {
                              if (deletedDepartment.uid == null) return;

                              // ✅ STEP 4: RESTORE
                              await DepartmentService.restoreDepartment(
                                deletedDepartment,
                              );

                              if (!context.mounted) return;

                              // ✅ STEP 5: REFRESH UI
                              context.read<DepartmentBloc>().add(
                                StreamDepartment(),
                              );
                            },
                          );
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
                      },
                    )
                  : IconButton(
                      icon: Icon(Iconsax.trash, color: AppColors.grey400),
                      onPressed: null,
                    ),
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
