import 'package:aaatp/models/src/download_model.dart';

abstract class DownloadHistoryEvent {}

class StreamDownloadHistory extends DownloadHistoryEvent {}

class AddDownloadHistoryItem extends DownloadHistoryEvent {
  final DownloadHistoryModel item;
  AddDownloadHistoryItem(this.item);
}
