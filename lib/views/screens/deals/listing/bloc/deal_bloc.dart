import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rxdart/rxdart.dart';
import '/services/services.dart';
import '/constants/constants.dart';
import '/models/models.dart';
part 'deal_event.dart';
part 'deal_state.dart';

class DealBloc extends Bloc<DealEvent, DealState> {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  List<DealModel> allDeals = [];
  List<DealStatusModel> allStatus = [];

  DealBloc() : super(DealLoading()) {
    on<StreamDeals>(_streamDeals);
    on<DeleteDeal>(_deleteDeal);
    on<StreamDealComments>(_streamDealComments);
    on<AddDealComment>(_addDealComment);
  }

  Future<void> _streamDeals(StreamDeals event, Emitter<DealState> emit) async {
    emit(DealLoading());
    final cid = await Spdb.getCid();

    final dealsStream = firestore
        .collection(Collections.users.name)
        .doc(cid)
        .collection(Collections.deals.name)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => DealModel.fromMap(doc.id, doc.data()))
              .toList(),
        );

    final statusStream = firestore
        .collection(Collections.users.name)
        .doc(cid)
        .collection(Collections.dealStatus.name)
        .orderBy('orderNumber', descending: false)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => DealStatusModel.fromMap(doc.id, doc.data()))
              .toList(),
        );

    await emit.forEach(
      Rx.combineLatest2<
        List<DealModel>,
        List<DealStatusModel>,
        Map<String, dynamic>
      >(
        dealsStream,
        statusStream,
        (deals, status) => {'deals': deals, 'status': status},
      ),
      onData: (data) {
        allDeals = data['deals'];
        allStatus = data['status'];
        return DealLoaded(allDeals, allStatus);
      },
      onError: (error, stackTrace) {
        debugPrint(stackTrace.toString());
        return DealError("Failed to load deals: $error");
      },
    );
  }

  Future<void> _deleteDeal(DeleteDeal event, Emitter<DealState> emit) async {
    try {
      final cid = await Spdb.getCid();

      var docRef = await firestore
          .collection(Collections.users.name)
          .doc(cid)
          .collection(Collections.deals.name)
          .doc(event.dealUid)
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
        activity: '${data['dealName'] ?? 'N/A'} has been deleted',
        description: 'User has deleted an entry in ${Collections.deals.name}',
        collection: '${Collections.users.name}/$cid/${Collections.deals.name}',
        docId: docRef.id,
      );
      await CommonService.add(
        '${Collections.users.name}/$cid/${Collections.activityLogs.name}',
        activityLogModel.toMap(),
      );
    } catch (e, st) {
      await ErrorService.recordError(e, st);
      debugPrint('Error deleting deal: $e\n$st');
      emit(DealError("Failed to delete deal: $e"));
    }
  }

  Future<void> _streamDealComments(
    StreamDealComments event,
    Emitter<DealState> emit,
  ) async {
    emit(DealCommentsLoading());
    final cid = await Spdb.getCid();
    final commentsStream = firestore
        .collection(Collections.users.name)
        .doc(cid)
        .collection(Collections.deals.name)
        .doc(event.dealUid)
        .collection('comments')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());

    await emit.forEach<List<Map<String, dynamic>>>(
      commentsStream,
      onData: (comments) {
        return DealCommentsLoaded(comments);
      },
      onError: (error, stackTrace) {
        return DealCommentsError("Failed to load comments: $error");
      },
    );
  }

  Future<void> _addDealComment(
    AddDealComment event,
    Emitter<DealState> emit,
  ) async {
    try {
      final cid = await Spdb.getCid();
      final uid = await Spdb.getUid();
      final comment = {
        'comment': event.commentText,
        'createdBy': uid,
        'createdAt': FieldValue.serverTimestamp(),
      };

      await firestore
          .collection(Collections.users.name)
          .doc(cid)
          .collection(Collections.deals.name)
          .doc(event.dealUid)
          .collection('comments')
          .add(comment);

      emit(DealCommentAdded());
    } catch (e, st) {
      await ErrorService.recordError(e, st);
      debugPrint("Error adding comment: $e\n$st");
      emit(DealCommentsError("Failed to add comment: $e"));
    }
  }
}
