import 'package:cloud_firestore/cloud_firestore.dart';

enum CaseStatus {
  underReview('تحت المراجعة'),
  rejected('مرفوضة'),
  needsFieldResearch('تحتاج إلى بحث ميداني'),
  fieldResearchDone('تم إجراء بحث ميداني');

  const CaseStatus(this.label);

  final String label;

  static CaseStatus fromLabel(String label) {
    return CaseStatus.values.firstWhere(
      (s) => s.label == label,
      orElse: () => CaseStatus.underReview,
    );
  }
}

class StatusHistoryEntry {
  const StatusHistoryEntry({required this.status, required this.at});

  final String status;
  final DateTime at;

  Map<String, dynamic> toMap() => {
        'status': status,
        'at': at,
      };

  factory StatusHistoryEntry.fromMap(Map<String, dynamic> map) {
    return StatusHistoryEntry(
      status: map['status'] as String? ?? '',
      at: (map['at'] as Timestamp? ?? Timestamp.now()).toDate(),
    );
  }
}

class FamilyQuestion {
  FamilyQuestion({this.answered = false});

  bool answered;
  Map<String, dynamic> details = {};

  Map<String, dynamic> toMap() => {
        'answered': answered,
        'details': details,
      };

  factory FamilyQuestion.fromMap(Map<String, dynamic> map) {
    final q = FamilyQuestion(answered: map['answered'] as bool? ?? false);
    q.details = (map['details'] as Map<String, dynamic>?) ?? {};
    return q;
  }
}

class FamilyCase {
  FamilyCase({
    this.id,
    required this.familyHeadName,
    required this.phone1,
    this.phone2 = '',
    required this.address,
    required this.governorate,
    required this.socialStatus,
    required this.helpType,
    required this.hasWork,
    this.pensionValue,
    this.initialDescription = '',
    required this.registrationDate,
    required this.caseClassification,
    this.status = CaseStatus.underReview,
    List<StatusHistoryEntry>? statusHistory,
    this.questions = const {},
    this.routedToPrograms = false,
    this.routedAt,
    this.programAssigned,
    this.programNotes,
    this.createdBy,
  }) : statusHistory = statusHistory ?? [];

  final String? id;
  final String familyHeadName;
  final String phone1;
  final String phone2;
  final String address;
  final String governorate;
  final String socialStatus;
  final String helpType;
  final bool hasWork;
  final double? pensionValue;
  final String initialDescription;
  final DateTime registrationDate;
  final String caseClassification;
  CaseStatus status;
  final List<StatusHistoryEntry> statusHistory;
  Map<String, FamilyQuestion> questions;
  bool routedToPrograms;
  DateTime? routedAt;
  String? programAssigned;
  String? programNotes;
  final String? createdBy;

  Map<String, dynamic> toMap() {
    return {
      'familyHeadName': familyHeadName,
      'phone1': phone1,
      'phone2': phone2,
      'address': address,
      'governorate': governorate,
      'socialStatus': socialStatus,
      'helpType': helpType,
      'hasWork': hasWork,
      'pensionValue': pensionValue,
      'initialDescription': initialDescription,
      'registrationDate': registrationDate,
      'caseClassification': caseClassification,
      'status': status.label,
      'statusHistory': statusHistory.map((e) => e.toMap()).toList(),
      'questions': questions.map((k, v) => MapEntry(k, v.toMap())),
      'routedToPrograms': routedToPrograms,
      'routedAt': routedAt,
      'programAssigned': programAssigned,
      'programNotes': programNotes,
      'createdBy': createdBy,
    };
  }

  factory FamilyCase.fromMap(Map<String, dynamic> map, {String? id}) {
    return FamilyCase(
      id: id ?? map['id'] as String?,
      familyHeadName: map['familyHeadName'] as String? ?? '',
      phone1: map['phone1'] as String? ?? '',
      phone2: map['phone2'] as String? ?? '',
      address: map['address'] as String? ?? '',
      governorate: map['governorate'] as String? ?? '',
      socialStatus: map['socialStatus'] as String? ?? '',
      helpType: map['helpType'] as String? ?? '',
      hasWork: map['hasWork'] as bool? ?? false,
      pensionValue: (map['pensionValue'] as num?)?.toDouble(),
      initialDescription: map['initialDescription'] as String? ?? '',
      registrationDate: (map['registrationDate'] as Timestamp? ?? Timestamp.now())
          .toDate(),
      caseClassification: map['caseClassification'] as String? ?? '',
      status: CaseStatus.fromLabel(map['status'] as String? ?? ''),
      statusHistory: ((map['statusHistory'] as List?) ?? [])
          .map((e) => StatusHistoryEntry.fromMap(e as Map<String, dynamic>))
          .toList(),
      questions: ((map['questions'] as Map<String, dynamic>?) ?? {})
          .map((k, v) =>
              MapEntry(k, FamilyQuestion.fromMap(v as Map<String, dynamic>))),
      routedToPrograms: map['routedToPrograms'] as bool? ?? false,
      routedAt: (map['routedAt'] as Timestamp?)?.toDate(),
      programAssigned: map['programAssigned'] as String?,
      programNotes: map['programNotes'] as String?,
      createdBy: map['createdBy'] as String?,
    );
  }
}