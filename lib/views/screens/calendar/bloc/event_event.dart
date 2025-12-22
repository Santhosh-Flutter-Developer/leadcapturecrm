part of 'event_bloc.dart';

abstract class EventEvent extends Equatable {
  @override
  List<Object> get props => [];
}

class FetchEvents extends EventEvent {}

class StreamEvent extends EventEvent {}
