part of 'chat_messages.dart';

class ChatData extends InheritedWidget {
  final String uid;
  final String currentUser;

  const ChatData({
    required this.uid,
    required this.currentUser,
    required super.child,
    super.key,
  });

  static ChatData of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<ChatData>()!;
  }

  @override
  bool updateShouldNotify(covariant InheritedWidget oldWidget) => true;
}
