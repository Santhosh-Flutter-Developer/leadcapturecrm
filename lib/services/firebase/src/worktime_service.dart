// Package imports:
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:leadcapture/models/src/filter_model.dart';
import 'package:leadcapture/models/src/notification_model.dart';
import 'package:leadcapture/models/src/worktime_model.dart';
import 'package:leadcapture/services/firebase/src/attendance_service.dart';

// Project imports:
import '/constants/constants.dart';
import '/services/services.dart';

class WorktimeService {
  static FirebaseConfig firebase = FirebaseConfig();
  static Future<String> createWorkTime({required WorktimeModel model}) async {
    try {
      var cid = await Spdb.getCid();
      if (cid == null) {
        throw Exception("Company ID not found - cannot clock in");
      }
      String result = "";

      var docRef = await firebase.users
          .doc(cid)
          .collection(Collections.worktime.name)
          .add(model.toMap());

      result = docRef.id;

      return result;
    } catch (e) {
      throw e.toString();
    }
  }

  // static Future<String> createWrongLoginAttempt({
  //   required LatLng points,
  // }) async {
  //   try {
  //     var cid = await Db.getData(type: UserData.collectionId);

  //     String result = "";

  //     if (cid != null) {
  //       var docRef = await firebase.users
  //           .doc(cid)
  //           .collection(Collections.outsideLoginAttempt.name)
  //           .add({
  //             "points": GeoPoint(points.latitude, points.longitude),
  //             "created": DateTime.now().millisecondsSinceEpoch,
  //             "userId": await Db.getData(type: UserData.uid),
  //             "userName": await Db.getData(type: UserData.name),
  //           });

  //       result = docRef.id;
  //     }mo

  //     return result;
  //   } catch (e) {
  //     throw e.toString();
  //   }
  // }

  static Future<WorktimeModel> getClockIn({required String id}) async {
    try {
      var i = await WorktimeService.processClockIn(id: id);
      // if (i.isNotEmpty) {
      return WorktimeModel(
        uid: i["uid"],
        userName: i["userName"],
        userUid: i["userUid"],
        clockIn: DateTime.fromMillisecondsSinceEpoch(i["clockIn"]),
        breaks: i["breaks"],
        clockOut: i["clockOut"] != null
            ? DateTime.fromMillisecondsSinceEpoch(i["clockOut"])
            : null,
        created: DateTime.fromMillisecondsSinceEpoch(i["created"]),
        modified: DateTime.fromMillisecondsSinceEpoch(i["modified"]),
      );
      // }
    } catch (e) {
      throw e.toString();
    }
  }

  static Future<Map<String, dynamic>> processClockIn({
    required String id,
  }) async {
    try {
      var cid = await Spdb.getCid();

      Map<String, dynamic> result = {};

      if (cid != null) {
        var docRef = await firebase.users
            .doc(cid)
            .collection(Collections.worktime.name)
            .doc(id)
            .get();

        result = docRef.data() ?? {};
        result['uid'] = docRef.id;
      }

      return result;
    } catch (e) {
      throw e.toString();
    }
  }

  static Future<Map<String, dynamic>> getWorkFromHome({
    required String id,
  }) async {
    try {
      var cid = await Spdb.getCid();

      Map<String, dynamic> result = {};

      if (cid != null) {
        var docRef = await firebase.users
            .doc(cid)
            .collection(Collections.worktimeFromHome.name)
            .doc(id)
            .get();

        result = docRef.data() ?? {};
        result['uid'] = docRef.id;
      }

      return result;
    } catch (e) {
      throw e.toString();
    }
  }

  static Future clockOut({required String id}) async {
    try {
      var cid = await Spdb.getCid();

      if (cid != null) {
        await firebase.users
            .doc(cid)
            .collection(Collections.worktime.name)
            .doc(id)
            .update({"clockOut": DateTime.now().millisecondsSinceEpoch});

        await AttendanceService.generateTodayAttendance();
      }
    } catch (e) {
      throw e.toString();
    }
  }

  static Future<bool> checkDayEnd() async {
    try {
      var cid = await Spdb.getCid();
      var uid = await Spdb.getUid();

      if (cid == null || uid == null) return false;

      DateTime now = DateTime.now();

      int todayStart = DateTime(
        now.year,
        now.month,
        now.day,
      ).millisecondsSinceEpoch;

      int todayEnd = DateTime(
        now.year,
        now.month,
        now.day,
        23,
        59,
        59,
      ).millisecondsSinceEpoch;

      var snapshot = await firebase.users
          .doc(cid)
          .collection(Collections.worktime.name)
          .where('userUid', isEqualTo: uid)
          .where('clockIn', isGreaterThanOrEqualTo: todayStart)
          .where('clockIn', isLessThanOrEqualTo: todayEnd)
          .orderBy('clockIn', descending: true)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) {
        return false;
      }

      var data = snapshot.docs.first.data();

      if (data.containsKey('clockOut') && data['clockOut'] != null) {
        return true;
      }


      return false;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> checkYesterdayClockedOut() async {
    try {
      var cid = await Spdb.getCid();
      var uid = await Spdb.getUid();

      var docRef = await firebase.users
          .doc(cid)
          .collection(Collections.worktime.name)
          .where('userUid', isEqualTo: uid)
          .where(
            'clockIn',
            isGreaterThanOrEqualTo: DateTime(
              DateTime.now().subtract(const Duration(days: 1)).year,
              DateTime.now().subtract(const Duration(days: 1)).month,
              DateTime.now().subtract(const Duration(days: 1)).day,
              00,
              00,
              00,
            ).millisecondsSinceEpoch,
          )
          .where(
            'clockIn',
            isLessThanOrEqualTo: DateTime(
              DateTime.now().subtract(const Duration(days: 1)).year,
              DateTime.now().subtract(const Duration(days: 1)).month,
              DateTime.now().subtract(const Duration(days: 1)).day,
              23,
              59,
              59,
            ).millisecondsSinceEpoch,
          )
          .where('clockOut', isNull: true)
          .get();

      return docRef.docs.isNotEmpty; // true
    } catch (e) {
      throw e.toString();
    }
  }

  static Future<bool> checkAlreadyClockedIn() async {
    try {
      var cid = await Spdb.getCid();
      var uid = await Spdb.getUid();

      var docRef = await firebase.users
          .doc(cid)
          .collection(Collections.worktime.name)
          .where('userUid', isEqualTo: uid)
          .where(
            'clockIn',
            isGreaterThanOrEqualTo: DateTime(
              DateTime.now().year,
              DateTime.now().month,
              DateTime.now().day,
              00,
              00,
              00,
            ).millisecondsSinceEpoch,
          )
          .where(
            'clockIn',
            isLessThanOrEqualTo: DateTime(
              DateTime.now().year,
              DateTime.now().month,
              DateTime.now().day,
              23,
              59,
              59,
            ).millisecondsSinceEpoch,
          )
          .where('clockOut', isNull: true)
          .get();

      return docRef
          .docs
          .isEmpty; 
    } catch (e) {
      throw e.toString();
    }
  }

  static Future<String?> checkAlreadyClockedInReturnId() async {
    try {
      var cid = await Spdb.getCid();
      var uid = await Spdb.getUid();

      var docRef = await firebase.users
          .doc(cid)
          .collection(Collections.worktime.name)
          .where('userUid', isEqualTo: uid)
          .where(
            'clockIn',
            isGreaterThanOrEqualTo: DateTime(
              DateTime.now().year,
              DateTime.now().month,
              DateTime.now().day,
              00,
              00,
              00,
            ).millisecondsSinceEpoch,
          )
          .where(
            'clockIn',
            isLessThanOrEqualTo: DateTime(
              DateTime.now().year,
              DateTime.now().month,
              DateTime.now().day,
              23,
              59,
              59,
            ).millisecondsSinceEpoch,
          )
          .where('clockOut', isNull: true)
          .get();

      if (docRef.docs.isNotEmpty) {
        return docRef.docs.first.id;
      }
      return null;
    } catch (e) {
      throw e.toString();
    }
  }

  static Future updateWorkTime({
    required String id,
    required WorktimeModel model,
  }) async {
    try {
      var cid = await Spdb.getCid();

      String result = "";

      if (cid != null) {
        await firebase.users
            .doc(cid)
            .collection(Collections.worktime.name)
            .doc(id)
            .update(model.toUpdateMap());
      }

      return result;
    } catch (e) {
      throw e.toString();
    }
  }

  static Future updatePreviousDayClockOut({
    required String id,
    required List<WorktimeModel> model,
  }) async {
    try {
      var cid = await Spdb.getCid();

      String result = "";

      if (cid != null) {
        await firebase.users
            .doc(cid)
            .collection(Collections.worktime.name)
            .doc(id)
            .update(model[0].toClockOutMap());

        await firebase.users
            .doc(cid)
            .collection(Collections.worktime.name)
            .add(model[1].toMap());
      }

      await sendNotification();

      return result;
    } catch (e) {
      throw e.toString();
    }
  }

  static Future<void> sendNotification() async {
    var cid = await Spdb.getCid();
    final user = await Spdb.getUser();

    var name = user.name;
    List<String> receiverFcmIds = [];
    var receivers = await firebase.users
        .doc(cid)
        .collection(Collections.users.name)
        .where('type', isEqualTo: 'admin')
        .get();

    receiverFcmIds = (receivers.docs).map((e) {
      return e['fcmId'].toString();
    }).toList();

    var notificationModel = NotificationModel(
      body: '$name has forgot yesterday clockout',
      title: 'Forgot clockout',
      type: NotificationType.alert,
      createdAt: DateTime.now(),
      to: receiverFcmIds,
    );
    if (receiverFcmIds.isNotEmpty) {
      PostNotificationService.sendNotification(model: notificationModel);
    }
  }

  static Future<int> workTimesCount() async {
    try {
      var cid = await Spdb.getCid();
      var uid = await Spdb.getUid();

      var workTimesCount = await firebase.users
          .doc(cid)
          .collection(Collections.worktime.name)
          .where('userUid', isEqualTo: uid)
          .count()
          .get();

      return workTimesCount.count ?? 0;
    } catch (e) {
      throw e.toString();
    }
  }

  static Future<int> workTimesReportCount() async {
    try {
      var cid = await Spdb.getCid();

      var workTimesCount = await firebase.users
          .doc(cid)
          .collection(Collections.worktime.name)
          .count()
          .get();

      return workTimesCount.count ?? 0;
    } catch (e) {
      throw e.toString();
    }
  }

  static Future<List<WorktimeModel>> worktimeListing({
    required FilterModel filter,
  }) async {
    try {
      List<WorktimeModel> data = [];
      var cid = await Spdb.getCid();
      var uid = await Spdb.getUid();

      int skipCount = (filter.pageNumber - 1) * filter.pageLimit;

      var workTimesQuery = firebase.users
          .doc(cid)
          .collection(Collections.worktime.name)
          .where('userUid', isEqualTo: uid)
          .where('clockOut', isNull: false)
          .where(
            'created',
            isGreaterThanOrEqualTo: filter.fromDate.millisecondsSinceEpoch,
          )
          .where(
            'created',
            isLessThanOrEqualTo: filter.toDate.millisecondsSinceEpoch,
          )
          .orderBy('created', descending: true)
          .limit(filter.pageLimit);

      if (skipCount > 0) {
        var previousPageSnapshot = await workTimesQuery.get(
          const GetOptions(source: Source.serverAndCache),
        );
        if (previousPageSnapshot.docs.isNotEmpty) {
          var lastVisible = previousPageSnapshot.docs[skipCount - 1];
          workTimesQuery = workTimesQuery.startAfterDocument(lastVisible);
        }
      }

      var workTimes = await workTimesQuery.get(
        const GetOptions(source: Source.serverAndCache),
      );

      if (workTimes.docs.isNotEmpty) {
        for (var i in workTimes.docs) {
          var dList = i.data();
          dList["uid"] = i.id;
          data.add(WorktimeModel.fromMap(i.id, dList));
        }
      }

      return data;
    } catch (e) {
      throw e.toString();
    }
  }

  static Future<List<WorktimeModel>> dashboardWorktimeListing({
    required DateTime date,
  }) async {
    try {
      List<WorktimeModel> data = [];
      var cid = await Spdb.getCid();

      var workTimesQuery = firebase.users
          .doc(cid)
          .collection(Collections.worktime.name)
          .where(
            'created',
            isGreaterThanOrEqualTo: DateTime(
              date.year,
              date.month,
              date.day,
              00,
              00,
              00,
            ).millisecondsSinceEpoch,
          )
          .where(
            'created',
            isLessThanOrEqualTo: DateTime(
              date.year,
              date.month,
              date.day,
              23,
              59,
              59,
            ).millisecondsSinceEpoch,
          )
          .orderBy('created', descending: true);

      var workTimes = await workTimesQuery.get(
        const GetOptions(source: Source.serverAndCache),
      );

      if (workTimes.docs.isNotEmpty) {
        for (var i in workTimes.docs) {
          var dList = i.data();
          dList["uid"] = i.id;
          data.add(WorktimeModel.fromMap(i.id, dList));
        }
      }

      return data;
    } catch (e) {
      throw e.toString();
    }
  }

  static Future<List<WorkingHoursCalendarModel>> dashboardWorktimeMonthListing({
    required DateTime date,
    required List<String> uids,
  }) async {
    try {
      List<WorkingHoursCalendarModel> data = [];
      for (var i in uids) {
        List<DateTime> presentDays = [];
        List<DateTime> absentDays = [];
        List<DateTime> officeLeaveDays = [];

        var cid = await Spdb.getCid();

        var workTimesQuery = firebase.users
            .doc(cid)
            .collection(Collections.worktime.name)
            .where(
              'created',
              isGreaterThanOrEqualTo: DateTime(
                date.year,
                date.month,
                1,
              ).millisecondsSinceEpoch,
            )
            .where(
              'created',
              isLessThanOrEqualTo: DateTime(
                date.year,
                date.month,
                date.day,
                23,
                59,
                59,
              ).millisecondsSinceEpoch,
            )
            .where('userUid', isEqualTo: i)
            .orderBy('created', descending: true);

        var workTimes = await workTimesQuery.get(
          const GetOptions(source: Source.serverAndCache),
        );

        if (workTimes.docs.isNotEmpty) {
          for (var j in workTimes.docs) {
            final presentDate = DateTime.fromMillisecondsSinceEpoch(
              j['created'],
            );
            // Add only the date part (no time) to match comparisons later
            presentDays.add(
              DateTime(presentDate.year, presentDate.month, presentDate.day),
            );
          }
        }

        for (int d = 1; d <= date.day; d++) {
          DateTime current = DateTime(date.year, date.month, d);
          if (current.weekday == DateTime.sunday) {
            officeLeaveDays.add(current);
          } else if (!presentDays.contains(current)) {
            absentDays.add(current);
          }
        }

        data.add(
          WorkingHoursCalendarModel(
            absentDays: absentDays,
            presentDays: presentDays,
            officeHolidays: officeLeaveDays,
          ),
        );
      }

      return data;
    } catch (e) {
      throw e.toString();
    }
  }

  static Future<List<WorktimeModel>> userWorktimeListing({
    required String userId,
  }) async {
    try {
      List<WorktimeModel> data = [];
      var cid = await Spdb.getCid();

      var workTimesQuery = firebase.users
          .doc(cid)
          .collection(Collections.worktime.name)
          .where('userUid', isEqualTo: userId)
          .where(
            'created',
            isGreaterThanOrEqualTo: DateTime(
              DateTime.now().year,
              DateTime.now().month,
              DateTime.now().day,
              00,
              00,
              00,
            ).millisecondsSinceEpoch,
          )
          .where(
            'created',
            isLessThanOrEqualTo: DateTime(
              DateTime.now().year,
              DateTime.now().month,
              DateTime.now().day,
              23,
              59,
              59,
            ).millisecondsSinceEpoch,
          )
          .orderBy('created', descending: true);

      var workTimes = await workTimesQuery.get(
        const GetOptions(source: Source.serverAndCache),
      );

      if (workTimes.docs.isNotEmpty) {
        for (var i in workTimes.docs) {
          var dList = i.data();
          dList["uid"] = i.id;
          data.add(WorktimeModel.fromMap(i.id, dList));
        }
      }

      return data;
    } catch (e) {
      throw e.toString();
    }
  }

  static Future<List<Map<String, dynamic>>> allworktimeListing() async {
    try {
      List<Map<String, dynamic>> data = [];
      var uid = await Spdb.getUid();

      var cid = await Spdb.getCid();
      var workTimes = await firebase.users
          .doc(cid)
          .collection(Collections.worktime.name)
          .where('userUid', isEqualTo: uid)
          .get(const GetOptions(source: Source.serverAndCache));

      if (workTimes.docs.isNotEmpty) {
        for (var i in workTimes.docs) {
          var dList = i.data();
          dList["uid"] = i.id;
          data.add(dList);
        }
      }
      return data;
    } catch (e) {
      throw e.toString();
    }
  }

  static Future<List<WorktimeModel>> worktimeListingReport({
    required FilterModel filter,
  }) async {
    try {
      List<WorktimeModel> data = [];
      var cid = await Spdb.getCid();

      int skipCount = (filter.pageNumber - 1) * filter.pageLimit;

      var workTimesQuery = firebase.users
          .doc(cid)
          .collection(Collections.worktime.name)
          .where(
            'created',
            isGreaterThanOrEqualTo: filter.fromDate.millisecondsSinceEpoch,
          )
          .where(
            'created',
            isLessThanOrEqualTo: filter.toDate.millisecondsSinceEpoch,
          )
          .orderBy('created', descending: true)
          .limit(filter.pageLimit);

      if (skipCount > 0) {
        var previousPageSnapshot = await workTimesQuery.get(
          const GetOptions(source: Source.serverAndCache),
        );
        if (previousPageSnapshot.docs.isNotEmpty) {
          var lastVisible = previousPageSnapshot.docs[skipCount - 1];
          workTimesQuery = workTimesQuery.startAfterDocument(lastVisible);
        }
      }

      var workTimes = await workTimesQuery.get(
        const GetOptions(source: Source.serverAndCache),
      );

      if (workTimes.docs.isNotEmpty) {
        for (var i in workTimes.docs) {
          var dList = i.data();
          dList["uid"] = i.id;
          data.add(WorktimeModel.fromMap(i.id, dList));
        }
      }

      return data;
    } catch (e) {
      throw e.toString();
    }
  }

  static Future<bool> checkTodayClockIn() async {
    var cid = await Spdb.getCid();
    var uid = await Spdb.getUid();

    DateTime now = DateTime.now();

    int start = DateTime(now.year, now.month, now.day).millisecondsSinceEpoch;

    var data = await firebase.users
        .doc(cid)
        .collection(Collections.worktime.name)
        .where("userUid", isEqualTo: uid)
        .where("created", isGreaterThanOrEqualTo: start)
        .get();

    return data.docs.isNotEmpty;
  }
}
