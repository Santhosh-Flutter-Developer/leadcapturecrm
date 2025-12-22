import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '/services/services.dart';
import '/constants/constants.dart';
import '/models/models.dart';
part 'roles_event.dart';
part 'roles_state.dart';

class RolesBloc extends Bloc<RolesEvent, RolesState> {
  FirebaseFirestore firestore = FirebaseFirestore.instance;
  List<RoleModel> allRoles = [];

  RolesBloc() : super(RolesLoading()) {
    on<StreamRoles>(_streamRoless);
  }

  Future<void> _streamRoless(
      StreamRoles event, Emitter<RolesState> emit) async {
    emit(RolesLoading());
    var cid = await Spdb.getCid();

    await emit.forEach(
      firestore
          .collection(Collections.users.name)
          .doc(cid)
          .collection(Collections.roles.name)
          .snapshots()
          .map((snapshot) {
        allRoles = snapshot.docs
            .map((doc) => RoleModel.fromMap(doc.id, doc.data()))
            .toList();

        return allRoles;
      }),
      onData: (roles) => RolesLoaded(roles),
      onError: (error, stackTrace) {
        return RolesError("Failed to load role, $error");
      },
    );
  }
}
