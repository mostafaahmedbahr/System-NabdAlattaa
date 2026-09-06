import 'package:flutter/material.dart';

import '../../data/models/family_case.dart';

Color caseStatusColor(CaseStatus status) {
  return switch (status) {
    CaseStatus.underReview => const Color(0xFF2563EB),
    CaseStatus.rejected => const Color(0xFFDC2626),
    CaseStatus.needsFieldResearch => const Color(0xFFEA580C),
    CaseStatus.fieldResearchDone => const Color(0xFF16A34A),
  };
}

IconData caseStatusIcon(CaseStatus status) {
  return switch (status) {
    CaseStatus.underReview => Icons.pending_actions_outlined,
    CaseStatus.rejected => Icons.cancel_outlined,
    CaseStatus.needsFieldResearch => Icons.search_outlined,
    CaseStatus.fieldResearchDone => Icons.fact_check_outlined,
  };
}