import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:iconsax/iconsax.dart';
import 'package:leadcapture/views/screens/leads/listing/lead_upload.dart';
import 'package:provider/provider.dart';
import 'package:collection/collection.dart';
import '/services/services.dart';
import '/models/models.dart';
import '/views/views.dart';
import '/utils/utils.dart';
import '/theme/theme.dart';

const String _pageTitle = "Leads";

class LeadsListing extends StatelessWidget {
  final bool showAppBar;
  const LeadsListing({super.key, this.showAppBar = true});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [BlocProvider(create: (_) => LeadBloc()..add(StreamLead()))],

      child: ChangeNotifierProvider(
        create: (context) => PaginatedDataController<LeadModel>(
          initialSortColumnIndex: 1,
          filterLogic: (lead, query) {
            final q = query.toLowerCase();
            return lead.leadName.toLowerCase().contains(q) ||
                lead.leadName.toLowerCase().contains(q);
          },
          sortLogic: (a, b, col, asc) {
            int compare;
            switch (col) {
              case 1:
                compare = (a.leadNumber ?? 0).compareTo((b.leadNumber ?? 0));
                break;
              case 2:
                compare = a.leadName.toLowerCase().compareTo(
                  b.leadName.toLowerCase(),
                );
                break;
              case 3:
                compare = a.leadEmail.toLowerCase().compareTo(
                  b.leadEmail.toLowerCase(),
                );
                break;
              case 5:
                compare = a.leadValue.compareTo(b.leadValue);
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
          getItemId: (lead) => lead.uid ?? '',
        ),
        child: LeadsListingView(showAppBar: showAppBar),
      ),
    );
  }
}

class LeadsListingView extends StatefulWidget {
  final bool showAppBar;
  const LeadsListingView({super.key, this.showAppBar = true});

  @override
  State<LeadsListingView> createState() => _LeadsListingViewState();
}

class _LeadsListingViewState extends State<LeadsListingView> {
  final ScrollController _hScrollController = ScrollController();
  String _selectedView = 'Grid';
  final List<LeadModel> _selectedLeads = [];
  final List<LeadModel> _leadsList = [];
  List<LeadModel> _filteredLeads = [];
  PermissionModel? permissions;
  String? _currentUid;
  bool _isAdmin = false;

  DateTime? _fromDate;
  DateTime? _toDate;
  String? _selectedStatus;
  String? _selectedCategory;
  String? _selectedCreatedBy;

  double? _value;

  @override
  void initState() {
    super.initState();
    _loadPermissions();
  }

  Future<void> _loadPermissions() async {
    permissions = await PermissionService.getPermissions(_pageTitle);
    _currentUid = await Spdb.getUid();
    _isAdmin = await Spdb.isAdminLoggedIn();
    setState(() {});
  }

  List<String> statusItems(Box<Map<dynamic, dynamic>> box) {
    return box.keys.map((key) {
      final data = CacheService.normalizeFromCache(box.get(key) ?? {});
      final model = LeadStatusModel.fromMap(key, data);
      return model.name;
    }).toList();
  }

  List<String> categoryItems(Box<Map<dynamic, dynamic>> box) {
    return box.keys.map((key) {
      final data = CacheService.normalizeFromCache(box.get(key) ?? {});
      final model = LeadCategoryModel.fromMap(key, data);
      return model.name;
    }).toList();
  }

  List<String> employeeItems(CacheService cache) {
    return cache.getAllListenableEmployees().value.map((e) => e.name).toList();
  }

  @override
  Widget build(BuildContext context) {
    final controllerRead = context.read<PaginatedDataController<LeadModel>>();
    final controllerWatch = context.watch<PaginatedDataController<LeadModel>>();
    return Scaffold(
      appBar: widget.showAppBar && kIsMobile
          ? AppBar(title: Text(_pageTitle))
          : null,
      body: BlocListener<LeadBloc, LeadState>(
        listenWhen: (previous, current) => current is LeadLoaded,
        listener: (context, state) {
          if (state is LeadLoaded) {
            controllerRead.setData(state.leads);
            setState(() {
              _filteredLeads = state.leads;
            });
          }
        },
        child: BlocBuilder<LeadBloc, LeadState>(
          builder: (context, state) {
            if (state is LeadLoading) {
              return const WaitingLoading();
            }

            if (state is LeadLoaded) {
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
                        LeadKanbanListing(
                          leadList: _filteredLeads,
                          onLeadDeleted: () =>
                              context.read<LeadBloc>().add(StreamLead()),
                        ),
                      ] else if (_selectedView == 'Calendar') ...[
                        LeadCalendarListing(
                          leadList: _filteredLeads,
                          onLeadCreated: () =>
                              context.read<LeadBloc>().add(StreamLead()),
                        ),
                      ] else ...[
                        _buildListView(controllerWatch, controllerRead),
                      ],
                    ],
                  ),
                ),
              );
            }

            if (state is LeadError) {
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
    PaginatedDataController<LeadModel> controllerWatch,
    PaginatedDataController<LeadModel> controllerRead,
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
                      // headingRowHeight: 40,
                      // dataRowMinHeight: 36,
                      // dataRowMaxHeight: 36,
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
                          label: IntrinsicWidth(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  "Id",
                                  style: Theme.of(context).textTheme.bodySmall,
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
                          onSort: controllerRead.setSort,
                        ),
                        DataColumn(
                          label: IntrinsicWidth(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  "Name",
                                  style: Theme.of(context).textTheme.bodySmall,
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
                          onSort: controllerRead.setSort,
                        ),
                        DataColumn(
                          label: IntrinsicWidth(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  "Email",
                                  style: Theme.of(context).textTheme.bodySmall,
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
                          onSort: controllerRead.setSort,
                        ),
                        DataColumn(
                          label: IntrinsicWidth(
                            child: Text(
                              "Mobile No",
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ),
                        ),
                        DataColumn(
                          label: IntrinsicWidth(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  "Lead Value",
                                  style: Theme.of(context).textTheme.bodySmall,
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
                          onSort: controllerRead.setSort,
                        ),
                        DataColumn(
                          label: IntrinsicWidth(
                            child: Text(
                              "Source",
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ),
                        ),
                        DataColumn(
                          label: IntrinsicWidth(
                            child: Text(
                              "Status",
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ),
                        ),
                        DataColumn(
                          label: IntrinsicWidth(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  "Created",
                                  style: Theme.of(context).textTheme.bodySmall,
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
                          onSort: controllerRead.setSort,
                        ),
                        DataColumn(
                          label: IntrinsicWidth(
                            child: Text(
                              "Created By",
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ),
                        ),
                        DataColumn(
                          label: IntrinsicWidth(
                            child: Text(
                              "Action",
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ),
                        ),
                      ],
                      rows: controllerWatch.paginatedItems.map((lead) {
                        return _buildDataRow(
                          context,
                          lead,
                          controllerWatch,
                          controllerRead,
                        );
                      }).toList(),
                    ),
                  ),
                ),
              );
            },
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            child: PaginationControls<LeadModel>(),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterRow({required ValueChanged<String> onSearchChanged}) {
    if (!Hive.isBoxOpen('leadStatus') ||
        !Hive.isBoxOpen('leadCategory') ||
        !Hive.isBoxOpen('employees')) {
      return SizedBox(
        width: 250,
        child: TextField(
          onChanged: onSearchChanged,
          decoration: InputDecoration(
            hintText: 'Search',
            prefixIcon: const Icon(Icons.search, size: 20, color: Colors.grey),
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
          ),
        ),
      );
    }
    final statusBox = Hive.box<Map<dynamic, dynamic>>('leadStatus');
    final categoryBox = Hive.box<Map<dynamic, dynamic>>('leadCategory');
    final cache = CacheService();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
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
        const SizedBox(height: 12),

        // Filters Row
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
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
              _filterDropdown(
                label: "Status",
                value: _selectedStatus != null
                    ? LeadStatusModel.fromMap(
                        _selectedStatus!,
                        Map<String, dynamic>.from(
                          statusBox.get(_selectedStatus!) ?? {},
                        ),
                      ).name
                    : null,
                items: statusItems(statusBox),
                onChanged: (v) {
                  final selectedModel = statusBox.keys.firstWhere(
                    (key) =>
                        LeadStatusModel.fromMap(
                          key,
                          Map<String, dynamic>.from(statusBox.get(key) ?? {}),
                        ).name ==
                        v,
                    orElse: () => '',
                  );
                  setState(() => _selectedStatus = selectedModel);
                  _applyFilters();
                },
              ),
              const SizedBox(width: 10),
              _filterDropdown(
                label: "Lead Category",
                value: _selectedCategory != null
                    ? LeadCategoryModel.fromMap(
                        _selectedCategory!,
                        Map<String, dynamic>.from(
                          categoryBox.get(_selectedCategory!) ?? {},
                        ),
                      ).name
                    : null,
                items: categoryItems(categoryBox),
                onChanged: (v) {
                  final selectedModel = categoryBox.keys.firstWhere(
                    (key) =>
                        LeadCategoryModel.fromMap(
                          key,
                          Map<String, dynamic>.from(categoryBox.get(key) ?? {}),
                        ).name ==
                        v,
                    orElse: () => '',
                  );
                  setState(() => _selectedCategory = selectedModel);
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

              _valueFilter(onChanged: _onValueChanged),
            ],
          ),
        ),
      ],
    );
  }

  Widget _valueFilter({
    required ValueChanged<String> onChanged,
    double itemWidth = 180,
  }) {
    return SizedBox(
      width: itemWidth,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Lead Value",
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
                // Icon(
                //   Icons.currency_rupee,
                //   size: 18,
                //   color: Colors.grey.shade600,
                // ),
                // const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    keyboardType: TextInputType.number,
                    onChanged: onChanged,
                    style: Theme.of(context).textTheme.bodySmall,
                    decoration: const InputDecoration(
                      isDense: true,
                      // hintText: "1000 - 5000",
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                      fillColor: Colors.transparent,
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

  void _onValueChanged(String value) {
    _value = null;

    final cleaned = value.replaceAll(' ', '');
    if (cleaned.isEmpty) {
      _applyFilters();
      return;
    }

    final parsedValue = double.tryParse(cleaned);
    if (parsedValue == null) {
      _applyFilters();
      return;
    }

    _value = parsedValue;

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
                    color: Colors.black,
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
    final controller = context.read<PaginatedDataController<LeadModel>>();
    final List<LeadModel> allLeads =
        context.read<LeadBloc>().state is LeadLoaded
        ? (context.read<LeadBloc>().state as LeadLoaded).leads
        : <LeadModel>[];

    List<LeadModel> filtered = allLeads;

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
          .where((e) => e.leadStatus == _selectedStatus)
          .toList();
    }

    if (_selectedCategory != null) {
      filtered = filtered
          .where((e) => e.leadCategory == _selectedCategory)
          .toList();
    }

    if (_selectedCreatedBy != null) {
      filtered = filtered
          .where((e) => e.createdBy.uid == _selectedCreatedBy)
          .toList();
    }

    if (_value != null) {
      filtered = filtered.where((e) => e.leadValue == _value!).toList();
    }

    setState(() {
      _filteredLeads = filtered;
    });

    controller.setData(filtered);
  }

  Widget _buildActionRow(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final List<Widget> actionButtons = [];

        // ADD BUTTON
        if (permissions?.canCreate ?? false) {
          actionButtons.add(
            ElevatedButton.icon(
              onPressed: () async {
                final result = kIsMobile
                    ? await Sheet.showSheet(context, widget: const LeadCreate())
                    : await GeneralDialog.showRTLSheet(
                        context,
                        const LeadCreate(),
                      );
                if (result == true && context.mounted) {
                  context.read<LeadBloc>().add(StreamLead());
                }
              },
              icon: const Icon(Icons.add, size: 18),
              label: Text("Add $_pageTitle"),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.success,
                foregroundColor: AppColors.white,
              ),
            ),
          );
        } else {
          actionButtons.add(
            ElevatedButton.icon(
              onPressed: null,
              icon: const Icon(Icons.add, size: 18),
              label: Text("Add $_pageTitle"),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.grey300,
                foregroundColor: AppColors.grey600,
              ),
            ),
          );
        }

        actionButtons.add(const SizedBox(width: 10));

        actionButtons.add(
          ElevatedButton.icon(
            onPressed: () {
              if (kIsMobile) {
                Sheet.showSheet(context, widget: const LeadUpload());
              } else {
                GeneralDialog.showRTLSheet(context, const LeadUpload());
              }
            },
            icon: const Icon(Iconsax.cloud_plus, size: 18),
            label: const Text("Upload"),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.blue,
              foregroundColor: AppColors.white,
            ),
          ),
        );

        actionButtons.add(const SizedBox(width: 10));

        actionButtons.add(
          OutlinedButton.icon(
            onPressed: () async {
              await Download.downloadFromUrl(
                context,
                "https://firebasestorage.googleapis.com/v0/b/srisoftwarez-crm.firebasestorage.app/o/static%2Faaatp_lead_upload_template.xlsx?alt=media&token=8173a050-72a3-403e-bc10-e8c876118721",
                "Lead_Import_Template.xlsx",
              );
            },
            icon: const Icon(Icons.file_download_outlined, size: 18),
            label: const Text("Template"),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.blue,
              side: const BorderSide(color: AppColors.blue),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
          ),
        );

        actionButtons.add(const SizedBox(width: 10));

        // EXPORT BUTTON
        actionButtons.add(
          ElevatedButton.icon(
            label: const Text("Export"),
            icon: const Icon(Iconsax.export_3, size: 18),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.grey600,
              foregroundColor: AppColors.white,
            ),
            onPressed: () async {
              try {
                List<List<String>> exportData = [];
                exportData.add([
                  'Lead Name',
                  'Email',
                  'Source',
                  'Category',
                  'Priority',
                  'Value',
                  'Status',
                  'Company',
                  'Mobile',
                  'Country',
                  'State',
                  'City',
                  'Address',
                  'Notes',
                  'Created At',
                ]);

                for (var lead in _leadsList) {
                  exportData.add([
                    lead.leadName,
                    lead.leadEmail,
                    lead.leadSource.name,
                    lead.leadCategory,
                    lead.leadPriority,
                    lead.leadValue.toString(),
                    lead.leadStatus,
                    lead.companyName ?? '',
                    lead.companyMobile ?? '',
                    lead.companyCountry?.name ?? '',
                    lead.companyState?.name ?? '',
                    lead.companyCity?.name ?? '',
                    lead.companyAddress ?? '',
                    lead.notes,
                    lead.createdAt.formatDateTime,
                  ]);
                }

                var fileBytes = await XlsxWriter().create(exportData);
                var filePath = await saveFileToDownloads(
                  fileBytes,
                  fileName:
                      'Leads_Export_${DateTime.now().millisecondsSinceEpoch}.xlsx',
                );
                openfile(filePath, context);
              } catch (e) {
                FlushBar.show(context, e.toString(), isSuccess: false);
              }
            },
          ),
        );

        // DELETE BUTTON (Only shows if items selected)
        if ((permissions?.canDelete ?? false) && _selectedLeads.isNotEmpty) {
          actionButtons.add(const SizedBox(width: 10));
          actionButtons.add(
            ElevatedButton.icon(
              label: const Text("Delete"),
              icon: const Icon(Iconsax.trash, size: 18),
              onPressed: () async {
                var result = await showDialog(
                  context: context,
                  builder: (context) => const ConfirmDialog(
                    title: 'Delete',
                    content:
                        'Are you sure you want to delete the selected leads?',
                  ),
                );

                if (result != true) return;

                try {
                  // ✅ STEP 1: backup
                  final deletedLeads = List<LeadModel>.from(_selectedLeads);

                  futureLoading(context);

                  // ✅ STEP 2: delete
                  for (var lead in deletedLeads) {
                    await LeadService.deleteLead(uid: lead.uid ?? '');
                  }

                  if (Navigator.canPop(context)) Navigator.pop(context);

                  // ✅ STEP 3: clear selection
                  _selectedLeads.clear();
                  setState(() {});

                  // ✅ STEP 4: UNDO
                  FlushBar.show(
                    context,
                    'Leads deleted successfully',
                    actionLabel: 'UNDO',
                    onActionPressed: () async {
                      for (var lead in deletedLeads) {
                        await LeadService.restoreLead(
                          lead,
                        ); // 👈 implement this
                      }

                      // 🔥 refresh list
                      context.read<LeadBloc>().add(StreamLead());
                    },
                    // onDismissed: () {
                    //   // 🔥 refresh if user does nothing
                    //   context.read<LeadBloc>().add(StreamLeads());
                    // },
                  );
                } catch (e) {
                  if (Navigator.canPop(context)) Navigator.pop(context);
                  FlushBar.show(context, e.toString(), isSuccess: false);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.danger,
                foregroundColor: AppColors.white,
              ),
            ),
          );
        }

        // 2. Define the View Toggle (Grid/List/Calendar)
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
              _buildToggleIcon(Iconsax.grid_3, 'Grid'),
              Container(width: 1, color: Colors.grey.shade300),
              _buildToggleIcon(Icons.list, 'List'),
              Container(width: 1, color: Colors.grey.shade300),
              _buildToggleIcon(Iconsax.calendar_1, 'Calendar'),
            ],
          ),
        );

        // 3. Layout the components
        if (kIsMobile) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(children: actionButtons),
              ),
              const SizedBox(height: 12),
              viewToggle,
            ],
          );
        } else {
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(children: actionButtons),
              viewToggle,
            ],
          );
        }
      },
    );
  }

  // Helper for the View Toggle icons
  Widget _buildToggleIcon(IconData icon, String viewName) {
    return IconButton(
      onPressed: () => setState(() => _selectedView = viewName),
      icon: Icon(icon, size: 18),
      color: _selectedView == viewName ? AppColors.blue : AppColors.grey700,
    );
  }

  DataRow _buildDataRow(
    BuildContext context,
    LeadModel lead,
    PaginatedDataController<LeadModel> controllerWatch,
    PaginatedDataController<LeadModel> controllerRead,
  ) {
    bool isSelected = controllerWatch.selectedIds.contains(lead.uid);
    var leadCategory = CacheService.leadCategoryByUid(lead.leadCategory);

    /// Open Lead View
    void openLead(BuildContext context, LeadModel lead) async {
      final result = kIsMobile
          ? await Sheet.showSheet(context, widget: LeadsViewPage(lead: lead))
          : await GeneralDialog.showRTLSheet(
              context,
              LeadsViewPage(lead: lead),
            );

      if (result == 'deleted' && context.mounted) {
        context.read<LeadBloc>().add(StreamLead());
      }
    }

    /// Reusable tappable DataCell
    DataCell dataCell(BuildContext context, Widget child) {
      return DataCell(
        InkWell(
          onTap: () => openLead(context, lead),
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
        controllerRead.onSelected(lead.uid ?? '', selected);
        if (selected ?? false) {
          _selectedLeads.add(lead);
        } else {
          _selectedLeads.remove(lead);
        }
        setState(() {});
      },
      cells: [
        /// Lead Number
        dataCell(
          context,
          Text(
            lead.leadNumber.toString(),
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w500),
          ),
        ),

        /// Lead Name
        dataCell(
          context,
          Text(
            lead.leadName,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w500),
          ),
        ),

        /// Email
        dataCell(
          context,
          Text(lead.leadEmail, style: Theme.of(context).textTheme.bodySmall),
        ),

        /// Empty column
        dataCell(context, const Text('')),

        /// Lead Value
        dataCell(
          context,
          Text(
            lead.leadValue.toString(),
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),

        /// Category
        dataCell(
          context,
          Text(
            leadCategory?.name ?? '',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),

        /// Status
        dataCell(
          context,
          Text(
            CacheService.leadStatusByUid(lead.leadStatus)?.name ?? '',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),

        /// Created At
        dataCell(
          context,
          Text(
            lead.createdAt.listingDateTime,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),

        /// Created By
        dataCell(context, CreatedByWidget(userData: lead.createdBy)),

        /// Actions (❌ no row tap here)
        DataCell(
          Row(
            children: [
              if ((permissions?.canEdit ?? false) &&
                  (_isAdmin ||
                      lead.createdBy.uid == _currentUid)) ...[
                IconButton(
                  icon: const Icon(Iconsax.edit),
                  color: AppColors.info,
                  splashRadius: 20,
                  onPressed: () {
                    if (kIsMobile) {
                      Sheet.showSheet(
                        context,
                        widget: LeadEdit(uid: lead.uid ?? ''),
                      );
                    } else {
                      GeneralDialog.showRTLSheet(
                        context,
                        LeadEdit(uid: lead.uid ?? ''),
                      );
                    }
                  },
                ),
              ] else ...[
                IconButton(
                  icon: Icon(Iconsax.edit, color: AppColors.grey400),
                  onPressed: null,
                ),
              ],

              IconButton(
                icon: const Icon(Icons.autorenew_rounded),
                tooltip: 'Convert $_pageTitle to Deal',
                color: AppColors.primary,
                splashRadius: 20,
                onPressed: () async {
                  final result = await showDialog<bool>(
                    context: context,
                    builder: (_) => const ConfirmDialog(
                      title: 'Convert $_pageTitle',
                      content:
                          'Are you sure you want to convert this lead to a deal?',
                    ),
                  );

                  if (result == true) {
                    await _convertLeadToDeal(context, lead);
                  }
                },
              ),

              if ((permissions?.canDelete ?? false) &&
                  (_isAdmin ||
                      lead.createdBy.uid == _currentUid)) ...[
                IconButton(
                  icon: const Icon(Iconsax.trash),
                  color: AppColors.danger,
                  splashRadius: 20,
                  tooltip: 'Delete $_pageTitle',
                  onPressed: () async {
                    final result = await showDialog<bool>(
                      context: context,
                      builder: (_) => ConfirmDialog(
                        title: 'Delete $_pageTitle',
                        content: 'Are you sure you want to delete this lead?',
                      ),
                    );

                    if (result != true) return;

                    try {
                      final deletedLead = lead;

                      await LeadService.deleteLead(uid: lead.uid ?? '');

                      if (!mounted) return;

                      FlushBar.show(
                        context,
                        '$_pageTitle deleted successfully',
                        actionLabel: 'UNDO',
                        onActionPressed: () async {
                          await LeadService.restoreLead(deletedLead);

                          // ✅ refresh after undo
                          context.read<LeadBloc>().add(StreamLead());
                        },
                        // onDismissed: () {
                        //   // ✅ refresh if no undo
                        //   context.read<LeadBloc>().add(StreamLead());
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

  Future<void> _convertLeadToDeal(BuildContext context, LeadModel lead) async {
    try {
      futureLoading(context);

      final leadDetails = await LeadService.getLead(uid: lead.uid ?? '');

      final dealData = {
        'dealName': leadDetails.leadName,
        'dealEmail': leadDetails.leadEmail,
        'companyName': leadDetails.companyName,
        'companyMobile': leadDetails.companyMobile,
        'companyAddress': leadDetails.companyAddress,
        'dealValue': leadDetails.leadValue,
        'notes': leadDetails.notes,
      };

      // await DealService.createDeal(
      //   deal: DealModel.fromMap(lead.uid ?? '', dealData),
      // );

      await LeadService.convertLeadToDeal(lead: leadDetails);

      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }
      Navigate.route(
        context,
        DealCreate(
          isFromLead: true,
          prefillDeal: DealModel.fromMap(lead.uid ?? '', dealData),
        ),
      );
    } catch (e, st) {
      await ErrorService.recordError(e, st);
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }
      FlushBar.show(context, e.toString(), isSuccess: false);
    }
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
