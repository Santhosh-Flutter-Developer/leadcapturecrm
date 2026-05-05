import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';
import '/models/models.dart';
import '/views/views.dart';
import '/utils/utils.dart';
import '/theme/theme.dart';
import '/services/services.dart';
import 'bloc/designation_bloc.dart';

const String _pageTitle = "Designation";

class DesignationListing extends StatelessWidget {
  const DesignationListing({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => DesignationBloc()..add(StreamDesignation()),
      child: ChangeNotifierProvider(
        create: (context) => PaginatedDataController<DesignationModel>(
          initialSortColumnIndex: 1,
          filterLogic: (designation, query) {
            final q = query.toLowerCase();
            return designation.name.toLowerCase().contains(q) ||
                designation.name.toLowerCase().contains(q);
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
          getItemId: (designation) => designation.uid ?? '',
        ),
        child: const DesignationListingView(),
      ),
    );
  }
}

class DesignationListingView extends StatefulWidget {
  const DesignationListingView({super.key});

  @override
  State<DesignationListingView> createState() => _DesignationListingViewState();
}

class _DesignationListingViewState extends State<DesignationListingView> {
  final List<DesignationModel> _selectedDesignations = [];
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
        .read<PaginatedDataController<DesignationModel>>();
    final controllerWatch = context
        .watch<PaginatedDataController<DesignationModel>>();

    return Scaffold(
      appBar: kIsMobile
          ? AppBar(leading: Back(), title: Text(_pageTitle))
          : null,
      body: BlocListener<DesignationBloc, DesignationState>(
        listenWhen: (previous, current) => current is DesignationLoaded,
        listener: (context, state) {
          if (state is DesignationLoaded) {
            controllerRead.setData(state.designation);
          }
        },
        child: BlocBuilder<DesignationBloc, DesignationState>(
          builder: (context, state) {
            if (state is DesignationLoading) {
              return const WaitingLoading();
            }

            if (state is DesignationLoaded) {
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
                          color: Theme.of(context).colorScheme.surface,
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
                                          DataColumn(
                                            label: Row(
                                              children: [
                                                Text(
                                                  "Name",
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
                                                  "Desc",
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
                                                  "Created",
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
                                              (designation) => _buildDataRow(
                                                context,
                                                designation,
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
                              child: PaginationControls<DesignationModel>(),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            if (state is DesignationError) {
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

  Widget _buildActionRow(context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            (permissions?.canCreate ?? false)
                ? ElevatedButton.icon(
                    onPressed: () async {
                      if (kIsMobile) {
                        Sheet.showSheet(
                          context,
                          widget: const DesignationCreate(),
                        );
                      } else {
                        GeneralDialog.showRTLSheet(
                          context,
                          const DesignationCreate(),
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
                      "Add Role",
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
            if (_selectedDesignations.isNotEmpty) ...[
              (permissions?.canDelete ?? false)
                  ? ElevatedButton.icon(
                      label: Text(
                        "Delete",
                        style: Theme.of(
                          context,
                        ).textTheme.bodySmall?.copyWith(color: AppColors.white),
                      ),
                      icon: Icon(Iconsax.trash),
                      onPressed: () async {
                        var result = await showDialog(
                          context: context,
                          builder: (context) => ConfirmDialog(
                            title: 'Delete',
                            content:
                                'Are you sure want to delete this $_pageTitle?',
                          ),
                          barrierDismissible: false,
                        );
                        if (result != null && result) {
                          try {
                            futureLoading(context);
                            for (var i in _selectedDesignations) {
                              await DesignationService.deleteDesignation(
                                uid: i.uid ?? '',
                              );
                            }
                            if (Navigator.canPop(context)) {
                              Navigator.pop(context);
                            }
                            FlushBar.show(
                              context,
                              '$_pageTitle deleted successfully',
                            );
                            _selectedDesignations.clear();
                            setState(() {});
                          } catch (e) {
                            if (Navigator.canPop(context)) {
                              Navigator.pop(context);
                            }
                            FlushBar.show(
                              context,
                              e.toString(),
                              isSuccess: false,
                            );
                          }
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
    DesignationModel designation,
    PaginatedDataController<DesignationModel> controllerWatch,
    PaginatedDataController<DesignationModel> controllerRead,
  ) {
    bool isSelected = controllerWatch.selectedIds.contains(designation.uid);
    return DataRow(
      selected: isSelected,
      onSelectChanged: (selected) {
        controllerRead.onSelected(designation.uid ?? '', selected);
        if (selected ?? false) {
          _selectedDesignations.add(designation);
        } else {
          _selectedDesignations.remove(designation);
        }
        setState(() {});
      },
      cells: [
        DataCell(
          Text(
            designation.name,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w500),
          ),
        ),
        DataCell(
          Text(
            designation.description,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
        DataCell(
          Text(
            designation.createdAt.listingDateTime,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
        DataCell(CreatedByWidget(userData: designation.createdBy)),
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
                            widget: DesignationEdit(uid: designation.uid ?? ''),
                          );
                        } else {
                          GeneralDialog.showRTLSheet(
                            context,
                            DesignationEdit(uid: designation.uid ?? ''),
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
                      onPressed: () async {
                        var result = await showDialog(
                          context: context,
                          builder: (context) {
                            return const ConfirmDialog(
                              title: 'Delete $_pageTitle',
                              content:
                                  'Are you sure want to delete this $_pageTitle',
                            );
                          },
                        );
                        if (result != null && result) {
                          try {
                            await DesignationService.deleteDesignation(
                              uid: designation.uid ?? '',
                            );
                            FlushBar.show(
                              context,
                              '$_pageTitle deleted successfully',
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
                        }
                      },
                      color: AppColors.danger,
                      splashRadius: 20,
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
