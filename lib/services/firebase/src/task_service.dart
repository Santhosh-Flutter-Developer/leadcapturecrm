import 'package:flutter/material.dart';
import '/constants/constants.dart';
import '/services/services.dart';
import '/models/models.dart';

class TaskService {
  static final FirebaseConfig firebase = FirebaseConfig();

  static Future<void> createTask({required TaskModel task}) async {
    try {
      var cid = await Spdb.getCid();
      var uid = await Spdb.getUid();

      if (!task.createdBy.contains(uid)) {
        task.createdBy.add(uid!);
      }

      final userDoc = firebase.users.doc(cid);
      final tasksRef = userDoc.collection(Collections.tasks.name);

      // Generate task number if not provided
      int taskNumber = task.taskNumber ?? 1;
      var lastTaskSnapshot = await tasksRef
          .orderBy('taskNumber', descending: true)
          .limit(1)
          .get();
      if (lastTaskSnapshot.docs.isNotEmpty) {
        taskNumber =
            (lastTaskSnapshot.docs.first.data()['taskNumber'] ?? 0) + 1;
      }

      var taskData = task.toMap();
      taskData['taskNumber'] = taskNumber;

      var taskDoc = await tasksRef.add(taskData);

      // Task History
      TaskHistoryModel taskHistoryModel = TaskHistoryModel(
        userId: uid ?? '',
        updateDisposition: 'Task Created',
      );

      await taskDoc
          .collection(Collections.taskHistory.name)
          .add(taskHistoryModel.toMap());

      // Collect Users
      List<String> users = [
        ...task.assignees,
        ...task.participants,
        ...task.createdBy,
        ...task.observers,
      ];

      users = users.toSet().toList();

      List<String> fcmIds = [];
      List<String> toUids = [];

      for (var i in users) {
        var userFcmIds = await AuthService.getUserFcmIds(uid: i);
        if (userFcmIds.isNotEmpty) {
          fcmIds.addAll(userFcmIds);
          toUids.add(i);
        }
      }

      var user = await Spdb.getUser();

      var notif = NotificationModel(
        collectionId: await Spdb.getCid() ?? '',
        title: 'Task : ${task.taskName}',
        message: 'New task created by ${user.name}',
        toFcms: fcmIds,
        toUids: users,
        senderId: await Spdb.getUid(),
        type: 'Task',
        payload: {},
      );

      PostNotificationService.sendNotification(model: notif);

      if (task.deadlineRequired && task.deadline != null) {
        ReminderService.createReminder(
          scheduledAt: task.deadline!,
          notification: NotificationModel(
            title: 'Task Deadline Reminder',
            message: 'Task "${task.taskName}" is due soon',
            collectionId: cid ?? '',
            toFcms: fcmIds,
            toUids: users,
            type: 'task_deadline_reminder',
            payload: {'taskId': taskDoc.id},
          ),
        );
      }
    } catch (e, st) {
      await ErrorService.recordError(e, st);
      throw 'Error creating task: $e';
    }
  }

  static Future<void> updateTask({
    required String uid,
    required TaskModel task,
  }) async {
    try {
      var cid = await Spdb.getCid();
      var userId = await Spdb.getUid();

      await CommonService.update(
        '${Collections.users.name}/$cid/${Collections.tasks.name}',
        uid,
        task.toUpdateMap(),
        activity: '${task.taskName} has been updated',
      );

      TaskHistoryModel taskHistoryModel = TaskHistoryModel(
        userId: userId ?? '',
        updateDisposition: 'Task Updated',
      );

      await firebase.users
          .doc(cid)
          .collection(Collections.tasks.name)
          .doc(uid)
          .collection(Collections.taskHistory.name)
          .add(taskHistoryModel.toMap());

      List<String> users = [
        ...task.assignees,
        ...task.participants,
        ...task.createdBy,
        ...task.observers,
      ];

      users = users.toSet().toList();

      List<String> fcmIds = [];
      List<String> toUids = [];

      for (var i in users) {
        var userFcmIds = await AuthService.getUserFcmIds(uid: i);

        if (userFcmIds.isNotEmpty) {
          fcmIds.addAll(userFcmIds);
          toUids.add(i);
        }
      }

      var user = await Spdb.getUser();

      var notif = NotificationModel(
        collectionId: await Spdb.getCid() ?? '',
        title: 'Task : ${task.taskName}',
        message: 'Task has updated by ${user.name}',
        toFcms: fcmIds,
        toUids: users,
        senderId: await Spdb.getUid(),
        type: 'Task',
        payload: {},
      );

      PostNotificationService.sendNotification(model: notif);
      if (task.deadlineRequired && task.deadline != null) {
        ReminderService.createReminder(
          scheduledAt: task.deadline!,
          notification: NotificationModel(
            title: 'Task Deadline Reminder',
            message: 'Task "${task.taskName}" is due soon',
            collectionId: cid ?? '',
            toFcms: fcmIds,
            toUids: users,
            type: 'task_deadline_reminder',
            payload: {'taskId': uid},
          ),
        );
      }
    } catch (e, st) {
      debugPrint("Error updating task: $e\n$st");
      await ErrorService.recordError(e, st);
      throw 'Error updating task: $e';
    }
  }

  // Delete task
  static Future<void> deleteTask({required String uid}) async {
    try {
      var cid = await Spdb.getCid();
      var docRef = await firebase.users
          .doc(cid)
          .collection(Collections.tasks.name)
          .doc(uid)
          .get();
      final data = docRef.data() as Map<String, dynamic>;
      await TrashService.moveToTrash(
        docRef: docRef.reference,
        docData: data,
        reason: 'user_deleted',
      );
      docRef.reference.delete();
      var user = await Spdb.getUser();
      ActivityLogModel activityLogModel = ActivityLogModel(
        userData: user,
        activity: '${data['taskName'] ?? 'N/A'} has been deleted',
        description: 'User has deleted an entry in ${Collections.tasks.name}',
        collection: '${Collections.users.name}/$cid/${Collections.tasks.name}',
        docId: docRef.id,
      );
      await CommonService.add(
        '${Collections.users.name}/$cid/${Collections.activityLogs.name}',
        activityLogModel.toMap(),
      );
    } catch (e, st) {
      await ErrorService.recordError(e, st);
      throw 'Error deleting task: $e';
    }
  }

  // Get a single task
  static Future<TaskModel> getTask({required String uid}) async {
    try {
      var cid = await Spdb.getCid();
      var doc = await firebase.users
          .doc(cid)
          .collection(Collections.tasks.name)
          .doc(uid)
          .get();

      if (!doc.exists) throw 'Task not found';
      return TaskModel.fromMap(doc.id, doc.data()!);
    } catch (e, st) {
      await ErrorService.recordError(e, st);
      throw 'Error fetching task: $e';
    }
  }

  // Get all tasks
  static Future<List<TaskModel>> getAllTasks() async {
    try {
      var cid = await Spdb.getCid();
      var snapshot = await firebase.users
          .doc(cid)
          .collection(Collections.tasks.name)
          .get();

      return snapshot.docs
          .map((doc) => TaskModel.fromMap(doc.id, doc.data()))
          .toList();
    } catch (e, st) {
      await ErrorService.recordError(e, st);
      throw 'Error fetching tasks: $e';
    }
  }

  static Future<void> startTask({required String taskId}) async {
    try {
      var cid = await Spdb.getCid();
      var uid = await Spdb.getUid();

      await CommonService.update(
        '${Collections.users.name}/$cid/${Collections.tasks.name}',
        taskId,
        {
          "hasStarted": true,
          "completed": false,
          "startedTime": DateTime.now().millisecondsSinceEpoch,
        },
        activity: 'Task has been updated',
      );
      // Add history
      TaskHistoryModel history = TaskHistoryModel(
        userId: uid ?? '',
        updateDisposition: 'Task Started',
      );

      await CommonService.add(
        '${Collections.users.name}/$cid/${Collections.subDepartments.name}/$taskId/${Collections.taskHistory.name}',
        history.toMap(),
      );
    } catch (e, st) {
      await ErrorService.recordError(e, st);
      throw "Error starting task: $e";
    }
  }

  static Future<void> completeTask({required String taskId}) async {
    try {
      var cid = await Spdb.getCid();
      var uid = await Spdb.getUid();

      await CommonService.update(
        '${Collections.users.name}/$cid/${Collections.tasks.name}',
        taskId,
        {
          "completed": true,
          "hasStarted": false,
          "completedTime": DateTime.now().millisecondsSinceEpoch,
        },
        activity: 'Task has been updated',
      );
      // Add history
      TaskHistoryModel history = TaskHistoryModel(
        userId: uid ?? '',
        updateDisposition: 'Task Completed',
      );

      await firebase.users
          .doc(cid)
          .collection(Collections.tasks.name)
          .doc(taskId)
          .collection(Collections.taskHistory.name)
          .add(history.toMap());
    } catch (e, st) {
      await ErrorService.recordError(e, st);
      throw "Error completing task: $e";
    }
  }

  static Stream<List<TaskHistoryModel>> streamTaskHistory({
    required String cid,
    required String taskId,
  }) {
    return firebase.users
        .doc(cid)
        .collection(Collections.tasks.name)
        .doc(taskId)
        .collection(Collections.taskHistory.name)
        .orderBy("timestamp", descending: true)
        .snapshots()
        .map(
          (snap) =>
              snap.docs.map((d) => TaskHistoryModel.fromMap(d.data())).toList(),
        )
        .asBroadcastStream(); // allows multiple listeners
  }

  static Stream<List<TaskCommentModel>> streamComments({
    required String cid,
    required String taskId,
  }) {
    return firebase.users
        .doc(cid)
        .collection(Collections.tasks.name)
        .doc(taskId)
        .collection(Collections.taskComments.name)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map(
          (snap) =>
              snap.docs.map((d) => TaskCommentModel.fromMap(d.data())).toList(),
        )
        .asBroadcastStream(); // allows multiple listeners
  }

  static Future<List<TaskHistoryModel>> getTaskHistory({
    required String taskId,
  }) async {
    try {
      var cid = await Spdb.getCid();

      var snapshot = await firebase.users
          .doc(cid)
          .collection(Collections.tasks.name)
          .doc(taskId)
          .collection(Collections.taskHistory.name)
          .orderBy('timestamp', descending: true)
          .get();

      return snapshot.docs
          .map((d) => TaskHistoryModel.fromMap(d.data()))
          .toList();
    } catch (e, st) {
      await ErrorService.recordError(e, st);
      throw 'Error getting task history: $e';
    }
  }

  static Future<List<TaskCommentModel>> getComments({
    required String taskId,
  }) async {
    try {
      var cid = await Spdb.getCid();

      var snapshot = await firebase.users
          .doc(cid)
          .collection(Collections.tasks.name)
          .doc(taskId)
          .collection(Collections.taskComments.name)
          .orderBy('timestamp', descending: true)
          .get();

      return snapshot.docs
          .map((d) => TaskCommentModel.fromMap(d.data()))
          .toList();
    } catch (e, st) {
      await ErrorService.recordError(e, st);
      throw 'Error getting comments: $e';
    }
  }

  static Future<void> addComment({
    required String taskId,
    required String comment,
  }) async {
    try {
      var cid = await Spdb.getCid();
      var uid = await Spdb.getUid();

      TaskCommentModel commentModel = TaskCommentModel(
        userId: uid ?? '',
        comment: comment,
        timestamp: DateTime.now(),
      );

      await firebase.users
          .doc(cid)
          .collection(Collections.tasks.name)
          .doc(taskId)
          .collection(Collections.taskComments.name)
          .add(commentModel.toMap());
    } catch (e, st) {
      await ErrorService.recordError(e, st);
      throw 'Error adding comment: $e';
    }
  }

  static Future<int> getUserTaskCount({required String userId}) async {
    try {
      var cid = await Spdb.getCid();

      var snapshot = await firebase.users
          .doc(cid)
          .collection(Collections.tasks.name)
          .where('createdBy', arrayContains: userId)
          .get();

      return snapshot.docs.length;
    } catch (e, st) {
      await ErrorService.recordError(e, st);
      throw 'Error getting user task count: $e';
    }
  }
}
