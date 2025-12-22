part of 'lead_bloc.dart';

abstract class LeadState extends Equatable {
  @override
  List<Object> get props => [];
}

// Initial state
class LeadInitial extends LeadState {}

// Loading state
class LeadLoading extends LeadState {}

// Loaded state with user list
class LeadLoaded extends LeadState {
  final List<LeadModel> leads;
  final List<LeadStatusModel> allStatuses;

  LeadLoaded(this.leads, this.allStatuses);

  @override
  List<Object> get props => [leads, allStatuses];
}

class LeadError extends LeadState {
  final String message;
  LeadError(this.message);

  @override
  List<Object> get props => [message];
}

class CommentsLoading extends LeadState {}
class CommentsLoaded extends LeadState {
  final List<Map<String, dynamic>> comments;
   CommentsLoaded(this.comments);
}
class CommentAdded extends LeadState {}
class CommentsError extends LeadState {
  final String message;
   CommentsError(this.message);
}

