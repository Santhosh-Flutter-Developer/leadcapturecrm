import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:rxdart/rxdart.dart';
import '/services/services.dart';
import '/constants/constants.dart';
import '/models/models.dart';
part 'lead_event.dart';
part 'lead_state.dart';

class LeadBloc extends Bloc<LeadEvent, LeadState> {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  List<LeadModel> allLeads = [];
  List<LeadStatusModel> allStatus = [];

  LeadBloc() : super(LeadLoading()) {
    on<StreamLead>(_streamLeads);
    on<DeleteLead>(_deleteLead);
    on<StreamLeadComments>(_streamLeadComments);
    on<AddLeadComment>(_addLeadComment);
  }

  Future<void> _streamLeads(StreamLead event, Emitter<LeadState> emit) async {
    emit(LeadLoading());
    final cid = await Spdb.getCid();

    final leadsStream = firestore
        .collection(Collections.users.name)
        .doc(cid)
        .collection(Collections.leads.name)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs.map((doc) {
            return LeadModel.fromMap(doc.id, doc.data());
          }).toList(),
        );

    final statusStream = firestore
        .collection(Collections.users.name)
        .doc(cid)
        .collection(Collections.leadStatus.name)
        .orderBy('orderNumber', descending: false)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => LeadStatusModel.fromMap(doc.id, doc.data()))
              .toList(),
        );

    // Combine both streams
    await emit.forEach(
      Rx.combineLatest2<
        List<LeadModel>,
        List<LeadStatusModel>,
        Map<String, dynamic>
      >(
        leadsStream,
        statusStream,
        (leads, status) => {'leads': leads, 'status': status},
      ),
      onData: (data) {
        allLeads = data['leads'];
        allStatus = data['status'];
        return LeadLoaded(allLeads, allStatus);
      },
      onError: (error, stackTrace) {
        debugPrint(stackTrace.toString());
        return LeadError("Failed to load leads: $error");
      },
    );
  }

  Future<void> _deleteLead(DeleteLead event, Emitter<LeadState> emit) async {
    try {
      final cid = await Spdb.getCid();

      var docRef = await firestore
          .collection(Collections.users.name)
          .doc(cid)
          .collection(Collections.leads.name)
          .doc(event.uid)
          .get();
      final data = docRef.data() as Map<String, dynamic>;
      await TrashService.moveToTrash(
        docRef: docRef.reference,
        docData: data,
        reason: 'user_deleted',
      );
      docRef.reference.delete();

      ActivityLogModel activityLogModel = ActivityLogModel(
        userData: await Spdb.getUser(),
        activity: '${data['leadName'] ?? 'N/A'} has been deleted',
        description: 'User has deleted an entry in ${Collections.admins.name}',
        collection: '${Collections.users.name}/$cid/${Collections.admins.name}',
        docId: docRef.id,
      );
      await CommonService.add(
        '${Collections.users.name}/$cid/${Collections.leads.name}',
        activityLogModel.toMap(),
      );
      add(StreamLead());
    } catch (e, st) {
      await ErrorService.recordError(e, st);
      debugPrint(st.toString());
      emit(LeadError("Failed to delete lead: $e"));
    }
  }

  Future<void> _streamLeadComments(
    StreamLeadComments event,
    Emitter<LeadState> emit,
  ) async {
    emit(CommentsLoading());
    final cid = await Spdb.getCid();

    final commentsStream = firestore
        .collection(Collections.users.name)
        .doc(cid)
        .collection(Collections.leads.name)
        .doc(event.leadUid)
        .collection('comments')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());

    await emit.forEach<List<Map<String, dynamic>>>(
      commentsStream,
      onData: (comments) {
        return CommentsLoaded(comments);
      },
      onError: (error, stackTrace) {
        debugPrint(stackTrace.toString());
        return CommentsError("Failed to load comments: $error");
      },
    );
  }

  Future<void> _addLeadComment(
    AddLeadComment event,
    Emitter<LeadState> emit,
  ) async {
    try {
      final cid = await Spdb.getCid();
      final uid = await Spdb.getUid(); // user UID
      final comment = {
        'comment': event.commentText,
        'createdBy': uid,
        'createdAt': FieldValue.serverTimestamp(),
      };

      await firestore
          .collection(Collections.users.name)
          .doc(cid)
          .collection(Collections.leads.name)
          .doc(event.leadUid)
          .collection('comments')
          .add(comment);

      emit(CommentAdded());
    } catch (e, st) {
      await ErrorService.recordError(e, st);
      debugPrint("Error adding comment: $e\n$st");
      emit(CommentsError("Failed to add comment: $e"));
    }
  }
}
