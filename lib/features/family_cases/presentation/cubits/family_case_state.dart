import 'package:equatable/equatable.dart';

import '../../data/models/family_case.dart';

class FamilyCaseState extends Equatable {
  const FamilyCaseState({
    this.cases = const [],
    this.filter = 'الكل',
    this.errorMessage,
  });

  final List<FamilyCase> cases;
  final String filter;
  final String? errorMessage;

  List<FamilyCase> get filteredCases {
    if (filter == 'الكل') return cases;
    if (filter == 'محولة للبرامج') {
      return cases.where((c) => c.routedToPrograms).toList();
    }
    return cases.where((c) => c.status.label == filter).toList();
  }

  @override
  List<Object?> get props => [cases, filter, errorMessage];
}