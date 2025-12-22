part of 'deal_bloc.dart';

abstract class DealState extends Equatable {
  @override
  List<Object> get props => [];
}

// Initial state
class DealInitial extends DealState {}

// Loading state
class DealLoading extends DealState {}

// Loaded state with deals and statuses
class DealLoaded extends DealState {
  final List<DealModel> deals;
  final List<DealStatusModel> allStatuses;

  DealLoaded(this.deals, this.allStatuses);

  @override
  List<Object> get props => [deals, allStatuses];
}

class DealCommentsLoading extends DealState {}

class DealCommentsLoaded extends DealState {
  final List<Map<String, dynamic>> comments;
  DealCommentsLoaded(this.comments);
}

class DealCommentsError extends DealState {
  final String message;
  DealCommentsError(this.message);
}

class DealCommentAdded extends DealState {}

class DealError extends DealState {
  final String message;

  DealError(this.message);

  @override
  List<Object> get props => [message];
}
