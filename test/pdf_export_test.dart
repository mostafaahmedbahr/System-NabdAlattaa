import 'package:flutter_test/flutter_test.dart';

import 'package:system_nabd_alattaa/features/family_cases/data/models/family_case.dart';
import 'package:system_nabd_alattaa/features/family_cases/pdf/case_pdf.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  FamilyCase sampleCase() => FamilyCase(
        id: 'test-id',
        familyHeadName: 'محمد أحمد',
        phone1: '01012345678',
        phone2: '',
        address: 'شارع الجمهورية - حي شرق',
        governorate: 'الدقهلية',
        socialStatus: 'أرمل/ة',
        helpType: 'مساعدات غذائية',
        hasWork: false,
        pensionValue: 1500,
        initialDescription: 'أسرة مكونة من 5 أفراد تحتاج مساعدة شهرية.',
        registrationDate: DateTime(2026, 1, 15),
        caseClassification: 'حالة عاجلة',
        status: CaseStatus.underReview,
        statusHistory: [
          StatusHistoryEntry(
            status: CaseStatus.underReview.label,
            at: DateTime(2026, 1, 15, 10, 30),
          ),
        ],
      );

  test('CasePdfExporter builds a valid PDF file with Arabic content', () async {
    final bytes = await CasePdfExporter.export(sampleCase());

    expect(bytes.length, greaterThan(5000));
    expect(bytes.sublist(0, 4), [0x25, 0x50, 0x44, 0x46]);
    expect(String.fromCharCodes(bytes.take(5)), startsWith('%PDF-'));
  });

  test('CasePdfExporter handles empty history and no answered questions',
      () async {
    final caseItem = sampleCase()
      ..statusHistory.clear()
      ..questions = {};

    final bytes = await CasePdfExporter.export(caseItem);
    expect(bytes.sublist(0, 4), [0x25, 0x50, 0x44, 0x46]);
    expect(bytes.length, greaterThan(5000));
  });
}