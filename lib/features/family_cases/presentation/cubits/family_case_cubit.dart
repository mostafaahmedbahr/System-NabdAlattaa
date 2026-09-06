import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/models/family_case.dart';
import '../../data/repositories/family_case_repository.dart';
import 'family_case_state.dart';

class FamilyCaseCubit extends Cubit<FamilyCaseState> {
  FamilyCaseCubit({FamilyCaseRepository? repository})
      : _repository = repository ?? FamilyCaseRepository.instance,
        super(const FamilyCaseState()) {
    _subscription = _repository.watchCases().listen(
          (snapshot) {
            final cases = snapshot.docs
                .map((d) => FamilyCase.fromMap(d.data(), id: d.id))
                .toList();
            emit(FamilyCaseState(cases: cases, filter: state.filter));
          },
          onError: (Object e) {
            emit(FamilyCaseState(cases: state.cases, errorMessage: '$e'));
          },
        );
  }

  final FamilyCaseRepository _repository;
  late final StreamSubscription<QuerySnapshot<Map<String, dynamic>>>
      _subscription;

  void setFilter(String filter) {
    emit(FamilyCaseState(cases: state.cases, filter: filter));
  }

  Future<bool> createCase(FamilyCase familyCase) async {
    try {
      await _repository.addCase(familyCase);
      return true;
    } catch (e) {
      emit(FamilyCaseState(
          cases: state.cases, filter: state.filter, errorMessage: '$e'));
      return false;
    }
  }

  Future<bool> updateCase(FamilyCase familyCase) async {
    try {
      await _repository.updateCase(familyCase);
      return true;
    } catch (e) {
      emit(FamilyCaseState(
          cases: state.cases, filter: state.filter, errorMessage: '$e'));
      return false;
    }
  }

  Future<bool> changeStatus(String caseId, CaseStatus newStatus) async {
    try {
      await _repository.updateStatus(caseId, newStatus);
      return true;
    } catch (e) {
      emit(FamilyCaseState(
          cases: state.cases, filter: state.filter, errorMessage: '$e'));
      return false;
    }
  }

  Future<bool> routeToPrograms(String caseId, {String? notes}) async {
    try {
      await _repository.routeToPrograms(caseId, notes: notes);
      return true;
    } catch (e) {
      emit(FamilyCaseState(
          cases: state.cases, filter: state.filter, errorMessage: '$e'));
      return false;
    }
  }

  Future<bool> assignProgram(
    String caseId, {
    required String program,
    String? notes,
  }) async {
    try {
      await _repository.assignProgram(caseId, program: program, notes: notes);
      return true;
    } catch (e) {
      emit(FamilyCaseState(
          cases: state.cases, filter: state.filter, errorMessage: '$e'));
      return false;
    }
  }

  @override
  Future<void> close() {
    _subscription.cancel();
    return super.close();
  }
}