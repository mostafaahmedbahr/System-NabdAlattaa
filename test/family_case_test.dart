import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:system_nabd_alattaa/features/family_cases/data/models/family_case.dart';
import 'package:system_nabd_alattaa/features/family_cases/presentation/cubits/family_case_state.dart';

void main() {
  group('FamilyCase model', () {
    test('fromMap parses a Firestore document correctly', () {
      final stored = <String, dynamic>{
        'familyHeadName': 'محمد أحمد',
        'phone1': '01000000000',
        'phone2': '01111111111',
        'address': 'شارع النيل، المعادي',
        'governorate': 'القاهرة',
        'socialStatus': 'أرمل/ة',
        'helpType': 'مساعدة مالية',
        'hasWork': true,
        'pensionValue': 1500.0,
        'initialDescription': 'أسرة محتاجة',
        'registrationDate': Timestamp.fromDate(DateTime(2026, 9, 1, 10, 30)),
        'caseClassification': 'حالة عاجلة',
        'status': CaseStatus.needsFieldResearch.label,
        'statusHistory': [
          {
            'status': CaseStatus.underReview.label,
            'at': Timestamp.fromDate(DateTime(2026, 9, 1, 9)),
          },
          {
            'status': CaseStatus.needsFieldResearch.label,
            'at': Timestamp.fromDate(DateTime(2026, 9, 2, 14)),
          },
        ],
        'questions': {
          'workingMembers': {
            'answered': true,
            'details': {'count': 2, 'income': 4000.0},
          },
        },
        'routedToPrograms': true,
        'routedAt': Timestamp.fromDate(DateTime(2026, 9, 3)),
        'programAssigned': 'مساندة مالية شهرية',
        'programNotes': 'ملاحظات',
        'createdBy': 'user-1',
      };

      final restored = FamilyCase.fromMap(stored, id: 'abc123');

      expect(restored.id, 'abc123');
      expect(restored.familyHeadName, 'محمد أحمد');
      expect(restored.phone1, '01000000000');
      expect(restored.phone2, '01111111111');
      expect(restored.address, 'شارع النيل، المعادي');
      expect(restored.governorate, 'القاهرة');
      expect(restored.socialStatus, 'أرمل/ة');
      expect(restored.helpType, 'مساعدة مالية');
      expect(restored.hasWork, isTrue);
      expect(restored.pensionValue, 1500.0);
      expect(restored.initialDescription, 'أسرة محتاجة');
      expect(restored.registrationDate, DateTime(2026, 9, 1, 10, 30));
      expect(restored.caseClassification, 'حالة عاجلة');
      expect(restored.status, CaseStatus.needsFieldResearch);
      expect(restored.statusHistory, hasLength(2));
      expect(restored.statusHistory.first.status, CaseStatus.underReview.label);
      expect(restored.statusHistory.last.at, DateTime(2026, 9, 2, 14));
      expect(restored.questions['workingMembers']!.answered, isTrue);
      expect(restored.questions['workingMembers']!.details['count'], 2);
      expect(restored.routedToPrograms, isTrue);
      expect(restored.routedAt, DateTime(2026, 9, 3));
      expect(restored.programAssigned, 'مساندة مالية شهرية');
      expect(restored.programNotes, 'ملاحظات');
      expect(restored.createdBy, 'user-1');
    });

    test('toMap produces Firestore-serializable types', () {
      final familyCase = FamilyCase(
        familyHeadName: 'حالة',
        phone1: '010',
        address: 'عنوان',
        governorate: 'القاهرة',
        socialStatus: 'أرمل/ة',
        helpType: 'مساعدة مالية',
        hasWork: false,
        registrationDate: DateTime(2026, 9, 1),
        caseClassification: 'حالة عادية',
      );

      final map = familyCase.toMap();
      expect(map['status'], CaseStatus.underReview.label);
      expect(map['statusHistory'], isA<List<Map<String, dynamic>>>());
      expect(map['registrationDate'], isA<DateTime>());
      expect(map['routedToPrograms'], false);
    });

    test('CaseStatus parsing falls back to underReview for unknown labels', () {
      expect(CaseStatus.fromLabel('غير موجود'), CaseStatus.underReview);
      expect(CaseStatus.fromLabel('مرفوضة'), CaseStatus.rejected);
      expect(CaseStatus.fromLabel('تحتاج إلى بحث ميداني'),
          CaseStatus.needsFieldResearch);
    });
  });

  group('FamilyCaseState', () {
    test('filteredCases applies status filter', () {
      final cases = [
        FamilyCase(
          familyHeadName: 'أ',
          phone1: '1',
          address: 'a',
          governorate: 'القاهرة',
          socialStatus: 'عادية',
          helpType: 'مالية',
          hasWork: false,
          registrationDate: DateTime(2026),
          caseClassification: 'عادية',
          status: CaseStatus.underReview,
        ),
        FamilyCase(
          familyHeadName: 'ب',
          phone1: '2',
          address: 'b',
          governorate: 'الجيزة',
          socialStatus: 'عادية',
          helpType: 'غذائية',
          hasWork: true,
          registrationDate: DateTime(2026),
          caseClassification: 'عادية',
          status: CaseStatus.rejected,
        ),
      ];
      final state = FamilyCaseState(cases: cases, filter: 'مرفوضة');
      expect(state.filteredCases, hasLength(1));
      expect(state.filteredCases.single.familyHeadName, 'ب');
    });
  });
}