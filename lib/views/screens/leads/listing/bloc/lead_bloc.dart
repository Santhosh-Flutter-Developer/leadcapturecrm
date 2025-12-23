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
  List<Map<String, dynamic>> _comments = [];
  List<LeadHistoryModel> _history = [];

  LeadBloc() : super(LeadLoading()) {
    on<StreamLead>(_streamLeads);
    on<DeleteLead>(_deleteLead);
    on<StreamLeadComments>(_streamLeadComments);
    on<AddLeadComment>(_addLeadComment);
    on<StreamLeadHistory>(_streamLeadHistory);
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
    try {
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

      await emit.forEach(
        commentsStream,
        onData: (comments) {
          _comments = comments;
          return LeadDetailLoaded(comments: _comments, history: _history);
        },
        onError: (error, stackTrace) {
          debugPrint(stackTrace.toString());
          return LeadDetailError("Failed to load comments");
        },
      );
    } catch (e) {
      emit(LeadDetailError("Failed to load comments: $e"));
    }
  }

  Future<void> _addLeadComment(
    AddLeadComment event,
    Emitter<LeadState> emit,
  ) async {
    try {
      final cid = await Spdb.getCid();
      final user = await Spdb.getUser();

      final comment = {
        'comment': event.commentText,
        'createdBy': {'uid': user.uid, 'name': user.name},
        'createdAt': FieldValue.serverTimestamp(),
      };

      await firestore
          .collection(Collections.users.name)
          .doc(cid)
          .collection(Collections.leads.name)
          .doc(event.leadUid)
          .collection('comments')
          .add(comment);

      // Add history entry
      await LeadService.addLeadHistory(
        leadUid: event.leadUid,
        action: "${user.name} added a comment",
      );
    } catch (e, st) {
      debugPrint(st.toString());
      emit(LeadDetailError("Failed to add comment"));
    }
  }

  Future<void> _streamLeadHistory(
    StreamLeadHistory event,
    Emitter<LeadState> emit,
  ) async {
    try {
      final cid = await Spdb.getCid();
      final historyStream = firestore
          .collection(Collections.users.name)
          .doc(cid)
          .collection(Collections.leads.name)
          .doc(event.leadUid)
          .collection('history')
          .orderBy('timestamp', descending: true)
          .snapshots()
          .map(
            (snapshot) => snapshot.docs
                .map((doc) => LeadHistoryModel.fromMap(doc.data()))
                .toList(),
          );

      await emit.forEach(
        historyStream,
        onData: (history) {
          _history = history;
          return LeadDetailLoaded(comments: _comments, history: _history);
        },
        onError: (error, _) => LeadDetailError(error.toString()),
      );
    } catch (e) {
      emit(LeadDetailError(e.toString()));
    }
  }
}
