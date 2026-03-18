import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:leadcapture/models/src/worktime_model.dart';
import 'package:leadcapture/services/database/src/spdb.dart';
import 'package:leadcapture/views/ui/src/form_fields.dart';
import 'package:leadcapture/views/ui/src/submit_button.dart';
import '/theme/theme.dart';
import '/utils/utils.dart';

class ClockoutDialog extends StatefulWidget {
  final WorktimeModel model;

  const ClockoutDialog({super.key, required this.model});

  @override
  State<ClockoutDialog> createState() => _ClockoutDialogState();
}

class _ClockoutDialogState extends State<ClockoutDialog> {
  TimeOfDay _mStart = const TimeOfDay(hour: 0, minute: 0);
  TimeOfDay _mEnd = const TimeOfDay(hour: 0, minute: 0);

  TimeOfDay _eStart = const TimeOfDay(hour: 0, minute: 0);
  TimeOfDay _eEnd = const TimeOfDay(hour: 0, minute: 0);

  bool buttonEnabled = false;

  String calculateHours() {
    int mStartMinutes = _mStart.hour * 60 + _mStart.minute;
    int mEndMinutes = _mEnd.hour * 60 + _mEnd.minute;

    int mDifference = mEndMinutes - mStartMinutes;

    if (mDifference < 0) {
      mDifference += 24 * 60; // Handle overnight cases
    }

    int mHours = mDifference;
    int mMinutes = mDifference;

    int eStartMinutes = _eStart.hour * 60 + _eStart.minute;
    int eEndMinutes = _eEnd.hour * 60 + _eEnd.minute;

    int eDifference = eEndMinutes - eStartMinutes;

    if (eDifference < 0) {
      eDifference += 24 * 60; // Handle overnight cases
    }

    int eHours = eDifference;
    int eMinutes = eDifference;

    int hours = (mHours + eHours) ~/ 60;
    int minutes = (mMinutes + eMinutes) % 60;

    return "${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}";
  }

  final TextEditingController _mStartTime = TextEditingController();
  final TextEditingController _mEndTime = TextEditingController();
  final TextEditingController _eStartTime = TextEditingController();
  final TextEditingController _eEndTime = TextEditingController();
  final TextEditingController _reason = TextEditingController();

  final key = GlobalKey<FormState>();

  @override
  void initState() {
    _mStart = TimeOfDay(
      hour: widget.model.clockIn.hour,
      minute: widget.model.clockIn.minute,
    );
    _mStartTime.text = "${_mStart.hour}:${_mStart.minute}";
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(30),
        topRight: Radius.circular(30),
      ),
      child: Scaffold(
        backgroundColor: AppColors.white,
        bottomNavigationBar: SubmitButton(
          event: () async {
            if (key.currentState?.validate() ?? false) {
              final now = widget.model.created;

              var mWorkTimeModel = WorktimeModel(
                breaks: {},
                userUid: '',
                userName: '',
                clockIn: DateTime(
                  now.year,
                  now.month,
                  now.day,
                  _mStart.hour,
                  _mStart.minute,
                ),
                clockOut: DateTime(
                  now.year,
                  now.month,
                  now.day,
                  _mEnd.hour,
                  _mEnd.minute,
                ),
                created: now,
                modified: now,
                reason: _reason.text,
              );

              var uid = await Spdb.getUid();
              var user = await Spdb.getUser();
              var name = user.name;

              var eWorkTimeModel = WorktimeModel(
                breaks: {},
                userUid: uid ?? '',
                userName: name,
                clockIn: DateTime(
                  now.year,
                  now.month,
                  now.day,
                  _eStart.hour,
                  _eStart.minute,
                ),
                clockOut: DateTime(
                  now.year,
                  now.month,
                  now.day,
                  _eEnd.hour,
                  _eEnd.minute,
                ),
                created: now,
                modified: now,
                reason: _reason.text,
              );

              Navigator.pop(context, [mWorkTimeModel, eWorkTimeModel]);
            }
          },
        ),
        body: Form(
          key: key,
          child: ListView(
            padding: const EdgeInsets.all(10),
            children: [
              Text(
                "Clockout info for ${DateFormat('dd-MM-yyyy').format(widget.model.created)}",
                style: Theme.of(
                  context,
                ).textTheme.titleLarge!.copyWith(color: AppColors.primary),
              ),
              const Divider(),
              Text(
                "Morning Session",
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium!.copyWith(color: AppColors.primary),
              ),
              const Divider(),
              Row(
                children: [
                  Expanded(
                    child: FormFields(
                      controller: _mStartTime,
                      label: "Start Time",
                      hintText: "--:--",
                      readOnly: true,
                      onTap: () async {
                        var result = await pickTime(context, null);
                        if (result != null) {
                          _mStart = result;
                          _mStartTime.text =
                              "${_mStart.hour}:${_mStart.minute}";
                        }
                        setState(() {});
                      },
                      valid: (input) {
                        if (input != null) {
                          if (input.isEmpty) {
                            return "*Required";
                          }
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FormFields(
                      controller: _mEndTime,
                      label: "End Time",
                      hintText: "--:--",
                      readOnly: true,
                      onTap: () async {
                        var result = await pickTime(context, null);
                        if (result != null) {
                          _mEnd = result;
                          _mEndTime.text = "${_mEnd.hour}:${_mEnd.minute}";
                        }
                        setState(() {});
                      },
                      valid: (input) {
                        if (input != null) {
                          if (input.isEmpty) {
                            return "*Required";
                          }
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                "Evening Session",
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium!.copyWith(color: AppColors.primary),
              ),
              const Divider(),
              Row(
                children: [
                  Expanded(
                    child: FormFields(
                      controller: _eStartTime,
                      label: "Start Time",
                      hintText: "--:--",
                      readOnly: true,
                      onTap: () async {
                        var result = await pickTime(context, null);
                        if (result != null) {
                          _eStart = result;
                          _eStartTime.text =
                              "${_eStart.hour}:${_eStart.minute}";
                        }
                        setState(() {});
                      },
                      valid: (input) {
                        if (input != null) {
                          if (input.isEmpty) {
                            return "*Required";
                          }
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FormFields(
                      controller: _eEndTime,
                      label: "End Time",
                      hintText: "--:--",
                      readOnly: true,
                      onTap: () async {
                        var result = await pickTime(context, null);
                        if (result != null) {
                          _eEnd = result;
                          _eEndTime.text = "${_eEnd.hour}:${_eEnd.minute}";
                        }
                        setState(() {});
                      },
                      valid: (input) {
                        if (input != null) {
                          if (input.isEmpty) {
                            return "*Required";
                          }
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              FormFields(
                controller: _reason,
                label: "Reason",
                maxLines: 2,
                valid: (input) {
                  if (input != null) {
                    if (input.isEmpty) {
                      return "*Required";
                    }
                  }
                  return null;
                },
              ),
              const SizedBox(height: 10),
              Text("Working Day Duration : ${calculateHours()} Hrs"),
            ],
          ),
        ),
      ),
    );
  }
}
