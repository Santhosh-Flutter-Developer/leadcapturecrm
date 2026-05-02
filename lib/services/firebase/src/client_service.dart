import 'package:flutter/material.dart';
import '/constants/constants.dart';
import '/models/models.dart';
import '/services/services.dart';

class ClientService {
  static final FirebaseConfig firebase = FirebaseConfig();

  static Future<String?> createClient({required ClientModel client}) async {
    try {
      var cid = await Spdb.getCid();
      var docRef = await CommonService.add(
        '${Collections.users.name}/$cid/${Collections.clients.name}',
        client.toMap(),
        activity: '${client.companyName} has been added as a client',
      );

      return docRef.id;
    } catch (e, st) {
      debugPrint("${e.toString()}, ${st.toString()}");
      await ErrorService.recordError(e, st);
      throw 'Error creating client: $e';
    }
  }

  static Future<void> editClient({
    required String uid,
    required ClientModel client,
  }) async {
    try {
      var cid = await Spdb.getCid();

      await CommonService.update(
        '${Collections.users.name}/$cid/${Collections.clients.name}',
        uid,
        client.toUpdateMap(),
        activity: '${client.companyName} has been updated',
      );
    } catch (e, st) {
      debugPrint("${e.toString()}, ${st.toString()}");
      await ErrorService.recordError(e, st);
      throw 'Error updating client: $e';
    }
  }

  static Future<ClientModel> getClient({required String uid}) async {
    try {
      final cid = await Spdb.getCid();

      if (cid == null || cid.isEmpty) {
        throw 'Invalid company id';
      }

      if (uid.isEmpty) {
        throw 'Invalid client id';
      }

      final docRef = firebase.users
          .doc(cid)
          .collection(Collections.clients.name)
          .doc(uid);

      final clientDoc = await docRef.get();

      if (!clientDoc.exists) {
        throw 'Client not found';
      }

      final data = clientDoc.data();
      if (data == null) {
        throw 'Client data is empty';
      }

      return ClientModel.fromMap(clientDoc.id, data);
    } catch (e, st) {
      await ErrorService.recordError(e, st);
      debugPrint("getClient error: $e\n$st");
      throw 'Error loading client: $e';
    }
  }

  static Future<void> deleteClientProfileImage({required String uid}) async {
    try {
      var cid = await Spdb.getCid();
      var client = await firebase.users
          .doc(cid)
          .collection(Collections.clients.name)
          .doc(uid)
          .get();
      var profilePictureUrl = client.data()?['profilePictureUrl'];
      if (profilePictureUrl != null) {
        await StorageService.deleteImage(profilePictureUrl);
      }

      await CommonService.update(
        '${Collections.users.name}/$cid/${Collections.clients.name}',
        uid,
        {'profilePictureUrl': null},
      );
    } catch (e, st) {
      debugPrint("${e.toString()}, ${st.toString()}");
      await ErrorService.recordError(e, st);
      throw 'Error deleting client: $e';
    }
  }

  static Future<void> deleteClientCompanyLogo({required String uid}) async {
    try {
      var cid = await Spdb.getCid();
      var client = await firebase.users
          .doc(cid)
          .collection(Collections.clients.name)
          .doc(uid)
          .get();
      var companyLogoUrl = client.data()?['companyLogoUrl'];
      if (companyLogoUrl != null) {
        await StorageService.deleteImage(companyLogoUrl);
      }

      await CommonService.update(
        '${Collections.users.name}/$cid/${Collections.clients.name}',
        uid,
        {'companyLogoUrl': null},
      );
    } catch (e, st) {
      debugPrint("${e.toString()}, ${st.toString()}");
      await ErrorService.recordError(e, st);
      throw 'Error deleting client: $e';
    }
  }

  static Future<List<ClientModel>> getAllClients() async {
    try {
      var cid = await Spdb.getCid();
      var querySnapshot = await firebase.users
          .doc(cid)
          .collection(Collections.clients.name)
          .get();

      List<ClientModel> clients = querySnapshot.docs.map((doc) {
        return ClientModel.fromMap(doc.id, doc.data());
      }).toList();

      clients.sort((a, b) => a.clientName!.compareTo(b.clientName!));

      return clients;
    } catch (e, st) {
      await ErrorService.recordError(e, st);
      debugPrint("${e.toString()}, ${st.toString()}");
      throw 'Error fetching clients: $e';
    }
  }

  static Future<bool> isClientAssigned(String clientUid) async {
    try {
      var cid = await Spdb.getCid();

      final snapshot = await firebase.users
          .doc(cid)
          .collection(Collections.leads.name)
          .where('clientId', isEqualTo: clientUid)
          .limit(1)
          .get();

      return snapshot.docs.isNotEmpty;
    } catch (e, st) {
      await ErrorService.recordError(e, st);
      debugPrint("Error checking client assignment: $e\n$st");
      return false;
    }
  }

  static Future<void> deleteClient({required String uid}) async {
    try {
      var cid = await Spdb.getCid();

      final docRef = await firebase.users
          .doc(cid)
          .collection(Collections.clients.name)
          .doc(uid)
          .get();

      final data = docRef.data() as Map<String, dynamic>;

      await TrashService.moveToTrash(
        docRef: docRef.reference,
        docData: data,
        reason: 'user_deleted',
      );

      await docRef.reference.delete();

      var user = await Spdb.getUser();
      ActivityLogModel activityLogModel = ActivityLogModel(
        userData: user,
        activity: '${data['companyName'] ?? 'N/A'} has been deleted',
        description: 'User has deleted an entry in ${Collections.clients.name}',
        collection:
            '${Collections.users.name}/$cid/${Collections.clients.name}',
        docId: docRef.id,
      );
      await CommonService.add(
        '${Collections.users.name}/$cid/${Collections.activityLogs.name}',
        activityLogModel.toMap(),
      );
    } catch (e, st) {
      await ErrorService.recordError(e, st);
      debugPrint("Error deleting client: $e\n$st");
      throw 'Error deleting client: $e';
    }
  }

  static Future<void> restoreClient(ClientModel client) async {
    var cid = await Spdb.getCid();

    final uid = client.uid;
    if (uid == null || uid.isEmpty) {
      throw Exception("UID missing");
    }

    await firebase.users
        .doc(cid)
        .collection(Collections.clients.name)
        .doc(uid)
        .set(client.toMap());
  }
}
