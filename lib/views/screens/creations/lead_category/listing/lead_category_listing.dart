import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';
import '/models/models.dart';
import '/views/views.dart';
import '/utils/utils.dart';
import '/theme/theme.dart';
import '/services/services.dart';
import 'bloc/lead_category_bloc.dart';

const String _pageTitle = "Lead Category";

class LeadCategoryListing extends StatelessWidget {
  const LeadCategoryListing({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => LeadCategoryBloc()..add(StreamLeadCategory()),
      child: ChangeNotifierProvider(
        create: (context) => PaginatedDataController<LeadCategoryModel>(
          initialSortColumnIndex: 1,
          filterLogic: (leadCategories, query) {
            final q = query.toLowerCase();
            return leadCategories.name.toLowerCase().contains(q) ||
                leadCategories.name.toLowerCase().contains(q);
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
          getItemId: (leadCategories) => leadCategories.uid ?? '',
        ),
        child: const LeadCategoryListingView(),
      ),
    );
  }
}

class LeadCategoryListingView extends StatefulWidget {
  const LeadCategoryListingView({super.key});

  @override
  State<LeadCategoryListingView> createState() =>
      _LeadCategoryListingViewState();
}

class _LeadCategoryListingViewState extends State<LeadCategoryListingView> {
  final List<LeadCategoryModel> _selectedLeadCategories = [];
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
        .read<PaginatedDataController<LeadCategoryModel>>();
    final controllerWatch = context
        .watch<PaginatedDataController<LeadCategoryModel>>();

    return Scaffold(
      appBar: kIsMobile
          ? AppBar(leading: Back(), title: Text("Category"))
          : null,
      body: BlocListener<LeadCategoryBloc, LeadCategoryState>(
        listenWhen: (previous, current) => current is LeadCategoryLoaded,
        listener: (context, state) {
          if (state is LeadCategoryLoaded) {
            controllerRead.setData(state.leadCategory);
          }
        },
        child: BlocBuilder<LeadCategoryBloc, LeadCategoryState>(
          builder: (context, state) {
            if (state is LeadCategoryLoading) {
              return const WaitingLoading();
            }

            if (state is LeadCategoryLoaded) {
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
                                          const DataColumn(
                                            label: Text("Action"),
                                          ),
                                        ],
                                        rows: controllerWatch.paginatedItems
                                            .map(
                                              (leadCategories) => _buildDataRow(
                                                context,
                                                leadCategories,
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
                              child: PaginationControls<LeadCategoryModel>(),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            if (state is LeadCategoryError) {
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
                          widget: const LeadCategoryCreate(),
                        );
                      } else {
                        GeneralDialog.showRTLSheet(
                          context,
                          const LeadCategoryCreate(),
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
            if (_selectedLeadCategories.isNotEmpty) ...[
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
                        if (_selectedLeadCategories.isEmpty) return;

                        for (var category in _selectedLeadCategories) {
                          final isAssigned =
                              await LeadCategoryService.isLeadCategoryAssigned(
                                category.uid ?? '',
                              );

                          if (isAssigned) {
                            await showDialog(
                              context: context,
                              builder: (_) => AlertDialog(
                                title: Text('Cannot Delete'),
                                content: Text(
                                  'One or more selected lead categories are associated with leads and cannot be deleted.',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () {
                                      if (Navigator.canPop(context)) {
                                        Navigator.pop(context);
                                      }
                                    },
                                    child: Text('OK'),
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
                            title: 'Delete $_pageTitle',
                            content:
                                'Are you sure want to delete this $_pageTitle?',
                          ),
                          barrierDismissible: false,
                        );

                        if (confirm != true) return;

                        try {
                          futureLoading(context);

                          for (var category in _selectedLeadCategories) {
                            await LeadCategoryService.deleteLeadCategory(
                              uid: category.uid ?? '',
                            );
                          }

                          if (Navigator.canPop(context)) {
                            Navigator.pop(context);
                          }
                          FlushBar.show(
                            context,
                            '$_pageTitle deleted successfully',
                          );

                          _selectedLeadCategories.clear();
                          setState(() {});
                        } catch (e, st) {
                          if (Navigator.canPop(context)) {
                            Navigator.pop(context);
                          }
                          await ErrorService.recordError(e, st);

                          FlushBar.show(
                            context,
                            'Failed to delete $_pageTitle: $e',
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
    LeadCategoryModel leadCategory,
    PaginatedDataController<LeadCategoryModel> controllerWatch,
    PaginatedDataController<LeadCategoryModel> controllerRead,
  ) {
    bool isSelected = controllerWatch.selectedIds.contains(leadCategory.uid);
    return DataRow(
      selected: isSelected,
      onSelectChanged: (selected) {
        controllerRead.onSelected(leadCategory.uid ?? '', selected);
        if (selected ?? false) {
          _selectedLeadCategories.add(leadCategory);
        } else {
          _selectedLeadCategories.remove(leadCategory);
        }
        setState(() {});
      },
      cells: [
        DataCell(
          Text(
            leadCategory.name,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w500),
          ),
        ),
        DataCell(Text(leadCategory.description)),
        DataCell(Text(leadCategory.createdAt.listingDateTime)),
        DataCell(CreatedByWidget(userData: leadCategory.createdBy)),
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
                            widget: LeadCategoryEdit(
                              uid: leadCategory.uid ?? '',
                            ),
                          );
                        } else {
                          GeneralDialog.showRTLSheet(
                            context,
                            LeadCategoryEdit(uid: leadCategory.uid ?? ''),
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
                        final isAssigned =
                            await LeadCategoryService.isLeadCategoryAssigned(
                              leadCategory.uid ?? '',
                            );

                        if (isAssigned) {
                          await showDialog(
                            context: context,
                            builder: (_) => AlertDialog(
                              title: Text('Cannot Delete'),
                              content: Text(
                                'This lead category is associated with one or more leads and cannot be deleted.',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () {
                                    if (Navigator.canPop(context)) {
                                      Navigator.pop(context);
                                    }
                                  },
                                  child: Text('OK'),
                                ),
                              ],
                            ),
                          );
                          return;
                        }

                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (context) => ConfirmDialog(
                            title: 'Delete $_pageTitle',
                            content:
                                'Are you sure want to delete this $_pageTitle?',
                          ),
                          barrierDismissible: false,
                        );

                        if (confirm == true) {
                          context.read<LeadCategoryBloc>().add(
                            DeleteLeadCategory(leadCategory.uid ?? ''),
                          );

                          FlushBar.show(
                            context,
                            'Category deleted successfully',
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
