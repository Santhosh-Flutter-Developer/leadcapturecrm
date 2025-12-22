import 'dart:io';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:mime/mime.dart';
import 'package:path/path.dart' as path;
import '/constants/constants.dart';
import '/models/models.dart';
import '/services/services.dart';
import '/theme/theme.dart';
import '/utils/utils.dart';
import '/views/views.dart';

class TaskCreate extends StatefulWidget {
  final List<EmployeeModel>? employees;

  const TaskCreate({super.key, this.employees});

  @override
  State<TaskCreate> createState() => _TaskCreateState();
}

class _TaskCreateState extends State<TaskCreate> {
  late Future _future;
  bool _highPriority = false;
  bool _taskStatusSummary = false;
  final TextEditingController _taskName = TextEditingController();
  final TextEditingController _description = TextEditingController();
  final TextEditingController _deadLine = TextEditingController();
  final TextEditingController _tags = TextEditingController();
  final TextEditingController _reminder = TextEditingController();
  List<EmployeeModel> _employeeList = [];
  List<ProjectModel> _projectList = [];
  List<LeadModel> _leadList = [];
  List<TaskModel> _taskList = [];
  final List<String> _selectedAssignees = [];
  final List<String> _selectedCreatedBy = [];
  final List<String> _selectedObservers = [];
  final List<String> _selectedParticipants = [];

  late final List<EmployeeModel> _initialAssignees;

  String? _selectedProject;
  String? _selectedLead;
  String? _selectedSubTaskOf;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final List<File> _selectedAttachments = [];
  DateTime? _selectedDeadLine;
  DateTime? _selectedReminder;
  bool _deadlineRequired = false;

  @override
  void initState() {
    super.initState();
    _future = _init();

    if (widget.employees != null && widget.employees!.isNotEmpty) {
      _initialAssignees = widget.employees!;
      for (final emp in widget.employees!) {
        if (emp.uid != null) {
          _selectedAssignees.add(emp.uid!);
        }
      }
    } else {
      _initialAssignees = [];
    }
  }

  Future<void> _init() async {
    try {
      _employeeList.clear();
      _employeeList = await EmployeeService.getAllEmployees();
      _projectList.clear();
      _projectList = await ProjectService.getAllProjects();
      _leadList.clear();
      _leadList = await LeadService.getAllLeads();
      _taskList.clear();
      _taskList = await TaskService.getAllTasks();
    } catch (e) {
      FlushBar.show(context, e.toString(), isSuccess: false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(16),
        bottomLeft: Radius.circular(16),
      ),
      child: Scaffold(
        appBar: FormWidgets.buildHeader(context: context, title: "Create Task"),
        body: FutureBuilder(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const WaitingLoading();
            } else if (snapshot.hasError) {
              return ErrorDisplay(error: snapshot.error.toString());
            } else {
              return Form(
                key: _formKey,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: SingleChildScrollView(
                    child: Container(
                      padding: EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _taskName,
                                  style: Theme.of(context).textTheme.bodyMedium!
                                      .copyWith(
                                        color: AppColors.black,
                                        fontWeight: FontWeight.w500,
                                      ),
                                  decoration: InputDecoration(
                                    hintText: 'Enter Task Name',
                                    hintStyle: Theme.of(context)
                                        .textTheme
                                        .bodyMedium!
                                        .copyWith(color: AppColors.grey400),
                                    filled: true,
                                    fillColor: AppColors.transparent,
                                  ),
                                  validator: (value) =>
                                      Validation.commonValidation(
                                        input: value,
                                        label: 'Task Name',
                                        isReq: true,
                                      ),
                                ),
                              ),
                              Row(
                                children: [
                                  Transform.scale(
                                    scale: 0.75,
                                    child: Checkbox(
                                      value: _highPriority,
                                      onChanged: (val) {
                                        if (val != null) {
                                          setState(() => _highPriority = val);
                                        }
                                      },
                                      visualDensity: VisualDensity.compact,
                                      materialTapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap,
                                      activeColor: AppColors.primary,
                                    ),
                                  ),
                                  Text(
                                    'High Priority',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodySmall,
                                  ),
                                  const SizedBox(width: 8),
                                  Icon(
                                    Icons.whatshot_outlined,
                                    color: _highPriority
                                        ? AppColors.danger
                                        : AppColors.grey400,
                                    size: 18,
                                  ),
                                ],
                              ),
                            ],
                          ),
                          Divider(indent: 0, endIndent: 0, height: 0),
                          TextFormField(
                            controller: _description,
                            style: Theme.of(context).textTheme.bodyMedium!
                                .copyWith(
                                  color: AppColors.black,
                                  fontWeight: FontWeight.w500,
                                ),
                            maxLines: 3,
                            decoration: InputDecoration(
                              hintText: 'Enter Description',
                              hintStyle: Theme.of(context).textTheme.bodyMedium!
                                  .copyWith(color: AppColors.grey400),
                              filled: true,
                              fillColor: AppColors.transparent,
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              TextButton.icon(
                                label: Text(
                                  "Attach File",
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                                icon: Icon(Iconsax.attach_circle),
                                onPressed: () async {
                                  var files = await FilePick.pickFiles(context);
                                  if (files != null && files.isNotEmpty) {
                                    _selectedAttachments.addAll(files);
                                    setState(() {});
                                  }
                                },
                              ),
                              Wrap(
                                alignment: WrapAlignment.start,
                                children: _selectedAttachments
                                    .map(
                                      (e) => Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: Chip(
                                          label: Text(
                                            path.basename(e.path),
                                            style: Theme.of(
                                              context,
                                            ).textTheme.bodySmall,
                                          ),
                                          deleteIcon: Icon(Icons.close),
                                          onDeleted: () {
                                            _selectedAttachments.remove(e);
                                            setState(() {});
                                          },
                                          side: BorderSide(
                                            color: AppColors.primary,
                                          ),
                                        ),
                                      ),
                                    )
                                    .toList(),
                              ),
                            ],
                          ),
                          Divider(indent: 0, endIndent: 0),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Row(
                              children: [
                                SizedBox(
                                  width: 180,
                                  child: Text(
                                    "Assignee",
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodySmall,
                                  ),
                                ),
                                Expanded(
                                  child: CustomSearchableDropdown<String>(
                                    initialValues: _initialAssignees
                                        .map((e) => e.name)
                                        .toList(),
                                    items: _employeeList
                                        .map((e) => e.name)
                                        .toList(),
                                    multiSelect: true,
                                    onChangedList: (list) {
                                      for (var name in list) {
                                        final emp = _employeeList.firstWhere(
                                          (e) => e.name == name,
                                        );
                                        if (emp.uid != null &&
                                            !_selectedAssignees.contains(
                                              emp.uid,
                                            )) {
                                          _selectedAssignees.add(emp.uid!);
                                        }
                                      }
                                    },
                                    itemAsString: (s) => s,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Divider(indent: 0, endIndent: 0),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Row(
                              children: [
                                SizedBox(
                                  width: 180,
                                  child: Text(
                                    "Participants",
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodySmall,
                                  ),
                                ),
                                Expanded(
                                  child: CustomSearchableDropdown<String>(
                                    items: _employeeList
                                        .map((e) => e.name)
                                        .toList(),
                                    multiSelect: true,
                                    onChangedList: (list) {
                                      for (var i in list) {
                                        final emp = _employeeList.firstWhere(
                                          (element) => element.name == i,
                                        );

                                        if (emp.uid != null) {
                                          if (!_selectedParticipants.contains(
                                            emp.uid,
                                          )) {
                                            _selectedParticipants.add(emp.uid!);
                                          }
                                        }
                                      }
                                    },
                                    itemAsString: (s) => s,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Divider(indent: 0, endIndent: 0),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Row(
                              children: [
                                SizedBox(
                                  width: 180,
                                  child: Text(
                                    "Created By",
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodySmall,
                                  ),
                                ),
                                Expanded(
                                  child: CustomSearchableDropdown<String>(
                                    items: _employeeList
                                        .map((e) => e.name)
                                        .toList(),
                                    multiSelect: true,
                                    onChangedList: (list) {
                                      for (var i in list) {
                                        final emp = _employeeList.firstWhere(
                                          (element) => element.name == i,
                                        );

                                        if (emp.uid != null) {
                                          if (!_selectedCreatedBy.contains(
                                            emp.uid,
                                          )) {
                                            _selectedCreatedBy.add(emp.uid!);
                                          }
                                        }
                                      }
                                    },
                                    itemAsString: (s) => s,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Divider(indent: 0, endIndent: 0),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Row(
                              children: [
                                SizedBox(
                                  width: 180,
                                  child: Text(
                                    "Observers",
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodySmall,
                                  ),
                                ),
                                Expanded(
                                  child: CustomSearchableDropdown<String>(
                                    items: _employeeList
                                        .map((e) => e.name)
                                        .toList(),
                                    multiSelect: true,
                                    onChangedList: (list) {
                                      for (var i in list) {
                                        final emp = _employeeList.firstWhere(
                                          (element) => element.name == i,
                                        );

                                        if (emp.uid != null) {
                                          if (!_selectedObservers.contains(
                                            emp.uid,
                                          )) {
                                            _selectedObservers.add(emp.uid!);
                                          }
                                        }
                                      }
                                    },
                                    itemAsString: (s) => s,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Divider(indent: 0, endIndent: 0),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: LayoutBuilder(
                              builder: (context, constraints) {
                                final isMobile = constraints.maxWidth < 600;

                                if (isMobile) {
                                  return Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "Deadline",
                                        style: Theme.of(
                                          context,
                                        ).textTheme.bodySmall,
                                      ),
                                      const SizedBox(height: 8),

                                      FormFields(
                                        enabled: _deadlineRequired,
                                        controller: _deadLine,
                                        readOnly: true,
                                        onTap: () async {
                                          var date = await datePicker(context);
                                          if (date != null) {
                                            var time = await pickTime(
                                              context,
                                              null,
                                            );
                                            if (time != null) {
                                              _deadLine.text =
                                                  '${date.formatDate} ${time.hour}:${time.minute}:00';
                                              _selectedDeadLine = date.copyWith(
                                                hour: time.hour,
                                                minute: time.minute,
                                              );
                                              setState(() {});
                                            }
                                          }
                                        },
                                        hintText: 'Select Deadline',
                                        suffixIcon: const Icon(
                                          Iconsax.calendar,
                                        ),
                                      ),

                                      const SizedBox(height: 12),

                                      Row(
                                        children: [
                                          Transform.scale(
                                            scale: 0.8,
                                            child: Checkbox(
                                              value: _deadlineRequired,
                                              onChanged: (val) {
                                                if (val != null) {
                                                  setState(
                                                    () =>
                                                        _deadlineRequired = val,
                                                  );
                                                }
                                              },
                                              activeColor: AppColors.primary,
                                              visualDensity:
                                                  VisualDensity.compact,
                                              materialTapTargetSize:
                                                  MaterialTapTargetSize
                                                      .shrinkWrap,
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            "Deadline Required",
                                            style: Theme.of(
                                              context,
                                            ).textTheme.bodyMedium,
                                          ),
                                        ],
                                      ),
                                    ],
                                  );
                                }

                                return Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    SizedBox(
                                      width: 180,
                                      child: Text(
                                        "Deadline",
                                        style: Theme.of(
                                          context,
                                        ).textTheme.bodySmall,
                                      ),
                                    ),
                                    const SizedBox(width: 8),

                                    Expanded(
                                      child: FormFields(
                                        enabled: _deadlineRequired,
                                        controller: _deadLine,
                                        readOnly: true,
                                        onTap: () async {
                                          var date = await datePicker(context);
                                          if (date != null) {
                                            var time = await pickTime(
                                              context,
                                              null,
                                            );
                                            if (time != null) {
                                              _deadLine.text =
                                                  '${date.formatDate} ${time.hour}:${time.minute}:00';
                                              _selectedDeadLine = date.copyWith(
                                                hour: time.hour,
                                                minute: time.minute,
                                              );
                                              setState(() {});
                                            }
                                          }
                                        },
                                        hintText: 'Select Deadline',
                                        suffixIcon: const Icon(
                                          Iconsax.calendar,
                                        ),
                                      ),
                                    ),

                                    const SizedBox(width: 16),

                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Transform.scale(
                                          scale: 0.75,
                                          child: Checkbox(
                                            value: _deadlineRequired,
                                            onChanged: (val) {
                                              if (val != null) {
                                                setState(
                                                  () => _deadlineRequired = val,
                                                );
                                              }
                                            },
                                            visualDensity:
                                                VisualDensity.compact,
                                            materialTapTargetSize:
                                                MaterialTapTargetSize
                                                    .shrinkWrap,
                                            activeColor: AppColors.primary,
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          'Deadline Required',
                                          style: Theme.of(
                                            context,
                                          ).textTheme.bodySmall,
                                        ),
                                      ],
                                    ),
                                  ],
                                );
                              },
                            ),
                          ),

                          Divider(indent: 0, endIndent: 0),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Row(
                              children: [
                                SizedBox(
                                  width: 180,
                                  child: Text(
                                    "Task Status Summary",
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodySmall,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Flexible(
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Transform.scale(
                                        scale: 0.75,
                                        child: Checkbox(
                                          value: _taskStatusSummary,
                                          onChanged: (val) {
                                            if (val != null) {
                                              setState(
                                                () => _taskStatusSummary = val,
                                              );
                                            }
                                          },
                                          visualDensity: VisualDensity.compact,
                                          materialTapTargetSize:
                                              MaterialTapTargetSize.shrinkWrap,
                                          activeColor: AppColors.primary,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Text(
                                          'Task Status Summary Required',
                                          style: Theme.of(
                                            context,
                                          ).textTheme.bodySmall,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),

                          SizedBox(height: 40),
                          Text(
                            'Other Details',
                            style: Theme.of(context).textTheme.titleMedium!
                                .copyWith(fontWeight: FontWeight.bold),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Row(
                              children: [
                                SizedBox(
                                  width: 180,
                                  child: Text(
                                    "Project",
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodySmall,
                                  ),
                                ),
                                Flexible(
                                  child: FormDropdownSearch(
                                    items: _projectList
                                        .map((e) => e.projectName)
                                        .toList(),
                                    onChanged: (value) {
                                      final project = _projectList.firstWhere(
                                        (element) =>
                                            element.projectName == value,
                                      );

                                      if (project.uid != null) {
                                        _selectedProject = project.uid!;
                                      }
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Divider(indent: 0, endIndent: 0),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Row(
                              children: [
                                SizedBox(
                                  width: 180,
                                  child: Text(
                                    "Sub Task Of",
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodySmall,
                                  ),
                                ),
                                Flexible(
                                  child: FormDropdownSearch(
                                    items: _taskList
                                        .map((e) => e.taskName)
                                        .toList(),
                                    onChanged: (value) {
                                      final task = _taskList.firstWhere(
                                        (element) => element.taskName == value,
                                      );

                                      if (task.uid != null) {
                                        _selectedSubTaskOf = task.uid!;
                                      }
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Divider(indent: 0, endIndent: 0),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Row(
                              children: [
                                SizedBox(
                                  width: 180,
                                  child: Text(
                                    "Lead",
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodySmall,
                                  ),
                                ),
                                Flexible(
                                  child: FormDropdownSearch(
                                    items: _leadList
                                        .map((e) => e.leadName)
                                        .toList(),
                                    onChanged: (value) {
                                      final lead = _leadList.firstWhere(
                                        (element) => element.leadName == value,
                                      );

                                      if (lead.uid != null) {
                                        _selectedLead = lead.uid!;
                                      }
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Divider(indent: 0, endIndent: 0),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Row(
                              children: [
                                SizedBox(
                                  width: 180,
                                  child: Text(
                                    "Tags",
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodySmall,
                                  ),
                                ),
                                Flexible(
                                  child: FormFields(
                                    hintText: 'Enter Tags',
                                    controller: _tags,
                                    maxLines: 2,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Divider(indent: 0, endIndent: 0),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Row(
                              children: [
                                SizedBox(
                                  width: 180,
                                  child: Text(
                                    "Reminder",
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodySmall,
                                  ),
                                ),
                                Flexible(
                                  child: FormFields(
                                    controller: _reminder,
                                    readOnly: true,
                                    onTap: () async {
                                      var date = await datePicker(context);
                                      if (date != null) {
                                        var time = await pickTime(
                                          context,
                                          null,
                                        );
                                        if (time != null) {
                                          _reminder.text =
                                              '${date.formatDate} ${time.hour}:${time.minute}:00';
                                          _selectedReminder = date.copyWith(
                                            hour: time.hour,
                                            minute: time.minute,
                                          );
                                          setState(() {});
                                        }
                                      }
                                    },
                                    hintText: 'Select Reminder',
                                    suffixIcon: Icon(Iconsax.calendar),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }
          },
        ),
        bottomNavigationBar: FormWidgets.buildBottomBar(
          context: context,
          onSubmit: _submitForm,
          isEdit: false,
        ),
      ),
    );
  }

  void _submitForm() async {
    if (_formKey.currentState!.validate()) {
      try {
        futureLoading(context);

        List<FileModel> attachments = [];

        if (_selectedAttachments.isNotEmpty) {
          List<String> urls = await StorageService.uploadFilesInBatch(
            files: _selectedAttachments,
            folder: StorageFolder.taskAttachments,
          );

          for (var i = 0; i < _selectedAttachments.length; i++) {
            var file = File(_selectedAttachments[i].path);
            var mimeType = lookupMimeType(file.path) ?? '';

            attachments.add(
              FileModel(
                name: path.basename(file.path),
                extension: path.extension(file.path).replaceAll('.', ''),
                size: file.lengthSync(),
                url: urls[i],
                mimeType: mimeType,
              ),
            );
          }
        }

        final task = TaskModel(
          taskName: _taskName.text,
          description: _description.text,
          project: _selectedProject,
          subTaskOf: _selectedSubTaskOf,
          lead: _selectedLead,
          deadline: _selectedDeadLine,
          deadlineRequired: _deadlineRequired,
          highPriority: _highPriority,
          statusSummaryRequired: _taskStatusSummary,
          assignees: _selectedAssignees,
          createdBy: _selectedCreatedBy,
          observers: _selectedObservers,
          participants: _selectedParticipants,
          reminder: _selectedReminder,
          tags: _tags.text.split(','),
          attachments: attachments,
          taskCreatedBy: await Spdb.getUser(),
        );

        await TaskService.createTask(task: task);

        if (Navigator.canPop(context)) {
          Navigator.pop(context);
        }
        Navigator.pop(context, true); // Close page

        FlushBar.show(context, 'Task created successfully', isSuccess: true);
      } catch (e, st) {
        await ErrorService.recordError(e, st);
        debugPrint("$e, $st");

        if (Navigator.canPop(context)) {
          Navigator.pop(context);
        }
        FlushBar.show(
          context,
          e.toString(),
          isSuccess: false,
          error: e,
          stackTrace: st,
        );
      }
    }
  }
}
