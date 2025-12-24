part of 'client_bloc.dart';

abstract class ClientState extends Equatable {
  @override
  List<Object> get props => [];
}

class ClientInitial extends ClientState {}

class ClientLoading extends ClientState {}

class ClientLoaded extends ClientState {
  final List<ClientModel> clients;
  ClientLoaded(this.clients);

  @override
  List<Object> get props => [clients];
}

class ClientError extends ClientState {
  final String message;
  ClientError(this.message);

  @override
  List<Object> get props => [message];
}

abstract class ClientCompanyState extends Equatable {
  @override
  List<Object> get props => [];
}

class ClientCompanyInitial extends ClientCompanyState {}

class ClientCompanyLoading extends ClientCompanyState {}

class ClientCompanyLoaded extends ClientCompanyState {
  final List<ClientModel> clients;
  ClientCompanyLoaded(this.clients);

  @override
  List<Object> get props => [clients];
}

class ClientCompanyError extends ClientCompanyState {
  final String message;
  ClientCompanyError(this.message);

  @override
  List<Object> get props => [message];
}
