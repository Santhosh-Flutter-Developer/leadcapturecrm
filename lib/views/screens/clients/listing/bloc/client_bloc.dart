import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '/services/services.dart';
import '/constants/constants.dart';
import '/models/models.dart';

part 'client_state.dart';
part 'client_event.dart';

class ClientBloc extends Bloc<ClientEvent, ClientState> {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  List<ClientModel> allClients = [];

  ClientBloc() : super(ClientLoading()) {
    on<StreamClients>(_streamClients);
    on<DeleteClients>(_deleteClients);
  }

  Future<void> _streamClients(
    StreamClients event,
    Emitter<ClientState> emit,
  ) async {
    emit(ClientLoading());

    try {
      var cid = await Spdb.getCid();
      await emit.forEach<List<ClientModel>>(
        firestore
            .collection(Collections.users.name)
            .doc(cid)
            .collection(Collections.clients.name)
            .where('isCompany', isEqualTo: false)
            .snapshots()
            .map((snapshot) {
              allClients = snapshot.docs
                  .map((doc) => ClientModel.fromMap(doc.id, doc.data()))
                  .toList();
              return allClients;
            }),
        onData: (clients) => ClientLoaded(clients),
        onError: (e, st) {
          debugPrint(st.toString());
          return ClientError("Failed to load clients, $e");
        },
      );
    } catch (e, st) {
      await ErrorService.recordError(e, st);
      debugPrint("${e.toString()}, ${st.toString()}");
      emit(ClientError("Error streaming clients: $e"));
    }
  }

  Future<void> _deleteClients(
    DeleteClients event,
    Emitter<ClientState> emit,
  ) async {
    try {
      await ClientService.deleteClient(uid: event.uid);

      var clients = await ClientService.getAllClients();
      emit(ClientLoaded(clients));
    } catch (e, st) {
      await ErrorService.recordError(e, st);
      emit(ClientError("Failed to delete client: $e"));
    }
  }
}

class ClientCompanyBloc extends Bloc<ClientCompanyEvent, ClientCompanyState> {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  List<ClientModel> allClientCompanys = [];

  ClientCompanyBloc() : super(ClientCompanyLoading()) {
    on<StreamClientCompany>(_streamClientCompanys);
    on<DeleteClientCompany>(_deleteClientCompanys);
  }

  Future<void> _streamClientCompanys(
    StreamClientCompany event,
    Emitter<ClientCompanyState> emit,
  ) async {
    emit(ClientCompanyLoading());

    try {
      var cid = await Spdb.getCid();
      await emit.forEach<List<ClientModel>>(
        firestore
            .collection(Collections.users.name)
            .doc(cid)
            .collection(Collections.clients.name)
            .where('isCompany', isEqualTo: true)
            .snapshots()
            .map((snapshot) {
              allClientCompanys = snapshot.docs
                  .map((doc) => ClientModel.fromMap(doc.id, doc.data()))
                  .toList();
              return allClientCompanys;
            }),
        onData: (clients) => ClientCompanyLoaded(clients),
        onError: (e, st) {
          debugPrint(st.toString());
          return ClientCompanyError("Failed to load companies, $e");
        },
      );
    } catch (e, st) {
      await ErrorService.recordError(e, st);
      debugPrint("${e.toString()}, ${st.toString()}");
      emit(ClientCompanyError("Error streaming companies: $e"));
    }
  }

  Future<void> _deleteClientCompanys(
    DeleteClientCompany event,
    Emitter<ClientCompanyState> emit,
  ) async {
    try {
      await ClientService.deleteClient(uid: event.uid);

      var clients = await ClientService.getAllClients();
      emit(ClientCompanyLoaded(clients));
    } catch (e, st) {
      await ErrorService.recordError(e, st);
      emit(ClientCompanyError("Failed to delete client: $e"));
    }
  }
}
