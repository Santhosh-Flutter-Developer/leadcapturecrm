import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import '/services/services.dart';
import '/constants/constants.dart';
import '/models/models.dart';
import '/theme/theme.dart';
import '/utils/utils.dart';
import '/views/views.dart';
import 'bloc/admin_bloc.dart';

const String _pageTitle = "Admin";

class AdminListing extends StatelessWidget {
  const AdminListing({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => AdminBloc()..add(StreamAdmins()),
      child: const AdminListView(),
    );
  }
}

class AdminListView extends StatelessWidget {
  const AdminListView({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => PaginatedDataController<AdminModel>(
        initialSortColumnIndex: 1,
        filterLogic: (admin, query) {
          final q = query.toLowerCase();
          return admin.name.toLowerCase().contains(q) ||
              admin.email.toLowerCase().contains(q) ||
              admin.mobileNumber.toLowerCase().contains(q);
        },
        sortLogic: (a, b, col, asc) {
          int compare;
          switch (col) {
            case 0:
              compare = a.name.toLowerCase().compareTo(b.name.toLowerCase());
              break;
            case 1:
              compare = a.email.toLowerCase().compareTo(b.email.toLowerCase());
              break;
            case 2:
              compare = a.mobileNumber.toLowerCase().compareTo(
                b.mobileNumber.toLowerCase(),
              );
              break;
            case 3:
              compare = a.isActive.toString().compareTo(b.isActive.toString());
              break;
            default:
              compare = a.uid!.compareTo(b.uid!);
          }
          return asc ? compare : -compare;
        },
        getItemId: (admin) => admin.uid!,
      ),
      child: const AdminListingView(),
    );
  }
}

class AdminListingView extends StatefulWidget {
  const AdminListingView({super.key});

  @override
  State<AdminListingView> createState() => _AdminListingViewState();
}

class _AdminListingViewState extends State<AdminListingView> {
  PermissionModel? permissions;
  final List<AdminModel> _adminList = [];
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

  final List<AdminModel> _selectedAdmins = [];

  @override
  Widget build(BuildContext context) {
    final controllerRead = context.read<PaginatedDataController<AdminModel>>();
    final controllerWatch = context
        .watch<PaginatedDataController<AdminModel>>();

    return Scaffold(
      appBar: kIsMobile
          ? AppBar(leading: Back(), title: Text(_pageTitle))
          : null,
      body: BlocListener<AdminBloc, AdminState>(
        listenWhen: (previous, current) => current is AdminLoaded,
        listener: (context, state) {
          if (state is AdminLoaded) {
            controllerRead.setData(state.admins);
            _adminList.addAll(state.admins);
          }
        },
        child: BlocBuilder<AdminBloc, AdminState>(
          builder: (context, state) {
            if (state is AdminLoading) {
              return const WaitingLoading();
            }

            if (state is AdminLoaded) {
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

                                        // ✅ MIN WIDTH SETTINGS
                                        columnSpacing: 12,
                                        horizontalMargin: 8,
                                        headingRowHeight: 40,

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
                                            label: IntrinsicWidth(
                                              child: _sortableHeader(
                                                "Name",
                                                controllerRead,
                                              ),
                                            ),
                                            onSort: controllerRead.setSort,
                                          ),

                                          DataColumn(
                                            label: IntrinsicWidth(
                                              child: _sortableHeader(
                                                "Email",
                                                controllerRead,
                                              ),
                                            ),
                                            onSort: controllerRead.setSort,
                                          ),

                                          DataColumn(
                                            label: IntrinsicWidth(
                                              child: _sortableHeader(
                                                "Mobile No",
                                                controllerRead,
                                              ),
                                            ),
                                            onSort: controllerRead.setSort,
                                          ),

                                          DataColumn(
                                            label: IntrinsicWidth(
                                              child: _sortableHeader(
                                                "Status",
                                                controllerRead,
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
                                                    "Created At",
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
                                            onSort: controllerRead.setSort,
                                          ),

                                          DataColumn(
                                            label: IntrinsicWidth(
                                              child: Text(
                                                "Created By",
                                                style: Theme.of(
                                                  context,
                                                ).textTheme.bodySmall,
                                              ),
                                            ),
                                          ),

                                          DataColumn(
                                            label: IntrinsicWidth(
                                              child: Text(
                                                "Action",
                                                style: Theme.of(
                                                  context,
                                                ).textTheme.bodySmall,
                                              ),
                                            ),
                                          ),
                                        ],

                                        rows: controllerWatch.paginatedItems
                                            .map(
                                              (admin) => _buildDataRow(
                                                context,
                                                admin,
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
                              child: PaginationControls<AdminModel>(),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            if (state is AdminError) {
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
    if (permissions == null) {
      return Row(
        children: [
          ElevatedButton.icon(
            onPressed: null,
            icon: const Icon(Icons.add),
            label: Text(
              "Add $_pageTitle",
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      );
    }

    return Row(
      children: [
        ElevatedButton.icon(
          onPressed: (permissions?.canCreate ?? false)
              ? () {
                  if (kIsMobile) {
                    Sheet.showSheet(context, widget: const AdminCreate());
                  } else {
                    GeneralDialog.showRTLSheet(context, const AdminCreate());
                  }
                }
              : null,
          icon: Icon(
            Icons.add,
            color: (permissions?.canCreate ?? false) ? null : AppColors.grey600,
            size: 18,
          ),
          label: Text(
            "Add $_pageTitle",
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppColors.white),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: (permissions?.canCreate ?? false)
                ? AppColors.success
                : AppColors.grey300,
            foregroundColor: (permissions?.canCreate ?? false)
                ? AppColors.white
                : AppColors.grey600,
          ),
        ),
        const SizedBox(width: 10),
        if (_selectedAdmins.isNotEmpty) ...[
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
                        for (var i in _selectedAdmins) {
                          await AdminService.deleteAdmin(uid: i.uid ?? '');
                        }
                        if (Navigator.canPop(context)) {
                          Navigator.pop(context);
                        }
                        FlushBar.show(
                          context,
                          '$_pageTitle deleted successfully',
                        );
                        _selectedAdmins.clear();
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
          const SizedBox(width: 10),
        ],
        ElevatedButton.icon(
          label: Text(
            "Export",
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppColors.white),
          ),
          icon: Icon(Iconsax.export_3),
          onPressed: () async {
            List<List<String>> exportData = [];
            exportData.add([
              'Name',
              'Email',
              'Mobile Number',
              'Created At',
              'Profile Picture',
            ]);
            for (var i in _adminList) {
              List<String> row = [];
              row.addAll([
                i.name,
                i.email,
                i.mobileNumber,
                i.createdAt.listingDateTime,
                i.profileImageUrl ?? '',
              ]);
              exportData.add(row);
            }
            var fileBytes = await XlsxWriter().create(exportData);
            var filePath = await saveFileToDownloads(
              fileBytes,
              fileName: 'Admin List.xlsx',
            );
            openfile(filePath, context);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.grey600,
            foregroundColor: AppColors.white,
          ),
        ),
      ],
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
    AdminModel admin,
    PaginatedDataController<AdminModel> controllerWatch,
    PaginatedDataController<AdminModel> controllerRead,
  ) {
    bool isSelected = controllerWatch.selectedIds.contains(admin.uid);
    return DataRow(
      selected: isSelected,
      onSelectChanged: (selected) {
        controllerRead.onSelected(admin.uid!, selected);
        if (selected ?? false) {
          _selectedAdmins.add(admin);
        } else {
          _selectedAdmins.remove(admin);
        }
        setState(() {});
      },
      cells: [
        DataCell(
          InkWell(
            onTap: () {
              permissions!.canView;
              if (kIsMobile) {
                Sheet.showSheet(context, widget: AdminProfile(admin: admin));
              } else {
                GeneralDialog.showRTLSheet(context, AdminProfile(admin: admin));
              }
            },
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: CachedNetworkImage(
                    imageUrl:
                        admin.profileImageUrl ??
                        AppStrings.emptyProfilePhotoUrl,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Shimmer.fromColors(
                      baseColor: AppColors.grey300,
                      highlightColor: AppColors.grey200,
                      child: Container(color: AppColors.white),
                    ),
                    height: 30,
                    width: 30,
                    errorWidget: (context, url, error) =>
                        const Icon(Iconsax.danger),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  admin.name,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        ),
        DataCell(
          Text(admin.email, style: Theme.of(context).textTheme.bodySmall),
        ),
        DataCell(
          Text(
            admin.mobileNumber,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
        DataCell(
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: admin.isActive ? AppColors.success : AppColors.danger,
              borderRadius: const BorderRadius.all(Radius.circular(8)),
            ),
            child: Text(
              admin.isActive ? 'Active' : 'Inactive',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
        DataCell(
          Text(
            admin.createdAt.listingDateTime,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
        DataCell(CreatedByWidget(userData: admin.createdBy)),
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
                            widget: AdminUpdate(id: admin.uid!, admin: admin),
                          );
                        } else {
                          GeneralDialog.showRTLSheet(
                            context,
                            AdminUpdate(id: admin.uid!, admin: admin),
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
                            await AdminService.deleteAdmin(
                              uid: admin.uid ?? '',
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
