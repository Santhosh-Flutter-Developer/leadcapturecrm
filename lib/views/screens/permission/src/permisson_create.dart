/*
  Copyright 2024 Srisoftwarez. All rights reserved.
  Use of this source code is governed by a BSD-style license that can be
  found in the LICENSE file.
*/

// Flutter imports:
import 'package:flutter/material.dart';
import 'package:leadcapture/models/src/workpermission_model.dart';
import 'package:leadcapture/services/database/src/spdb.dart';
import 'package:leadcapture/services/firebase/src/workpermission_service.dart';
import 'package:leadcapture/utils/src/work_permission.dart';
import 'package:leadcapture/views/ui/src/form_fields.dart';
import 'package:leadcapture/views/ui/src/loading.dart';
import 'package:leadcapture/views/ui/src/snackbar.dart';
import 'package:leadcapture/views/ui/src/submit_button.dart';

// Project imports:
import '/constants/constants.dart';
import '/utils/utils.dart';

class PermissonCreate extends StatefulWidget {
  const PermissonCreate({super.key});

  @override
  State<PermissonCreate> createState() => _PermissonCreateState();
}

class _PermissonCreateState extends State<PermissonCreate> {
  DateTime selectedDate = DateTime.now();
  TimeOfDay? startTime;
  TimeOfDay? endTime;
  PermissionType selectedType = PermissionType.permission;
  HalfDaySession? selectedSession;

  @override
  void initState() {
    _date.text = DateTime.now().formatDate;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: const Text("Request Permission"),
        ),
        bottomNavigationBar: SubmitButton(
          event: () {
            _submitForm();
          },
        ),
        body: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(10),
            children: [
              const SizedBox(height: 10),
              FormFields(
                label: "Date (*)",
                controller: _date,
                readOnly: true,
                onTap: () async {
                  var result = await datePicker(context);

                  if (result != null) {
                    selectedDate = result;
                    _date.text = selectedDate.formatDate;
                  }
                },
                valid: (input) {
                  return Validation.commonValidation(
                    label: "Date",
                    input: _date.text,
                    isReq: true,
                  );
                },
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<PermissionType>(
                initialValue: selectedType,
                items: PermissionType.values.map((type) {
                  return DropdownMenuItem(value: type, child: Text(type.label));
                }).toList(),
                onChanged: (type) {
                  setState(() {
                    selectedType = type!;

                    if (!selectedType.requiresTime) {
                      startTime = null;
                      endTime = null;
                      _start.clear();
                      _end.clear();
                    }

                    if (selectedType != PermissionType.leaveHalfDay) {
                      selectedSession = null;
                    }
                  });
                },
                decoration: const InputDecoration(
                  labelText: "Permission Type (*)",
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 15,
                  ),
                ),
                validator: (value) =>
                    value == null ? "Please select permission type" : null,
              ),
              const SizedBox(height: 10),
              if (selectedType == PermissionType.leaveHalfDay)
                DropdownButtonFormField<HalfDaySession>(
                  initialValue: selectedSession,
                  items: HalfDaySession.values.map((s) {
                    return DropdownMenuItem(
                      value: s,
                      child: Text(
                        s == HalfDaySession.morning
                            ? "Morning (First Half)"
                            : "Afternoon (Second Half)",
                      ),
                    );
                  }).toList(),
                  onChanged: (v) => setState(() => selectedSession = v),
                  validator: (value) {
                    if (selectedType == PermissionType.leaveHalfDay &&
                        value == null) {
                      return "Please select session";
                    }
                    return null;
                  },
                  decoration: const InputDecoration(
                    labelText: "Session (*)",
                    border: OutlineInputBorder(),
                  ),
                ),
              if (selectedType.requiresTime)
                Row(
                  children: [
                    Expanded(
                      child: FormFields(
                        label: "Start (*)",
                        controller: _start,
                        readOnly: true,
                        valid: (_) => Validation.commonValidation(
                          label: "Start",
                          input: _start.text,
                          isReq: true,
                        ),
                        onTap: () async {
                          var result = await pickTime(context, null);
                          if (result != null) {
                            startTime = result;
                            _start.text =
                                "${result.hour.toString().padLeft(2, '0')}:${result.minute.toString().padLeft(2, '0')}";
                          }
                          setState(() {});
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: FormFields(
                        label: "End (*)",
                        controller: _end,
                        readOnly: true,
                        valid: (_) => Validation.commonValidation(
                          label: "End",
                          input: _end.text,
                          isReq: true,
                        ),
                        onTap: () async {
                          var result = await pickTime(context, null);
                          if (result != null) {
                            endTime = result;
                            _end.text =
                                "${result.hour.toString().padLeft(2, '0')}:${result.minute.toString().padLeft(2, '0')}";
                          }
                          setState(() {});
                        },
                      ),
                    ),
                  ],
                ),
              const SizedBox(height: 10),
              FormFields(
                label: "Reason (*)",
                controller: _reason,
                maxLines: 3,
                valid: (input) {
                  return Validation.commonValidation(
                    isReq: true,
                    label: "Reason",
                    input: _reason.text,
                  );
                },
              ),
              const SizedBox(height: 10),

              if (selectedType.requiresTime)
                Text(
                  "Duration: ${getDurationDates(DateTime(selectedDate.year, selectedDate.month, selectedDate.day, startTime?.hour ?? 0, startTime?.minute ?? 0), DateTime(selectedDate.year, selectedDate.month, selectedDate.day, endTime?.hour ?? 0, endTime?.minute ?? 0)).inHours} hours and "
                  "${getDurationDates(DateTime(selectedDate.year, selectedDate.month, selectedDate.day, startTime?.hour ?? 0, startTime?.minute ?? 0), DateTime(selectedDate.year, selectedDate.month, selectedDate.day, endTime?.hour ?? 0, endTime?.minute ?? 0)).inMinutes % 60} minutes",
                  style: Theme.of(context).textTheme.bodyLarge,
                  textAlign: TextAlign.center,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      try {
        futureLoading(context);

        var uid = await Spdb.getUid();
        var user = await Spdb.getUser();
        var name = user.name;
        DateTime fromDate;
        DateTime toDate;

        if (selectedType.requiresTime) {
          fromDate = DateTime(
            selectedDate.year,
            selectedDate.month,
            selectedDate.day,
            startTime!.hour,
            startTime!.minute,
          );

          toDate = DateTime(
            selectedDate.year,
            selectedDate.month,
            selectedDate.day,
            endTime!.hour,
            endTime!.minute,
          );
        } else if (selectedType == PermissionType.leaveHalfDay) {
          if (selectedSession == HalfDaySession.morning) {
            fromDate = DateTime(
              selectedDate.year,
              selectedDate.month,
              selectedDate.day,
              9,
              0,
            );
            toDate = DateTime(
              selectedDate.year,
              selectedDate.month,
              selectedDate.day,
              13,
              0,
            );
          } else {
            fromDate = DateTime(
              selectedDate.year,
              selectedDate.month,
              selectedDate.day,
              14,
              0,
            );
            toDate = DateTime(
              selectedDate.year,
              selectedDate.month,
              selectedDate.day,
              18,
              0,
            );
          }
        } else {
          fromDate = selectedDate;
          toDate = selectedDate;
        }

        var model = WorkPermissionModel(
          uid: '',
          userId: uid ?? '',
          userName: name,
          reason: _reason.text,
          date: selectedDate,
          status: PermissionsStatus.pending,
          type: selectedType,
          from: fromDate,
          to: toDate,
          session: selectedType == PermissionType.leaveHalfDay
              ? selectedSession
              : null,
          created: DateTime.now(),
          modified: DateTime.now(),
        );
        await WorkPermissionService.createPermission(model: model);

        Navigator.pop(context);
        Snackbar.showSnackBar(
          context,
          content: "Permission requested successfully",
          isSuccess: true,
        );

        Navigator.pop(context, true);
      } catch (e) {
        Navigator.pop(context);
        Snackbar.showSnackBar(context, content: e.toString(), isSuccess: false);
      }
    }
  }

  final TextEditingController _date = TextEditingController();
  final TextEditingController _start = TextEditingController();
  final TextEditingController _end = TextEditingController();
  final TextEditingController _reason = TextEditingController();
  final _formKey = GlobalKey<FormState>();
}
