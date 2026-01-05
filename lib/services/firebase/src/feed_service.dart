import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '/constants/constants.dart';
import '/services/services.dart';
import '/models/models.dart';

class FeedService {
  static final FirebaseConfig firebase = FirebaseConfig();
  static final FirebaseFirestore firestore = FirebaseFirestore.instance;

  static Future<void> createFeed({required FeedModel feed}) async {
    try {
      final cid = await Spdb.getCid();
      final uid = await Spdb.getUid();

      if (cid == null || uid == null) {
        throw "Missing cid or uid";
      }

      final userDoc = firebase.users.doc(cid);
      final feedRef = userDoc.collection(Collections.feed.name);

      var lastFeed = await feedRef.orderBy('feedNumber').limit(1).get();
      var newFeedNumber = 0;
      if (lastFeed.docs.isNotEmpty) {
        var lastFeedNumber = lastFeed.docs.first.data()['feedNumber'];
        if (lastFeedNumber != null) {
          newFeedNumber = lastFeedNumber + 1;
        }
      } else {
        newFeedNumber = 1;
      }

      var map = feed.toMap();
      map['feedNumber'] = newFeedNumber;

      await feedRef.add(map);

      // List<String> workflows = feed.workflow;
      // List<String> fcmIds = [];
      // List<String> toUids = [];
      // for (var i in workflows) {
      //   var userFcmIds = await AuthService.getUserFcmIds(uid: i);
      //   if (userFcmIds.isNotEmpty) {
      //     fcmIds.addAll(userFcmIds);
      //     toUids.add(i);
      //   }
      // }

      // var user = await Spdb.getUser();
      // PostNotificationService.sendNotification(
      //   model: NotificationModel(
      //     title: 'New Feed : ${feed.feedName}',
      //     message: 'New feed has created by ${user?.name}',
      //     toFcms: fcmIds,
      //     toUids: workflows,
      //     payload: {},
      //   ),
      // );
    } catch (e, st) {
      await ErrorService.recordError(e, st);
      debugPrint("Error creating feed: $e\n$st");
      rethrow;
    }
  }

  static Future<FeedModel> getFeed({required String uid}) async {
    try {
      var cid = await Spdb.getCid();
      var feedDoc = await firebase.users
          .doc(cid)
          .collection(Collections.feed.name)
          .doc(uid)
          .get();

      if (feedDoc.exists) {
        var feedData = feedDoc.data();
        if (feedData != null) {
          var feed = FeedModel.fromMap(feedDoc.id, feedData);
          return feed;
        } else {
          throw 'Feed data is empty';
        }
      } else {
        throw 'Feed not found';
      }
    } catch (e, st) {
      await ErrorService.recordError(e, st);
      debugPrint("${e.toString()}, ${st.toString()}");
      throw 'Error creating feed: $e';
    }
  }

  static Future<List<FeedModel>> getAllFeeds() async {
    try {
      var cid = await Spdb.getCid();
      var querySnapshot = await firebase.users
          .doc(cid)
          .collection(Collections.feed.name)
          .orderBy('createdAt', descending: true)
          .get();

      List<FeedModel> feed = querySnapshot.docs.map((doc) {
        return FeedModel.fromMap(doc.id, doc.data());
      }).toList();

      return feed;
    } catch (e, st) {
      await ErrorService.recordError(e, st);
      debugPrint("${e.toString()}, ${st.toString()}");
      throw 'Error fetching feed: $e';
    }
  }

  static Future<void> updateCommentReaction({
    required String feedId,
    required String commentId,
    required Map<String, List<String>> reactions,
  }) async {
    try {
      final cid = await Spdb.getCid();

      final docRef = firestore
          .collection(Collections.users.name)
          .doc(cid)
          .collection(Collections.feed.name)
          .doc(feedId);

      final snapshot = await docRef.get();
      if (!snapshot.exists) throw "Feed post does not exist!";

      final data = snapshot.data() as Map<String, dynamic>;
      List<dynamic> comments = data['comments'] ?? [];

      // Update the reactions of the specific comment
      comments = comments.map((c) {
        if (c['commentId'] == commentId) {
          final updatedComment = Map<String, dynamic>.from(c);
          updatedComment['reactions'] = reactions;
          return updatedComment;
        }
        return c;
      }).toList();

      await docRef.update({'comments': comments});
    } catch (e) {
      debugPrint("Error updating comment reaction: $e");
      throw "Error updating comment reaction: $e";
    }
  }

  static Future<void> toggleReaction({
    required String feedId,
    required String userId,
    required String type,
  }) async {
    var cid = await Spdb.getCid();

    final docRef = firestore
        .collection(Collections.users.name)
        .doc(cid)
        .collection(Collections.feed.name)
        .doc(feedId);

    final snapshot = await docRef.get();

    if (!snapshot.exists) {
      throw "Feed post does not exist!";
    }

    final data = snapshot.data() as Map<String, dynamic>;

    // Get existing reactions
    List<dynamic> rawReactions = data['reactions'] ?? [];
    List<Map<String, dynamic>> reactions = List<Map<String, dynamic>>.from(
      rawReactions,
    );

    // Check if user already reacted
    final index = reactions.indexWhere((r) => r['userId'] == userId);

    if (index != -1) {
      // Remove reaction (toggle off)
      reactions.removeAt(index);
    } else {
      // Add reaction (toggle on)
      reactions.add({
        'userId': userId,
        'type': type,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });
    }

    // Update Firestore
    await docRef.update({'reactions': reactions});
  }

  static Future<void> addComment({
    required String feedId,
    required CommentModel comment,
  }) async {
    try {
      var cid = await Spdb.getCid();

      final docRef = firestore
          .collection(Collections.users.name)
          .doc(cid)
          .collection(Collections.feed.name)
          .doc(feedId);
      await docRef.update({
        'comments': FieldValue.arrayUnion([comment.toMap()]),
        'commentsCount': FieldValue.increment(1),
      });
    } catch (e) {
      throw 'Error adding comment: $e';
    }
  }

  static Future<void> editFeed({
    required String uid,
    required FeedModel feed,
  }) async {
    try {
      var cid = await Spdb.getCid();

      await CommonService.update(
        '${Collections.users.name}/$cid/${Collections.feed.name}',
        uid,
        feed.toUpdateMap(),
        activity: '${feed.content} has been updated',
      );

      // List<String> workflows = feed.workflow;
      // List<String> fcmIds = [];
      // List<String> toUids = [];
      // for (var i in workflows) {
      //   var userFcmIds = await AuthService.getUserFcmIds(uid: i);
      //   if (userFcmIds.isNotEmpty) {
      //     fcmIds.addAll(userFcmIds);
      //     toUids.add(i);
      //   }
      // }

      // var user = await Spdb.getUser();
      // PostNotificationService.sendNotification(
      //   model: NotificationModel(
      //     title: 'Feed Modified : ${feed.feedName}',
      //     message: 'Feed has modified created by ${user?.name}',
      //     toFcms: fcmIds,
      //     toUids: workflows,
      //     payload: {},
      //   ),
      // );
    } catch (e, st) {
      await ErrorService.recordError(e, st);
      debugPrint("${e.toString()}, ${st.toString()}");
      throw 'Error updating feed: $e';
    }
  }

  static Future<void> votePoll({
    required String feedId,
    required String optionId,
  }) async {
    try {
      String cid = await Spdb.getCid() ?? '';

      final docRef = firestore
          .collection(Collections.users.name)
          .doc(cid)
          .collection(Collections.feed.name)
          .doc(feedId);

      final snap = await docRef.get();
      if (!snap.exists) return;

      final data = snap.data()!;
      FeedModel feed = FeedModel.fromMap(snap.id, data);

      if (feed.poll == null) return;

      // Increase vote
      for (var option in feed.poll!.options) {
        if (option.optionId == optionId) {
          option.votes += 1;
          break;
        }
      }

      // Upload back
      await docRef.update({"poll": feed.poll!.toMap()});
    } catch (e, st) {
      await ErrorService.recordError(e, st);
      debugPrint("${e.toString()}, ${st.toString()}");
      throw 'Error updating feed: $e';
    }
  }
}
