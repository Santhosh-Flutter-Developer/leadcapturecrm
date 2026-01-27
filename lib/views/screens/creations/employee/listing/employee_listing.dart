import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '/services/services.dart';
import '/constants/constants.dart';
import '/models/models.dart';
import '/views/views.dart';
import '/utils/utils.dart';
import '/theme/theme.dart';
import 'bloc/employee_bloc.dart';

const String _pageTitle = "Employees";

class EmployeeListing extends StatelessWidget {
  const EmployeeListing({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => UsersBloc()..add(StreamUsers()),
      child: ChangeNotifierProvider(
        create: (context) => PaginatedDataController<UserRowModel>(
          initialSortColumnIndex: 0,
          filterLogic: (employee, query) {
            final q = query.toLowerCase();
            return employee.name.toLowerCase().contains(q) ||
                employee.name.toLowerCase().contains(q);
          },
          sortLogic: (a, b, col, asc) {
            int compare;
            switch (col) {
              case 0:
                compare = a.uid.toLowerCase().compareTo(b.uid.toLowerCase());
                break;
              case 1:
                compare = a.name.toLowerCase().compareTo(b.name.toLowerCase());
                break;
              case 2:
                compare = a.email.toLowerCase().compareTo(
                  b.email.toLowerCase(),
                );
                break;
              case 3:
                compare = a.isActive.toString().compareTo(
                  b.isActive.toString(),
                );
                break;
              default:
                compare = (a.uid).compareTo(b.uid);
                break;
            }
            return asc ? compare : -compare;
          },
          getItemId: (employee) => employee.uid,
        ),
        child: const EmployeeListingView(),
      ),
    );
  }
}

class EmployeeListingView extends StatefulWidget {
  const EmployeeListingView({super.key});

  @override
  State<EmployeeListingView> createState() => _EmployeeListingViewState();
}

class _EmployeeListingViewState extends State<EmployeeListingView> {
  final List<UserRowModel> _selectedEmployees = [];
  final List<UserRowModel> _employeesList = [];
  PermissionModel? permissions;
  final ScrollController _hScrollController = ScrollController();

  final TextEditingController _chatMessage = TextEditingController();

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
    final controllerRead = context.read<PaginatedDataController<UserRowModel>>();
    final controllerWatch = context.watch<PaginatedDataController<UserRowModel>>();

    return Scaffold(
      appBar: kIsMobile
          ? AppBar(leading: Back(), title: Text(_pageTitle))
          : null,
      body: BlocListener<UsersBloc, UsersState>(
        listenWhen: (previous, current) => current is UsersLoaded,
        listener: (context, state) {
          if (state is UsersLoaded) {
            controllerRead.setData(state.users);
          }
        },

        child: BlocBuilder<UsersBloc, UsersState>(
          builder: (context, state) {
            if (state is UsersLoading) {
              return const WaitingLoading();
            }

            if (state is UsersLoaded) {
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

                      _buildActionRow(),
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
                                        columnSpacing: 12,
                                        horizontalMargin: 8,
                                        // dataRowMinHeight: 40,
                                        // dataRowMaxHeight: 40,
                                        // headingRowHeight: 40,
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
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Text(
                                                    "Employee ID",
                                                    style: Theme.of(
                                                      context,
                                                    ).textTheme.bodySmall,
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Icon(
                                                    Icons.arrow_upward,
                                                    size: 14,
                                                    color: Colors.grey.shade400,
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
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Text(
                                                    "Department",
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
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Text(
                                                    "Email",
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
                                                "Mobile app",
                                                style: Theme.of(
                                                  context,
                                                ).textTheme.bodySmall,
                                              ),
                                            ),
                                          ),

                                          DataColumn(
                                            label: IntrinsicWidth(
                                              child: Text(
                                                "Desktop app",
                                                style: Theme.of(
                                                  context,
                                                ).textTheme.bodySmall,
                                              ),
                                            ),
                                          ),

                                          DataColumn(
                                            label: IntrinsicWidth(
                                              child: Text(
                                                "Role",
                                                style: Theme.of(
                                                  context,
                                                ).textTheme.bodySmall,
                                              ),
                                            ),
                                          ),

                                          DataColumn(
                                            label: IntrinsicWidth(
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Text(
                                                    "Status",
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
                                              (user) => _buildDataRow(
                                                context,
                                                user,
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
                              child: PaginationControls<UserRowModel>(),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            if (state is UsersError) {
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

  Future<void> handleDelete(BuildContext context, UserRowModel user) async {
    final confirm = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => ConfirmDialog2(
        title: 'Delete',
        content: 'Are you sure you want to delete ${user.name}?',
      ),
    );

    if (confirm != true) return;
    if (!context.mounted) return;
    debugPrint('Confirmed delete for ${user.uid}');
    context.read<UsersBloc>().add(DeleteUser(user));
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

  Widget _buildActionRow() {
    return LayoutBuilder(
      builder: (context, constraints) {
        // final bool isMobile = constraints.maxWidth < 600;

        final buttons = <Widget>[
          (permissions?.canCreate ?? false)
              ? ElevatedButton.icon(
                  onPressed: () {
                    if (kIsMobile) {
                      Sheet.showSheet(context, widget: const EmployeeCreate());
                    } else {
                      GeneralDialog.showRTLSheet(
                        context,
                        const EmployeeCreate(),
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
                  icon: Icon(Icons.add, size: 18, color: Colors.grey.shade600),
                  label: Text(
                    "Add $_pageTitle",
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey.shade600,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey.shade300,
                    foregroundColor: Colors.grey.shade600,
                  ),
                ),
          ElevatedButton.icon(
            onPressed: () {
              if (kIsMobile) {
                Sheet.showSheet(context, widget: const EmployeeUploadPage());
              } else {
                GeneralDialog.showRTLSheet(context, const EmployeeUploadPage());
              }
            },
            icon: const Icon(Iconsax.cloud_plus, size: 18),
            label: Text(
              "Upload",
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppColors.white),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.blue,
              foregroundColor: AppColors.white,
            ),
          ),
        ];

        buttons.add(
          ElevatedButton.icon(
            label: Text(
              "Export",
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppColors.white),
            ),
            icon: Icon(Iconsax.export_3),
            onPressed: () async {
              try {
                List<List<String>> exportData = [];
                exportData.add([
                  'Employee Id',
                  'Name',
                  'Email',
                  'Designation',
                  'Department',
                  'Sub Department',
                  'Mobile Number',
                  'Profile Image',
                  'Gender',
                  'Date Of Joining',
                  'Date Of Birth',
                  'Role',
                  'Address',
                  'About',
                  'Login Allowed',
                  'Receive Email Notifications',
                  'Employee Type',
                  'Reporting To',
                  'Marital Status',
                  'Is Active',
                  'Created At',
                ]);
                for (var i in _employeesList) {
                  List<String> row = [];
                  row.addAll([
                    i.employeeId ?? "",
                    i.name,
                    i.email,
                    CacheService.designationByUid(i.designation ?? "")?.name ??
                        '',
                    i.department != null && i.department!.isNotEmpty
                        ? i.department!
                              .map(
                                (uid) =>
                                    CacheService.departmentByUid(uid)?.name ??
                                    '',
                              )
                              .join(', ')
                        : '',
                    i.subDepartment != null
                        ? CacheService.subDepartmentByUid(
                                i.subDepartment!,
                              )?.name ??
                              ''
                        : '',
                    i.mobileNumber,
                    i.profileImageUrl ?? '',
                    i.gender ?? "",
                    i.dateOfJoining?.formatDate ?? '',
                    i.dateOfBirth?.formatDate ?? '',
                    CacheService.roleByUid(i.role ?? "")?.name ?? '',
                    i.address ?? "",
                    i.about ?? "",
                    (i.loginAllowed ?? false) ? "Yes" : "No",
                    (i.receiveEmailNotifications ?? false) ? "Yes" : "No",
                    i.employeeType ?? '',

                    i.reportingTo != null && i.reportingTo!.isNotEmpty
                        ? i.reportingTo!
                              .map(
                                (uid) =>
                                    CacheService.getUserByUid(uid)?.name ?? '',
                              )
                              .join(', ')
                        : '',
                    i.maritalStatus ?? "",
                    i.isActive ? "Yes" : "No",
                    i.createdAt?.formatDateTime ?? '',
                  ]);
                  exportData.add(row);
                }
                var fileBytes = await XlsxWriter().create(exportData);
                var filePath = await saveFileToDownloads(
                  fileBytes,
                  fileName: '$_pageTitle List.xlsx',
                );
                openfile(filePath, context);
              } catch (e) {
                FlushBar.show(context, e.toString(), isSuccess: false);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.grey600,
              foregroundColor: AppColors.white,
            ),
          ),
        );

        buttons.add(
          ElevatedButton.icon(
            label: Text(
              "Worflow",
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppColors.white),
            ),
            icon: Icon(Iconsax.data),
            onPressed: () async {
              try {
                futureLoading(context);
                var resultMap = [];
                var employees = await EmployeeService.getAllEmployees();
                for (var i in employees) {
                  var result = await EmployeeService.getUserWorkflow(
                    userId: i.uid,
                  );
                  var subResultMap = {};
                  for (var i = 0; i < result.length; i++) {
                    subResultMap[i.toString()] = result[i];
                  }

                  resultMap.add({i.uid: subResultMap});
                }
                if (Navigator.canPop(context)) {
                  Navigator.pop(context);
                }
                if (kIsDesktop) {
                  GeneralDialog.showRTLSheet(
                    context,
                    OrgChart(rawData: resultMap),
                  );
                } else if (kIsMobile) {
                  Sheet.showSheet(
                    context,
                    widget: OrgChart(rawData: resultMap),
                  );
                }
              } catch (e) {
                if (Navigator.canPop(context)) {
                  Navigator.pop(context);
                }
                FlushBar.show(context, e.toString(), isSuccess: false);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.teal,
              foregroundColor: AppColors.white,
            ),
          ),
        );

        if (_selectedEmployees.isNotEmpty) {
          buttons.add(
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
                      if (_selectedEmployees.isEmpty) return;

                      for (final employee in _selectedEmployees) {
                        final isAssigned =
                            await EmployeeService.isEmployeeAssigned(
                              employee.employeeId ?? '',
                            );

                        if (isAssigned) {
                          if (!context.mounted) return;

                          await showDialog(
                            context: context,
                            builder: (_) => AlertDialog(
                              title: Text(
                                'Cannot Delete',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                              content: Text(
                                'One or more selected employees are associated with chats, projects, tasks, leads, or deals and cannot be deleted.',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
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
                        barrierDismissible: false,
                        builder: (_) => ConfirmDialog(
                          title: 'Delete',
                          content:
                              'Are you sure you want to delete the selected $_pageTitle?',
                        ),
                      );

                      if (confirm != true) return;
                      if (!context.mounted) return;

                      for (final employee in _selectedEmployees) {
                        if (employee.uid.isNotEmpty) {
                          context.read<UsersBloc>().add(DeleteUser(employee));
                        }
                      }

                      _selectedEmployees.clear();

                      FlushBar.show(
                        context,
                        'Employee deleted successfully',
                        isSuccess: true,
                      );
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
                    icon: const Icon(Iconsax.trash),
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.grey400,
                      foregroundColor: AppColors.white,
                    ),
                  ),
          );
        }

        if (_selectedEmployees.isNotEmpty) {
          // Chat Button
          buttons.add(
            ElevatedButton.icon(
              onPressed: () async {
                if (_selectedEmployees.isEmpty) {
                  FlushBar.show(
                    context,
                    "Please select at least one employee.",
                    isSuccess: false,
                  );
                  return;
                }

                final bool isSingle = _selectedEmployees.length == 1;

                final bool? confirm = await showDialog<bool>(
                  context: context,
                  barrierDismissible: false,
                  builder: (context) => AlertDialog(
                    title: Text(
                      isSingle ? "Create Chat" : "Create Group Chat",
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          isSingle
                              ? "Do you want to start a chat with ${_selectedEmployees.first.name}?"
                              : "Do you want to create a group chat with ${_selectedEmployees.length} employees?",
                          style: Theme.of(context).textTheme.bodySmall,
                        ),

                        const SizedBox(height: 8),

                        FormFields(
                          label: 'Enter chat message',
                          controller: _chatMessage,
                          hintText: 'Enter Description',
                          maxLines: 3,
                          isRequired: true,
                          valid: (val) => val == null || val.isEmpty
                              ? 'Chat message is required'
                              : null,
                        ),
                      ],
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: Text(
                          "Cancel",
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(context, true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                        ),
                        child: Text(
                          "Confirm",
                          style: Theme.of(
                            context,
                          ).textTheme.bodySmall?.copyWith(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                );

                if (confirm != true) return;

                try {
                  futureLoading(context);

                  final sessionUser = await Spdb.getUser();
                  final creator = CacheService.getUserByUid(sessionUser.uid);

                  final creatorUid = creator?.uid ?? sessionUser.uid ?? '';
                  final creatorName = creator?.name ?? "";

                  if (isSingle) {
                    final emp = _selectedEmployees.first;

                    if (emp.uid == null || emp.uid.isEmpty) {
                      Navigator.pop(context);
                      return;
                    }

                    if (_chatMessage.text.isEmpty) {
                      FlushBar.show(
                        context,
                        "Please enter the chat message.",
                        isSuccess: false,
                      );
                      return;
                    }

                    var chatId = await ChatService.createIndividualChat(
                      userId: emp.uid!,
                      chatMessage: _chatMessage.text,
                    );

                    Navigator.pop(context);
                    var currentUserUid = await Spdb.getUid();
                    if (currentUserUid != null) {
                      if (!mounted) return;
                      if (kIsDesktop) {
                        GeneralDialog.showRTLSheet(
                          context,
                          ChatListing(
                            currentUserUid: currentUserUid,
                            selectedChatUid: chatId,
                          ),
                        );
                      } else if (kIsMobile) {
                        Sheet.showSheet(
                          context,
                          widget: ChatListing(
                            currentUserUid: currentUserUid,
                            selectedChatUid: chatId,
                          ),
                        );
                      }
                    }
                    _chatMessage.clear();
                    setState(() {});
                    FlushBar.show(context, "Chat created");
                    return;
                  }

                  var groupUsers = [
                    ..._selectedEmployees
                        .map((e) => e.uid ?? '')
                        .where((id) => id.isNotEmpty),
                    sessionUser.uid,
                  ];

                  final chatModel = ChatModel(
                    createdBy: creatorUid,
                    participants: groupUsers,
                    participantsKey: groupUsers.join('_'),
                    title: "Group Chat",
                    description: "",
                    isGroupChat: true,
                    isPinned: false,
                    isFavorite: false,
                    lastMessage: LastMessageModel(
                      message: "$creatorName created group",
                      timestamp: DateTime.now(),
                      senderId: creatorUid,
                    ),
                  );

                  var chatId = await ChatService.createGroupChat(
                    model: chatModel,
                  );
                  Navigator.pop(context);

                  if (chatId != null) {
                    var currentUserUid = await Spdb.getUid();
                    if (currentUserUid != null) {
                      if (!mounted) return;
                      if (kIsDesktop) {
                        GeneralDialog.showRTLSheet(
                          context,
                          ChatListing(
                            currentUserUid: currentUserUid,
                            selectedChatUid: chatId,
                          ),
                        );
                      } else if (kIsMobile) {
                        Sheet.showSheet(
                          context,
                          widget: ChatListing(
                            currentUserUid: currentUserUid,
                            selectedChatUid: chatId,
                          ),
                        );
                      }
                    }
                  }

                  FlushBar.show(context, "Group chat created");
                } catch (e, st) {
                  await ErrorService.recordError(e, st);
                  Navigator.pop(context);
                  FlushBar.show(
                    context,
                    e.toString(),
                    isSuccess: false,
                    error: e,
                    stackTrace: st,
                  );
                }
              },
              icon: const Icon(Icons.chat, size: 18),
              label: Text(
                _selectedEmployees.length == 1
                    ? 'Chat with ${_selectedEmployees.first.name}'
                    : 'Group Chat (${_selectedEmployees.length})',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: AppColors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.white,
              ),
            ),
          );

          buttons.add(
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => TaskCreate(
                      employees: _selectedEmployees
                          .where((e) => e.isEmployee)
                          .map((e) => e.toEmployeeModel())
                          .toList(),
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.task, size: 18),
              label: Text(
                "Create Task",
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: AppColors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.success,
                foregroundColor: AppColors.white,
              ),
            ),
          );
        }

        if (kIsMobile) {
          return Wrap(spacing: 10, runSpacing: 10, children: buttons);
        } else {
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minWidth: MediaQuery.of(context).size.width,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: buttons
                    .map(
                      (button) => Padding(
                        padding: const EdgeInsets.only(right: 10),
                        child: button,
                      ),
                    )
                    .toList(),
              ),
            ),
          );
        }
      },
    );
  }

  Widget buildPlatformCell({
    required IconData icon,
    required String? platformLabel,
    required DateTime? lastLogin,
  }) {
    if (platformLabel == null) {
      return Text(
        'Not installed',
        style: Theme.of(
          context,
        ).textTheme.bodySmall?.copyWith(color: AppColors.grey400),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Row(
          children: [
            Icon(icon, size: 18, color: AppColors.success),
            const SizedBox(width: 4),
            Text(
              platformLabel,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w500),
            ),
          ],
        ),
        if (lastLogin != null)
          Padding(
            padding: const EdgeInsets.only(left: 22),
            child: Text(
              DateFormat('dd MMM, hh:mm a').format(lastLogin),
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppColors.grey600),
            ),
          ),
      ],
    );
  }

  PlatformType? getPlatformFromDevice(Map<String, dynamic> device) {
    final platform = (device['platform'] ?? '').toString().toLowerCase();
    final model = (device['model'] ?? '').toString().toLowerCase();

    if (platform.contains('android') || platform.contains('ios')) {
      return PlatformType.mobile;
    }

    if (model.contains('windows') ||
        model.contains('mac') ||
        model.contains('linux')) {
      return PlatformType.desktop;
    }

    return null;
  }

  DateTime? getLastLoginByPlatform(
    List<Map<String, dynamic>> devices,
    PlatformType type,
  ) {
    DateTime? latest;

    for (final device in devices) {
      final platform = getPlatformFromDevice(device);
      if (platform != type) continue;

      final ts = device['lastLoginAt'];
      if (ts is int) {
        final dt = DateTime.fromMillisecondsSinceEpoch(ts);
        if (latest == null || dt.isAfter(latest)) {
          latest = dt;
        }
      }
    }
    return latest;
  }

  String? getPlatformLabelByType(
    List<Map<String, dynamic>> devices,
    PlatformType type,
  ) {
    for (final device in devices) {
      final platform = getPlatformFromDevice(device);
      if (platform == type) {
        return device['model']?.toString() ?? device['platform']?.toString();
      }
    }
    return null;
  }

  DataRow _buildDataRow(
    BuildContext context,
    UserRowModel employee,
    PaginatedDataController<UserRowModel> controllerWatch,
    PaginatedDataController<UserRowModel> controllerRead,
  ) {
    final devices = (employee.devices ?? []).cast<Map<String, dynamic>>();

    final mobileLastLogin = getLastLoginByPlatform(
      devices,
      PlatformType.mobile,
    );
    final desktopLastLogin = getLastLoginByPlatform(
      devices,
      PlatformType.desktop,
    );

    final mobilePlatformLabel = getPlatformLabelByType(
      devices,
      PlatformType.mobile,
    );
    final desktopPlatformLabel = getPlatformLabelByType(
      devices,
      PlatformType.desktop,
    );

    final isSelected = controllerWatch.selectedIds.contains(employee.uid);

    String getDepartmentNames(EmployeeModel? employee) {
      if (employee!.department == null || employee.department!.isEmpty) {
        return '';
      }

      return employee.department!
          .map((uid) => CacheService.departmentByUid(uid)?.name ?? '')
          .where((name) => name.isNotEmpty)
          .join(', ');
    }

    /// Open Employee Details
    void openEmployee(BuildContext context, UserRowModel employee) {
      if (kIsMobile) {
        Sheet.showSheet(
          context,
          widget: employee.isAdmin
              ? AdminProfile(admin: employee.toAdminModel())
              : EmployeeDetails(employee: employee.toEmployeeModel()),
        );
      } else {
        GeneralDialog.showRTLSheet(
          context,
          employee.isAdmin
              ? AdminProfile(admin: employee.toAdminModel())
              : EmployeeDetails(employee: employee.toEmployeeModel()),
        );
      }
    }

    /// Reusable tappable DataCell
    DataCell dataCell(BuildContext context, Widget child) {
      return DataCell(
        InkWell(
          onTap: () {
            // if (!employee.isEmployee) return;
            openEmployee(context, employee);
          },
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
        // if (!employee.isEmployee) return;
        controllerRead.onSelected(employee.uid, selected);
        if (selected ?? false) {
          if (!_selectedEmployees.any((e) => e.uid == employee.uid)) {
            _selectedEmployees.add(employee);
            _employeesList.add(employee);
          }
        } else {
          _selectedEmployees.removeWhere((e) => e.uid == employee.uid);
          _employeesList.removeWhere((e) => e.uid == employee.uid);
        }
        setState(() {});
      },
      cells: [
        /// Employee ID
        dataCell(
          context,
          Text(
            employee.employeeId ?? "",
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w500),
          ),
        ),

        /// Name + Avatar
        dataCell(
          context,
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: CachedNetworkImage(
                  imageUrl:
                      employee.profileImageUrl ??
                      AppStrings.emptyProfilePhotoUrl,
                  height: 32,
                  width: 32,
                  fit: BoxFit.cover,
                  errorWidget: (_, _, _) => const Icon(Iconsax.user),
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    employee.name,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    CacheService.designationByUid(
                          employee.designation ?? "",
                        )?.name ??
                        '',
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: AppColors.grey600),
                  ),
                ],
              ),
            ],
          ),
        ),

        /// Department
        dataCell(
          context,
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "",
                // getDepartmentNames(employee.isEmployee ? employee.toEmployeeModel() : null),
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w500),
              ),
              if (employee.subDepartment != null &&
                  employee.subDepartment!.isNotEmpty)
                Text(
                  CacheService.subDepartmentByUid(
                        employee.subDepartment!,
                      )?.name ??
                      '',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: AppColors.grey600),
                ),
            ],
          ),
        ),

        /// Email
        dataCell(
          context,
          Text(employee.email, style: Theme.of(context).textTheme.bodySmall),
        ),

        /// Mobile Platform
        dataCell(
          context,
          buildPlatformCell(
            icon: Icons.phone_android,
            platformLabel: mobilePlatformLabel,
            lastLogin: mobileLastLogin,
          ),
        ),

        /// Desktop Platform
        dataCell(
          context,
          buildPlatformCell(
            icon: Icons.desktop_windows,
            platformLabel: desktopPlatformLabel,
            lastLogin: desktopLastLogin,
          ),
        ),

        /// Role
        dataCell(
          context,
          Text(
            CacheService.roleByUid(employee.role ?? "")?.name ?? '',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),

        /// Status
        dataCell(
          context,
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: employee.isActive ? AppColors.success : AppColors.danger,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              employee.isActive ? 'Active' : 'Inactive',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),

        /// Created By
        dataCell(context, CreatedByWidget(userData: employee.createdBy)),

        /// Actions (no row tap)
        DataCell(
          Row(
            children: [
              (permissions?.canEdit ?? false)
                  ? IconButton(
                      icon: const Icon(Iconsax.edit),
                      color: AppColors.info,
                      onPressed: () {
                        if (kIsMobile) {
                          Sheet.showSheet(
                            context,
                            widget: EmployeeEdit(
                              uid: employee.uid,
                              admin: employee.isAdmin
                                  ? employee.toAdminModel()
                                  : null,
                            ),
                          );
                        } else {
                          GeneralDialog.showRTLSheet(
                            context,
                            EmployeeEdit(
                              uid: employee.uid,
                              admin: employee.isAdmin
                                  ? employee.toAdminModel()
                                  : null,
                            ),
                          );
                        }
                      },
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
                      tooltip: 'Delete $_pageTitle',
                      onPressed: () async {
                        handleDelete(context, employee);
                  
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
}
