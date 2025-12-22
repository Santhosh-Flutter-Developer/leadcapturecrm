import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '/services/services.dart';
import '/constants/constants.dart';
import '/models/models.dart';
part 'employee_event.dart';
part 'employee_state.dart';

class EmployeeBloc extends Bloc<EmployeeEvent, EmployeeState> {
  FirebaseFirestore firestore = FirebaseFirestore.instance;
  List<EmployeeModel> allEmployees = [];

  EmployeeBloc() : super(EmployeeLoading()) {
    on<StreamEmployee>(_streamEmployees);
    on<DeleteEmployee>(_deleteEmployee);
  }

  Future<void> _streamEmployees(
    StreamEmployee event,
    Emitter<EmployeeState> emit,
  ) async {
    emit(EmployeeLoading());
    var cid = await Spdb.getCid();

    await emit.forEach(
      firestore
          .collection(Collections.users.name)
          .doc(cid)
          .collection(Collections.employees.name)
          .snapshots()
          .map((snapshot) {
            allEmployees = snapshot.docs
                .map((doc) => EmployeeModel.fromMap(doc.id, doc.data()))
                .toList();

            return allEmployees;
          }),
      onData: (employees) => EmployeeLoaded(employees),
      onError: (error, stackTrace) {
        log(stackTrace.toString());
        return EmployeeError("Failed to load employees, $error");
      },
    );
  }

  Future<void> _deleteEmployee(
    DeleteEmployee event,
    Emitter<EmployeeState> emit,
  ) async {
    try {
      await EmployeeService.deleteEmployee(uid: event.uid);

      var updatedList = await EmployeeService.getAllEmployees();
      emit(EmployeeLoaded(updatedList));
    } catch (e, st) {
      await ErrorService.recordError(e, st);
      emit(EmployeeError("Failed to delete employee: $e"));
    }
  }
}
