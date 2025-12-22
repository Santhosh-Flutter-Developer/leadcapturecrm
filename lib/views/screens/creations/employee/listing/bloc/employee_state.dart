part of 'employee_bloc.dart';

abstract class EmployeeState extends Equatable {
  @override
  List<Object> get props => [];
}

// Initial state
class EmployeeInitial extends EmployeeState {}

// Loading state
class EmployeeLoading extends EmployeeState {}

// Loaded state with user list
class EmployeeLoaded extends EmployeeState {
  final List<EmployeeModel> employees;
  EmployeeLoaded(this.employees);

  @override
  List<Object> get props => [employees];
}

// Error state
class EmployeeError extends EmployeeState {
  final String message;
  EmployeeError(this.message);

  @override
  List<Object> get props => [message];
}
