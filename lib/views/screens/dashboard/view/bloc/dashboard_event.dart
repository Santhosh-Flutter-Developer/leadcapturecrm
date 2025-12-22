part of 'dashboard_bloc.dart';

abstract class DashboardEvent {}

class LoadDashboardEvent extends DashboardEvent {
  final String filter;
  LoadDashboardEvent({required this.filter});
}

class RefreshDashboardEvent extends DashboardEvent {}
