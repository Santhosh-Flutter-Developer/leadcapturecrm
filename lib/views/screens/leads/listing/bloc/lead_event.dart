part of 'lead_bloc.dart';

abstract class LeadEvent extends Equatable {
  @override
  List<Object> get props => [];
}

class FetchLeads extends LeadEvent {}

class StreamLead extends LeadEvent {}

class UpdateLeadStatus extends LeadEvent {
  final LeadModel lead;
  final String newStatusUid;
  UpdateLeadStatus({required this.lead, required this.newStatusUid});
}

class DeleteLead extends LeadEvent {
  final String uid;
  DeleteLead(this.uid);

  @override
  List<Object> get props => [uid];
}

class StreamLeadComments extends LeadEvent {
  final String leadUid;
  StreamLeadComments(this.leadUid);
}

class AddLeadComment extends LeadEvent {
  final String leadUid;
  final String commentText;
  AddLeadComment({required this.leadUid, required this.commentText});
}

class StreamLeadHistory extends LeadEvent {
  final String leadUid;
  StreamLeadHistory(this.leadUid);
}
