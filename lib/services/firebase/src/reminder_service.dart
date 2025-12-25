import 'package:cloud_firestore/cloud_firestore.dart';
import '/models/models.dart';
import '/services/services.dart';

class ReminderService {
  static void createReminder({
    required DateTime scheduledAt,
    required NotificationModel notification,
  }) async {
    ReminderModel reminderModel = ReminderModel(
      notification: notification,
      scheduledAt: scheduledAt,
      isSent: false,
      createdAt: DateTime.now(),
      createdBy: await Spdb.getUser(),
    );
    var firestore = FirebaseFirestore.instance;
    await firestore.collection('reminders').add(reminderModel.toMap());
  }
}
