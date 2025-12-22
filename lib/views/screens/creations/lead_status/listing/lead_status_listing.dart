import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';
import '/models/models.dart';
import '/views/views.dart';
import '/utils/utils.dart';
import '/theme/theme.dart';
import '/services/services.dart';
import 'bloc/lead_status_bloc.dart';

const String _pageTitle = "Lead Status";

class LeadStatusListing extends StatelessWidget {
  const LeadStatusListing({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => LeadStatusBloc()..add(StreamLeadStatus()),
      child: ChangeNotifierProvider(
        create: (context) => PaginatedDataController<LeadStatusModel>(
          initialSortColumnIndex: 1,
          filterLogic: (leadStatus, query) {
            final q = query.toLowerCase();
            return leadStatus.name.toLowerCase().contains(q) ||
                leadStatus.name.toLowerCase().contains(q);
          },
          sortLogic: (a, b, col, asc) {
            int compare;
            switch (col) {
              case 1:
                compare = a.orderNumber.compareTo(b.orderNumber);
                break;
              case 2:
                compare = a.name.toLowerCase().compareTo(b.name.toLowerCase());
                break;
              default:
                compare = (a.uid ?? '').compareTo(b.uid ?? '');
                break;
            }
            return asc ? compare : -compare;
          },
          getItemId: (leadStatus) => leadStatus.uid ?? '',
        ),
        child: const LeadStatusListingView(),
      ),
    );
  }
}

class LeadStatusListingView extends StatefulWidget {
  const LeadStatusListingView({super.key});

  @override
  State<LeadStatusListingView> createState() => _LeadStatusListingViewState();
}

class _LeadStatusListingViewState extends State<LeadStatusListingView> {
  final List<LeadStatusModel> _selectedLeadStatus = [];
  PermissionModel? permissions;

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
        .read<PaginatedDataController<LeadStatusModel>>();
    final controllerWatch = context
        .watch<PaginatedDataController<LeadStatusModel>>();

    return Scaffold(
      appBar: kIsMobile
          ? AppBar(leading: Back(), title: Text(_pageTitle))
          : null,
      body: BlocListener<LeadStatusBloc, LeadStatusState>(
        listenWhen: (previous, current) => current is LeadStatusLoaded,
        listener: (context, state) {
          if (state is LeadStatusLoaded) {
            controllerRead.setData(state.leadStatus);
          }
        },
        child: BlocBuilder<LeadStatusBloc, LeadStatusState>(
          builder: (context, state) {
            if (state is LeadStatusLoading) {
              return const WaitingLoading();
            }

            if (state is LeadStatusLoaded) {
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
                      _buildActionRow(context, state.leadStatus),
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
                                return SingleChildScrollView(
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
                                              Text(
                                                "No",
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
                                            (leadStatus) => _buildDataRow(
                                              context,
                                              leadStatus,
                                              controllerWatch,
                                              controllerRead,
                                            ),
                                          )
                                          .toList(),
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
                              child: PaginationControls<LeadStatusModel>(),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            if (state is LeadStatusError) {
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

  Widget _buildActionRow(context, List<LeadStatusModel> leadStatusList) {
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
                          widget: const LeadStatusCreate(),
                        );
                      } else {
                        GeneralDialog.showRTLSheet(
                          context,
                          const LeadStatusCreate(),
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
            if (_selectedLeadStatus.isNotEmpty) ...[
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
                        if (_selectedLeadStatus.isEmpty) return;

                        for (var status in _selectedLeadStatus) {
                          final isAssigned =
                              await LeadStatusService.isLeadStatusAssigned(
                                status.uid ?? '',
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
                                  'One or more selected lead statuses are associated with leads and cannot be deleted.',
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
                          context.read<LeadStatusBloc>().add(
                            DeleteLeadStatus(uid: 'uid'),
                          );
                          FlushBar.show(
                            context,
                            'Dealstatus deleted successfully',
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
    LeadStatusModel leadStatus,
    PaginatedDataController<LeadStatusModel> controllerWatch,
    PaginatedDataController<LeadStatusModel> controllerRead,
  ) {
    bool isSelected = controllerWatch.selectedIds.contains(leadStatus.uid);
    return DataRow(
      selected: isSelected,
      onSelectChanged: (selected) {
        controllerRead.onSelected(leadStatus.uid ?? '', selected);
        if (selected ?? false) {
          _selectedLeadStatus.add(leadStatus);
        } else {
          _selectedLeadStatus.remove(leadStatus);
        }
        setState(() {});
      },
      cells: [
        DataCell(
          Text(
            leadStatus.orderNumber.toString(),
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w500),
          ),
        ),
        DataCell(
          Text(
            leadStatus.name,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w500),
          ),
        ),
        DataCell(Icon(Icons.circle, color: Color(leadStatus.color))),
        DataCell(
          Text(
            leadStatus.createdAt.listingDateTime,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
        DataCell(CreatedByWidget(userData: leadStatus.createdBy)),
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
                            widget: LeadStatusEdit(uid: leadStatus.uid ?? ''),
                          );
                        } else {
                          GeneralDialog.showRTLSheet(
                            context,
                            LeadStatusEdit(uid: leadStatus.uid ?? ''),
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
                            await LeadStatusService.isLeadStatusAssigned(
                              leadStatus.uid ?? '',
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
                                'This lead status is assigned to one or more leads and cannot be deleted.',
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
                            context.read<LeadStatusBloc>().add(
                              DeleteLeadStatus(uid: leadStatus.uid!),
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
