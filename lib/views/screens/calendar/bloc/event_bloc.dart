import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '/services/services.dart';
import '/constants/constants.dart';
import '/models/models.dart';
part 'event_event.dart';
part 'event_state.dart';

class EventBloc extends Bloc<EventEvent, EventState> {
  FirebaseFirestore firestore = FirebaseFirestore.instance;
  List<EventModel> allEvent = [];

  EventBloc() : super(EventLoading()) {
    on<StreamEvent>(_streamEvent);
  }

  Future<void> _streamEvent(StreamEvent event, Emitter<EventState> emit) async {
    emit(EventLoading());
    var cid = await Spdb.getCid();

    await emit.forEach(
      firestore
          .collection(Collections.users.name)
          .doc(cid)
          .collection(Collections.events.name)
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map((snapshot) {
            allEvent = snapshot.docs
                .map((doc) => EventModel.fromMap(doc.id, doc.data()))
                .toList();

            return allEvent;
          }),
      onData: (event) => EventLoaded(event),
      onError: (error, stackTrace) {
        return EventError("Failed to load event, $error");
      },
    );
  }
}
