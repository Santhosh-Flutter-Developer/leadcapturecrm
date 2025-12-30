import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:rxdart/rxdart.dart';
import '/services/services.dart';
import '/constants/constants.dart';
import '/models/models.dart';
part 'calendar_event.dart';
part 'calendar_state.dart';

class CalendarBloc extends Bloc<CalendarCalendar, CalendarState> {
  FirebaseFirestore firestore = FirebaseFirestore.instance;
  List<EventModel> allEvents = [];
  List<TaskModel> allTasks = [];

  CalendarBloc() : super(CalendarLoading()) {
    on<StreamCalendar>(_streamCalendar);
  }

  Future<void> _streamCalendar(
    StreamCalendar event,
    Emitter<CalendarState> emit,
  ) async {
    emit(CalendarLoading());

    final cid = await Spdb.getCid();

    final eventsStream = firestore
        .collection(Collections.users.name)
        .doc(cid)
        .collection(Collections.events.name)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((d) => EventModel.fromMap(d.id, d.data()))
              .toList(),
        );

    final tasksStream = firestore
        .collection(Collections.users.name)
        .doc(cid)
        .collection(Collections.tasks.name)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((d) => TaskModel.fromMap(d.id, d.data()))
              .toList(),
        );

    await emit.forEach(
      Rx.combineLatest2<
        List<EventModel>,
        List<TaskModel>,
        Map<String, dynamic>
      >(
        eventsStream,
        tasksStream,
        (events, tasks) => {'events': events, 'tasks': tasks},
      ),
      onData: (data) {
        return CalendarLoaded(
          data['events'] as List<EventModel>,
          data['tasks'] as List<TaskModel>,
        );
      },
      onError: (error, stackTrace) {
        return CalendarError("Failed to load calendar: $error");
      },
    );
  }
}
