part of 'roles_bloc.dart';

abstract class RolesState extends Equatable {
  @override
  List<Object> get props => [];
}

// Initial state
class RolesInitial extends RolesState {}

// Loading state
class RolesLoading extends RolesState {}

// Loaded state with user list
class RolesLoaded extends RolesState {
  final List<RoleModel> roles;
  RolesLoaded(this.roles);

  @override
  List<Object> get props => [roles];
}

// Error state
class RolesError extends RolesState {
  final String message;
  RolesError(this.message);

  @override
  List<Object> get props => [message];
}
