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

abstract class ClientCompanyEvent extends Equatable {
  @override
  List<Object> get props => [];
}

class StreamClientCompany extends ClientCompanyEvent {}

class FetchClientCompany extends ClientCompanyEvent {}

class DeleteClientCompany extends ClientCompanyEvent {
  final String uid;

  DeleteClientCompany({required this.uid});
}
