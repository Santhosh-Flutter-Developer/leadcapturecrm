part of 'client_bloc.dart';

abstract class ClientEvent extends Equatable {
  @override
  List<Object> get props => [];
}

class StreamClients extends ClientEvent {}

class FetchClients extends ClientEvent {}

class DeleteClients extends ClientEvent {
  final String uid;

  DeleteClients({required this.uid});
}
