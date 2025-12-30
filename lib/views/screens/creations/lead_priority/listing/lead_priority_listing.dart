import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';
import '/models/models.dart';
import '/views/views.dart';
import '/utils/utils.dart';
import '/theme/theme.dart';
import '/services/services.dart';
import 'bloc/lead_priority_bloc.dart';

const String _pageTitle = "Lead Priority";

class LeadPriorityListing extends StatelessWidget {
  const LeadPriorityListing({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => LeadPriorityBloc()..add(StreamLeadPriority()),
      child: ChangeNotifierProvider(
        create: (context) => PaginatedDataController<LeadPriorityModel>(
          initialSortColumnIndex: 1,
          filterLogic: (leadPriority, query) {
            final q = query.toLowerCase();
            return leadPriority.name.toLowerCase().contains(q) ||
                leadPriority.name.toLowerCase().contains(q);
          },
          sortLogic: (a, b, col, asc) {
            int compare;
            switch (col) {
              case 1:
                compare = a.name.toLowerCase().compareTo(b.name.toLowerCase());
                break;
              default:
                compare = (a.uid ?? '').compareTo(b.uid ?? '');
                break;
            }
            return asc ? compare : -compare;
          },
          getItemId: (leadPriority) => leadPriority.uid ?? '',
        ),
        child: const LeadPriorityListingView(),
      ),
    );
  }
}

class LeadPriorityListingView extends StatefulWidget {
  const LeadPriorityListingView({super.key});

  @override
  State<LeadPriorityListingView> createState() =>
      _LeadPriorityListingViewState();
}

class _LeadPriorityListingViewState extends State<LeadPriorityListingView> {
  final List<LeadPriorityModel> _selectedLeadPriority = [];
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
        .read<PaginatedDataController<LeadPriorityModel>>();
    final controllerWatch = context
        .watch<PaginatedDataController<LeadPriorityModel>>();

    return Scaffold(
      appBar: kIsMobile
          ? AppBar(leading: Back(), title: Text(_pageTitle))
          : null,
      body: BlocListener<LeadPriorityBloc, LeadPriorityState>(
        listenWhen: (previous, current) => current is LeadPriorityLoaded,
        listener: (context, state) {
          if (state is LeadPriorityLoaded) {
            controllerRead.setData(state.leadPriority);
          }
        },
        child: BlocBuilder<LeadPriorityBloc, LeadPriorityState>(
          builder: (context, state) {
            if (state is LeadPriorityLoading) {
              return const WaitingLoading();
            }

            if (state is LeadPriorityLoaded) {
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
                      _buildActionRow(context, state.leadPriority),
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
                                                  "Color",
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
                                              (leadPriority) => _buildDataRow(
                                                context,
                                                leadPriority,
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
                              child: PaginationControls<LeadPriorityModel>(),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            if (state is LeadPriorityError) {
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

  Widget _buildActionRow(context, List<LeadPriorityModel> leadPriorityList) {
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
                          widget: const LeadPriorityCreate(),
                        );
                      } else {
                        GeneralDialog.showRTLSheet(
                          context,
                          const LeadPriorityCreate(),
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
            if (_selectedLeadPriority.isNotEmpty) ...[
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
                        if (_selectedLeadPriority.isEmpty) return;

                        for (var priority in _selectedLeadPriority) {
                          final isAssigned =
                              await LeadPriorityService.isLeadPriorityAssigned(
                                priority.uid ?? '',
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
                                  'One or more selected lead priorities are associated with leads and cannot be deleted.',
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
                                      style: Theme.of(
                                        context,
                                      ).textTheme.bodySmall,
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
                            title: 'Delete $_pageTitle',
                            content:
                                'Are you sure want to delete this $_pageTitle?',
                          ),
                          barrierDismissible: false,
                        );

                        if (confirm == true) {
                          context.read<LeadPriorityBloc>().add(
                            DeleteLeadPriority(uid: 'uid'),
                          );
                          FlushBar.show(
                            context,
                            'Dealpriority deleted successfully',
                            isSuccess: true,
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
    LeadPriorityModel leadPriority,
    PaginatedDataController<LeadPriorityModel> controllerWatch,
    PaginatedDataController<LeadPriorityModel> controllerRead,
  ) {
    bool isSelected = controllerWatch.selectedIds.contains(leadPriority.uid);
    return DataRow(
      selected: isSelected,
      onSelectChanged: (selected) {
        controllerRead.onSelected(leadPriority.uid ?? '', selected);
        if (selected ?? false) {
          _selectedLeadPriority.add(leadPriority);
        } else {
          _selectedLeadPriority.remove(leadPriority);
        }
        setState(() {});
      },
      cells: [
        DataCell(
          Text(
            leadPriority.name,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w500),
          ),
        ),
        DataCell(Icon(Icons.circle, color: Color(leadPriority.color))),
        DataCell(
          Text(
            leadPriority.createdAt.listingDateTime,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
        DataCell(CreatedByWidget(userData: leadPriority.createdBy)),
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
                            widget: LeadPriorityEdit(
                              uid: leadPriority.uid ?? '',
                            ),
                          );
                        } else {
                          GeneralDialog.showRTLSheet(
                            context,
                            LeadPriorityEdit(uid: leadPriority.uid ?? ''),
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
                        final isAssigned =
                            await LeadPriorityService.isLeadPriorityAssigned(
                              leadPriority.uid ?? '',
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
                                'This lead priority is assigned to one or more leads and cannot be deleted.',
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
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodySmall,
                                  ),
                                ),
                              ],
                            ),
                          );
                        } else {
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
                            context.read<LeadPriorityBloc>().add(
                              DeleteLeadPriority(uid: leadPriority.uid!),
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
