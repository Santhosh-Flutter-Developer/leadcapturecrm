import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '/constants/constants.dart';
import '/services/services.dart';
import '/models/models.dart';
part 'chat_event.dart';
part 'chat_state.dart';

class ChatBloc extends Bloc<ChatEvent, ChatState> {
  FirebaseFirestore firestore = FirebaseFirestore.instance;
  List<ChatModel> allChats = [];

  ChatBloc() : super(ChatLoading()) {
    on<StreamChat>(_streamChat);
    on<SearchChat>(_searchChat);
  }

  Future<void> _streamChat(StreamChat event, Emitter<ChatState> emit) async {
    emit(ChatLoading());
    var cid = await Spdb.getCid();
    var user = await Spdb.getUser();
    final uid = user.uid;
    await emit.forEach(
      firestore
          .collection(Collections.users.name)
          .doc(cid)
          .collection(Collections.chats.name)
          .where("participants", arrayContains: user.uid)
          // .orderBy("lastMessage.timestamp", descending: true)
          .snapshots()
          .map((snapshot) {
            allChats = snapshot.docs
                .map((doc) => ChatModel.fromMap(doc.id, doc.data()))
                .where((chat) {
                  if (chat.isDeletedForUser(uid)) return false;
                  final last = chat.lastMessage;
                  if (last == null) return false;

                  return (last.message.isNotEmpty) ||
                      (last.type != null && last.type!.isNotEmpty);
                })
                .toList();
            // Optional: sort safely
            // allChats.sort(
            //   (a, b) =>
            //       b.lastMessage!.timestamp.compareTo(a.lastMessage!.timestamp),
            // );

            return allChats;
          }),
      onData: (users) => ChatLoaded(users),
      onError: (error, stackTrace) => ChatError("Failed to load chats, $error"),
    );
  }

  void _searchChat(SearchChat event, Emitter<ChatState> emit) {
    // if (event.query.isEmpty) {
    //   emit(ChatLoaded(allChats));
    //   return;
    // }

    // List<ChatModel> filteredChat = allChats.where((ps) {
    //   return ps.chatNumber
    //       .toString()
    //       .toLowerCase()
    //       .contains(event.query.toLowerCase());
    // }).toList();

    // emit(ChatLoaded(filteredChat));
  }
}
