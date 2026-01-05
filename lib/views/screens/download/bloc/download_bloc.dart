import 'dart:async';

import 'package:aaatp/models/src/download_model.dart';
import 'package:aaatp/views/screens/download/bloc/download_event.dart';
import 'package:aaatp/views/screens/download/bloc/download_state.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class DownloadHistoryBloc
    extends Bloc<DownloadHistoryEvent, DownloadHistoryState> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  DownloadHistoryBloc() : super(DownloadHistoryLoading()) {
    on<StreamDownloadHistory>(_onStream);
  }

  Future<void> _onStream(
    StreamDownloadHistory event,
    Emitter<DownloadHistoryState> emit,
  ) async {
    emit(DownloadHistoryLoading());

    await emit.forEach<QuerySnapshot<Map<String, dynamic>>>(
      _firestore
          .collection('download_history')
          .orderBy('downloadedAt', descending: true)
          .snapshots(),
      onData: (snapshot) {
        final items = snapshot.docs
            .map((e) => DownloadHistoryModel.fromMap(e.data()))
            .toList();

        return DownloadHistoryLoaded(items);
      },
      onError: (error, _) {
        return DownloadHistoryError(error.toString());
      },
    );
  }
}
