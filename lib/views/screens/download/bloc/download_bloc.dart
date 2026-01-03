import 'package:aaatp/models/src/download_model.dart';
import 'package:aaatp/services/database/src/spdb.dart';
import 'package:aaatp/views/screens/download/bloc/download_event.dart';
import 'package:aaatp/views/screens/download/bloc/download_state.dart';
import 'package:bloc/bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DownloadHistoryBloc
    extends Bloc<DownloadHistoryEvent, DownloadHistoryState> {
  FirebaseFirestore firestore = FirebaseFirestore.instance;
  List<DownloadHistoryModel> allDownloads = [];

  DownloadHistoryBloc() : super(DownloadHistoryLoading()) {
    on<StreamDownloadHistory>(_streamDownloadHistory);
    on<AddDownloadHistoryItem>(_addDownloadHistoryItem);
  }

  // STREAM DOWNLOAD HISTORY LIVE
  Future<void> _streamDownloadHistory(
    StreamDownloadHistory event,
    Emitter<DownloadHistoryState> emit,
  ) async {
    emit(DownloadHistoryLoading());
    final cid = await Spdb.getCid();

    await emit.forEach(
      firestore
          .collection('users')
          .doc(cid)
          .collection('downloadHistory')
          .orderBy('downloadedAt', descending: true)
          .snapshots()
          .map((snapshot) {
            allDownloads = snapshot.docs
                .map((doc) => DownloadHistoryModel.fromMap(doc.data()))
                .toList();
            return allDownloads;
          }),
      onData: (items) => DownloadHistoryLoaded(items),
      onError: (error, stackTrace) =>
          DownloadHistoryError('Failed to load download history: $error'),
    );
  }

  // ADD DOWNLOAD HISTORY ITEM
  Future<void> _addDownloadHistoryItem(
    AddDownloadHistoryItem event,
    Emitter<DownloadHistoryState> emit,
  ) async {
    final cid = await Spdb.getCid();
    try {
      await firestore
          .collection('users')
          .doc(cid)
          .collection('downloadHistory')
          .add(event.item.toMap());
    } catch (e) {
      emit(DownloadHistoryError('Failed to add download: $e'));
    }
  }
}
