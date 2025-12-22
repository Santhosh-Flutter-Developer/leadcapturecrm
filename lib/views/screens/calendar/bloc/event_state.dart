part of 'event_bloc.dart';

abstract class EventState extends Equatable {
  @override
  List<Object> get props => [];
}

// Initial state
class EventInitial extends EventState {}

// Loading state
class EventLoading extends EventState {}

// Loaded state with user list
class EventLoaded extends EventState {
  final List<EventModel> events;
  EventLoaded(this.events);

  @override
  List<Object> get props => [events];
}

// Error state
class EventError extends EventState {
  final String message;
  EventError(this.message);

  @override
  List<Object> get props => [message];
}
