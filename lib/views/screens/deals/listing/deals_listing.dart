import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';
import '/views/views.dart';
import '/utils/utils.dart';
import '/theme/theme.dart';
import '/models/models.dart';
import '/services/services.dart';
import 'package:collection/collection.dart';

const String _pageTitle = "Deals";

class DealsListing extends StatelessWidget {
  final bool showAppBar;
  const DealsListing({super.key, this.showAppBar = true});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => DealBloc()..add(StreamDeals()),
      child: ChangeNotifierProvider(
        create: (context) => PaginatedDataController<DealModel>(
          initialSortColumnIndex: 1,
          filterLogic: (deal, query) {
            final q = query.toLowerCase();
            return deal.dealName.toLowerCase().contains(q) ||
                deal.dealEmail.toLowerCase().contains(q);
          },
          sortLogic: (a, b, col, asc) {
            int compare;
            switch (col) {
              case 1:
                compare = (a.dealNumber ?? 0).compareTo((b.dealNumber ?? 0));
                break;
              case 2:
                compare = a.dealName.toLowerCase().compareTo(
                  b.dealName.toLowerCase(),
                );
                break;
              case 3:
                compare = a.dealEmail.toLowerCase().compareTo(
                  b.dealEmail.toLowerCase(),
                );
                break;
              case 5:
                compare = a.dealValue.compareTo(b.dealValue);
                break;
              case 6:
                compare = a.createdAt.compareTo(b.createdAt);
                break;
              default:
                compare = (a.uid ?? '').compareTo(b.uid ?? '');
                break;
            }
            return asc ? compare : -compare;
          },
          getItemId: (deal) => deal.uid ?? '',
        ),
        child: DealsListingView(showAppBar: showAppBar),
      ),
    );
  }
}

class DealsListingView extends StatefulWidget {
  final bool showAppBar;
  const DealsListingView({super.key, this.showAppBar = true});
  @override
  State<DealsListingView> createState() => _DealsListingViewState();
}

class _DealsListingViewState extends State<DealsListingView> {
  String _selectedView = 'Grid';
  final List<DealModel> _selectedDeals = [];
  List<DealModel> _filteredDeals = [];

  DateTime? _fromDate;
  DateTime? _toDate;

  String? _selectedStatus;
  String? _selectedCreatedBy;

  double? _minDealValue;
  double? _maxDealValue;

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

  List<String> statusItems(Box<Map<dynamic, dynamic>> box) {
    return box.keys.map((key) {
      final data = box.get(key) ?? {};
      final model = LeadStatusModel.fromMap(
        key,
        Map<String, dynamic>.from(data),
      );
      return model.name;
    }).toList();
  }

  List<String> employeeItems(CacheService cache) {
    return cache.getAllListenableEmployees().value.map((e) => e.name).toList();
  }

  @override
  Widget build(BuildContext context) {
    final controllerRead = context.read<PaginatedDataController<DealModel>>();
    final controllerWatch = context.watch<PaginatedDataController<DealModel>>();

    return Scaffold(
      appBar: widget.showAppBar && kIsMobile
          ? AppBar(title: Text(_pageTitle))
          : null,
      body: BlocListener<DealBloc, DealState>(
        listenWhen: (previous, current) => current is DealLoaded,
        listener: (context, state) {
          if (state is DealLoaded) {
            controllerRead.setData(state.deals);
            setState(() {
              _filteredDeals = state.deals;
            });
          }
        },
        child: BlocBuilder<DealBloc, DealState>(
          builder: (context, state) {
            if (state is DealLoading) {
              return const WaitingLoading();
            }

            if (state is DealLoaded) {
              if (!(permissions?.canView ?? false)) {
                return buildNoPermissionView(context);
              }
              return SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildFilterRow(
                        onSearchChanged: controllerRead.setSearch,
                      ),
                      const SizedBox(height: 10),
                      _buildActionRow(context),
                      const SizedBox(height: 20),
                      if (_selectedView == 'Grid') ...[
                        DealKanbanListing(dealList: _filteredDeals),
                      ] else ...[
                        _buildListView(controllerWatch, controllerRead),
                      ],
                    ],
                  ),
                ),
              );
            }

            if (state is DealError) {
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

  Container _buildListView(
    PaginatedDataController<DealModel> controllerWatch,
    PaginatedDataController<DealModel> controllerRead,
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
              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: ConstrainedBox(
                  constraints: BoxConstraints(minWidth: constraints.maxWidth),
                  child: DataTable(
                    showCheckboxColumn: true,
                    sortColumnIndex: controllerWatch.sortColumnIndex,
                    sortAscending: controllerWatch.sortAscending,
                    headingRowColor: WidgetStateProperty.all(AppColors.grey100),
                    headingTextStyle: Theme.of(context).textTheme.bodySmall
                        ?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.black,
                        ),
                    columns: [
                      DataColumn(
                        label: Text(
                          "Id",
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        onSort: controllerRead.setSort,
                      ),
                      DataColumn(
                        label: Text(
                          "Name",
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        onSort: controllerRead.setSort,
                      ),
                      DataColumn(
                        label: Text(
                          "Email",
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        onSort: controllerRead.setSort,
                      ),
                      DataColumn(
                        label: Text(
                          "Value",
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          "Status",
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          "Created",
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        onSort: controllerRead.setSort,
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
                          (deal) => _buildDataRow(
                            context,
                            deal,
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
            padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            child: PaginationControls<DealModel>(),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterRow({required ValueChanged<String> onSearchChanged}) {
    final statusBox = Hive.box<Map<dynamic, dynamic>>('dealStatus');
    final cache = CacheService();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Search Box
        SizedBox(
          width: 250,
          child: ListingSearchField(
            onChanged: onSearchChanged,
            pageTitle: _pageTitle,
          ),
        ),
        const SizedBox(height: 12),

        // Filters Row
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              // From Date
              _dateFilter(
                label: "From Date",
                value: _fromDate,
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                    initialDate: _fromDate ?? DateTime.now(),
                  );
                  if (picked != null) {
                    setState(() => _fromDate = picked);
                    _applyFilters();
                  }
                },
              ),
              const SizedBox(width: 10),

              // To Date
              _dateFilter(
                label: "To Date",
                value: _toDate,
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                    initialDate: _toDate ?? DateTime.now(),
                  );
                  if (picked != null) {
                    setState(() => _toDate = picked);
                    _applyFilters();
                  }
                },
              ),
              const SizedBox(width: 10),

              // Status Dropdown
              _filterDropdown(
                label: "Status",
                value: _selectedStatus != null
                    ? CacheService.dealStatusByUid(_selectedStatus!)?.name
                    : null,
                items: statusItems(statusBox),
                onChanged: (v) {
                  final selectedModel = statusBox.keys.firstWhere(
                    (key) => CacheService.dealStatusByUid(key)?.name == v,
                    orElse: () => '',
                  );
                  setState(() => _selectedStatus = selectedModel);
                  _applyFilters();
                },
              ),
              const SizedBox(width: 10),

              _filterDropdown(
                label: "Created By",
                value: _selectedCreatedBy != null
                    ? cache
                          .getAllListenableEmployees()
                          .value
                          .firstWhere((e) => e.uid == _selectedCreatedBy)
                          .name
                    : null,
                items: employeeItems(cache),
                onChanged: (v) {
                  final selectedEmployee = cache
                      .getAllListenableEmployees()
                      .value
                      .firstWhereOrNull((e) => e.name == v);
                  setState(() => _selectedCreatedBy = selectedEmployee?.uid);
                  _applyFilters();
                },
              ),
              const SizedBox(width: 10),

              _valueRangeFilter(onChanged: _onDealValueRangeChanged),
            ],
          ),
        ),
      ],
    );
  }

  Widget _valueRangeFilter({
    required ValueChanged<String> onChanged,
    double itemWidth = 180,
  }) {
    return SizedBox(
      width: itemWidth,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Deal Value",
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.black,
              fontWeight: FontWeight.w500,
            ),
          ),

          const SizedBox(height: 8),
          Container(
            height: 32,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade700),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.currency_rupee,
                  size: 18,
                  color: Colors.grey.shade600,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    keyboardType: TextInputType.number,
                    onChanged: onChanged,
                    style: Theme.of(context).textTheme.bodySmall,
                    decoration: const InputDecoration(
                      isDense: true,
                      hintText: "1000 - 5000",
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _onDealValueRangeChanged(String value) {
    _minDealValue = null;
    _maxDealValue = null;

    final cleaned = value.replaceAll(' ', '');

    if (!cleaned.contains('-')) {
      _applyFilters();
      return;
    }

    final parts = cleaned.split('-');
    if (parts.length != 2) {
      _applyFilters();
      return;
    }

    final from = double.tryParse(parts[0]);
    final to = double.tryParse(parts[1]);

    if (from == null || to == null) {
      _applyFilters();
      return;
    }

    if (from > to) {
      // invalid range → ignore filter
      _applyFilters();
      return;
    }

    _minDealValue = from;
    _maxDealValue = to;

    _applyFilters();
  }

  Widget _dateFilter({
    required String label,
    required DateTime? value,
    required VoidCallback onTap,
    double itemWidth = 180,
  }) {
    return SizedBox(
      width: itemWidth,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.black,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: onTap,
            child: Container(
              height: 32,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade700),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                children: [
                  Icon(
                    Iconsax.calendar_1,
                    size: 18,
                    color: Colors.grey.shade600,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      value == null
                          ? "Select $label"
                          : "${value.day.toString().padLeft(2, '0')}/"
                                "${value.month.toString().padLeft(2, '0')}/"
                                "${value.year}",
                      style: Theme.of(context).textTheme.bodySmall,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const Icon(
                    Icons.arrow_drop_down,
                    color: Colors.grey,
                    size: 18,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _filterDropdown({
    required String label,
    required String? value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
    double itemWidth = 180,
  }) {
    return SizedBox(
      width: itemWidth,
      child: FormDropdownSearch(
        label: label,
        items: items,
        initialItem: value,
        onChanged: (dynamic val) {
          onChanged(val as String?);
        },
        validator: (val) => val == null ? "* Required" : null,
      ),
    );
  }

  void _applyFilters() {
    final controller = context.read<PaginatedDataController<DealModel>>();
    final List<DealModel> allDeals =
        context.read<DealBloc>().state is DealLoaded
        ? (context.read<DealBloc>().state as DealLoaded).deals
        : <DealModel>[];

    List<DealModel> filtered = allDeals;

    if (_fromDate != null) {
      filtered = filtered
          .where((e) => !e.createdAt.isBefore(_fromDate!))
          .toList();
    }

    if (_toDate != null) {
      filtered = filtered.where((e) => !e.createdAt.isAfter(_toDate!)).toList();
    }

    if (_selectedStatus != null) {
      filtered = filtered
          .where((e) => e.dealStatus == _selectedStatus)
          .toList();
    }

    if (_selectedCreatedBy != null) {
      filtered = filtered
          .where((e) => e.createdBy.uid == _selectedCreatedBy)
          .toList();
    }

    if (_minDealValue != null && _maxDealValue != null) {
      filtered = filtered
          .where(
            (e) =>
                e.dealValue >= _minDealValue! && e.dealValue <= _maxDealValue!,
          )
          .toList();
    }

    setState(() {
      _filteredDeals = filtered;
    });

    controller.setData(filtered);
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
                    Sheet.showSheet(context, widget: const DealCreate());
                  } else {
                    GeneralDialog.showRTLSheet(context, const DealCreate());
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
              if (_selectedDeals.isNotEmpty)
                ElevatedButton.icon(
                  label: Text(
                    "Delete",
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  icon: const Icon(Iconsax.trash),
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
                        for (var i in _selectedDeals) {
                          await DealService.deleteDeal(uid: i.uid ?? '');
                        }
                        if (Navigator.canPop(context)) {
                          Navigator.pop(context);
                        }
                        FlushBar.show(
                          context,
                          '$_pageTitle deleted successfully',
                        );
                        _selectedDeals.clear();
                        setState(() {});
                      } catch (e) {
                        if (Navigator.canPop(context)) {
                          Navigator.pop(context);
                        }
                        FlushBar.show(context, e.toString(), isSuccess: false);
                      }
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
                  style: Theme.of(context).textTheme.bodySmall,
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
            border: Border.all(color: AppColors.grey300),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                onPressed: () {
                  _selectedView = 'Grid';
                  setState(() {});
                },
                icon: const Icon(Iconsax.grid_3, size: 18),
                color: _selectedView == 'Grid'
                    ? AppColors.blue
                    : AppColors.grey700,
              ),
              Container(width: 1, color: AppColors.grey300),
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

  DataRow _buildDataRow(
    BuildContext context,
    DealModel deal,
    PaginatedDataController<DealModel> controllerWatch,
    PaginatedDataController<DealModel> controllerRead,
  ) {
    bool isSelected = controllerWatch.selectedIds.contains(deal.uid);
    return DataRow(
      selected: isSelected,
      onSelectChanged: (selected) {
        controllerRead.onSelected(deal.uid ?? '', selected);
        if (selected ?? false) {
          _selectedDeals.add(deal);
        } else {
          _selectedDeals.remove(deal);
        }
        setState(() {});
      },
      cells: [
        DataCell(
          Text(
            deal.dealNumber.toString(),
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w500),
          ),
        ),
        DataCell(
          InkWell(
            onTap: () {
              if (kIsMobile) {
                Sheet.showSheet(
                  context,
                  widget: BlocProvider(
                    create: (_) =>
                        DealBloc()..add(StreamDealComments(deal.uid!)),
                    child: DealsView(deal: deal),
                  ),
                );
              } else {
                GeneralDialog.showRTLSheet(
                  context,
                  BlocProvider(
                    create: (_) =>
                        DealBloc()..add(StreamDealComments(deal.uid!)),
                    child: DealsView(deal: deal),
                  ),
                );
              }
            },
            child: Text(
              deal.dealName,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w500),
            ),
          ),
        ),
        DataCell(
          Text(deal.dealEmail, style: Theme.of(context).textTheme.bodySmall),
        ),
        DataCell(
          Text(
            deal.dealValue.toString(),
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
        DataCell(
          Text(
            CacheService.dealStatusByUid(deal.dealStatus ?? '')?.name ?? '',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
        DataCell(
          Text(
            deal.createdAt.listingDateTime,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
        DataCell(CreatedByWidget(userData: deal.createdBy)),
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
                        widget: DealEdit(uid: deal.uid ?? ''),
                      );
                    } else {
                      GeneralDialog.showRTLSheet(
                        context,
                        DealEdit(uid: deal.uid ?? ''),
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
                  onPressed: () async {
                    // Ask for confirmation first
                    final result = await showDialog<bool>(
                      context: context,
                      builder: (context) {
                        return ConfirmDialog(
                          title: 'Delete $_pageTitle',
                          content:
                              'Are you sure you want to delete this $_pageTitle?',
                        );
                      },
                    );

                    if (result == true) {
                      try {
                        await DealService.deleteDeal(uid: deal.uid ?? '');

                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (context.mounted) {
                            FlushBar.show(
                              context,
                              '$_pageTitle deleted successfully',
                            );
                          }
                        });
                      } catch (e, st) {
                        await ErrorService.recordError(e, st);
                        if (context.mounted) {
                          FlushBar.show(
                            context,
                            'Failed to delete $_pageTitle: $e',
                          );
                        }
                      }
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
