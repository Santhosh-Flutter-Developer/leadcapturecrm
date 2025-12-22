import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '/services/services.dart';
import '/constants/constants.dart';
import '/models/models.dart';
part 'notifications_event.dart';
part 'notifications_state.dart';

class NotificationsBloc extends Bloc<NotificationsEvent, NotificationsState> {
  FirebaseFirestore firestore = FirebaseFirestore.instance;
  List<NotificationModel> allNotifications = [];

  NotificationsBloc() : super(NotificationsLoading()) {
    on<StreamNotifications>(_streamNotifications);
    on<DeleteNotifications>(_deleteNotifications);
  }

  Future<void> _streamNotifications(
    StreamNotifications event,
    Emitter<NotificationsState> emit,
  ) async {
    emit(NotificationsLoading());
    var cid = await Spdb.getCid();
    var uid = await Spdb.getUid();

    await emit.forEach(
      firestore
          .collection(Collections.users.name)
          .doc(cid)
          .collection(Collections.notifications.name)
          .where('toUids', arrayContains: uid)
          .where('senderId', isNotEqualTo: uid)
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map((snapshot) {
            allNotifications = snapshot.docs
                .map((doc) => NotificationModel.fromMap(doc.id, doc.data()))
                .toList();

            return allNotifications;
          }),
      onData: (notifications) => NotificationsLoaded(notifications),
      onError: (error, stackTrace) {
        return NotificationsError("Failed to load notifications, $error");
      },
    );
  }

  Future<void> _deleteNotifications(
    DeleteNotifications event,
    Emitter<NotificationsState> emit,
  ) async {
    try {
      var cid = await Spdb.getCid();

      await firestore
          .collection(Collections.users.name)
          .doc(cid)
          .collection(Collections.notifications.name)
          .doc(event.notificationId) // <-- use document id
          .delete();
    } catch (e, st) {
      await ErrorService.recordError(e, st);
      emit(NotificationsError("Failed to delete notification: $e"));
    }
  }
}
