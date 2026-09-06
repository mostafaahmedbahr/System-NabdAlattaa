import 'package:flutter/services.dart';
import 'package:intl/intl.dart' show DateFormat;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../data/models/family_case.dart';
import '../data/models/questions_config.dart';
import '../presentation/screens/case_status_style.dart';

class CasePdfExporter {
  CasePdfExporter._();

  static const _logoPath = 'assets/images/logo.jpg';
  static const _brandColor = 0xFF00695C;

  static Future<Uint8List> export(FamilyCase caseItem) async {
    final baseFont = pw.Font.ttf(
      await rootBundle.load('assets/fonts/Amiri-Regular.ttf'),
    );
    final boldFont = pw.Font.ttf(
      await rootBundle.load('assets/fonts/Amiri-Bold.ttf'),
    );
    final logoBytes = (await rootBundle.load(_logoPath)).buffer.asUint8List();

    final dateTimeFmt = DateFormat('yyyy/MM/dd HH:mm');
    final statusColor = caseStatusColor(caseItem.status);

    final doc = pw.Document(
      title: 'نموذج حالة - ${caseItem.familyHeadName}',
      author: 'نبض العطاء',
      theme: pw.ThemeData.withFont(base: baseFont, bold: boldFont),
    );

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        textDirection: pw.TextDirection.rtl,
        margin: const pw.EdgeInsets.all(28),
        build: (context) => [
          _header(caseItem, logoBytes, statusColor),
          _sectionTitle('بيانات الأسرة'),
          _familyInfo(caseItem),
          if (caseItem.routedToPrograms) ...[
            _sectionTitle('التوجيه إلى قسم البرامج'),
            _routingInfo(caseItem),
          ],
          _sectionTitle('الأسئلة الأولية عن الحالة'),
          _questions(caseItem),
          _sectionTitle('سجل تغييرات الحالة'),
          _history(caseItem),
          if (caseItem.initialDescription.isNotEmpty) ...[
            _sectionTitle('الوصف المبدئي للحالة'),
            pw.Padding(
              padding: const pw.EdgeInsets.only(top: 6),
              child: pw.Text(
                caseItem.initialDescription,
                textAlign: pw.TextAlign.right,
                style: const pw.TextStyle(fontSize: 11, lineSpacing: 2),
              ),
            ),
          ],
          pw.SizedBox(height: 24),
          _footer(dateTimeFmt),
        ],
      ),
    );

    return doc.save();
  }

  static pw.Widget _header(
    FamilyCase caseItem,
    Uint8List logoBytes,
    Color statusColor,
  ) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(14),
      decoration: pw.BoxDecoration(
        color: PdfColor.fromInt(_brandColor),
        borderRadius: pw.BorderRadius.circular(12),
      ),
      child: pw.Row(
        children: [
          pw.Container(
            width: 42,
            height: 42,
            decoration: pw.BoxDecoration(
              shape: pw.BoxShape.circle,
              color: PdfColors.white,
            ),
            child: pw.ClipOval(
              child: pw.Image(
                pw.MemoryImage(logoBytes),
                width: 42,
                height: 42,
                fit: pw.BoxFit.cover,
              ),
            ),
          ),
          pw.SizedBox(width: 10),
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  caseItem.familyHeadName,
                  style: pw.TextStyle(
                    color: PdfColors.white,
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 2),
                pw.Text(
                  'نبض العطاء - نموذج تسجيل حالة أسرة',
                  style: pw.TextStyle(color: PdfColors.white, fontSize: 10),
                ),
              ],
            ),
          ),
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: pw.BoxDecoration(
              color: PdfColors.white,
              borderRadius: pw.BorderRadius.circular(20),
            ),
            child: pw.Text(
              caseItem.status.label,
              style: pw.TextStyle(
                color: PdfColor.fromInt(statusColor.toARGB32()),
                fontSize: 11,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _sectionTitle(String title) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(top: 18, bottom: 6),
      padding: const pw.EdgeInsets.only(right: 8, bottom: 3),
      decoration: pw.BoxDecoration(
        border: pw.Border(
          right: pw.BorderSide(
            color: PdfColor.fromInt(_brandColor),
            width: 3.5,
          ),
        ),
      ),
      child: pw.Text(
        title,
        style: pw.TextStyle(
          fontSize: 13.5,
          fontWeight: pw.FontWeight.bold,
          color: PdfColor.fromInt(_brandColor),
        ),
      ),
    );
  }

  static pw.Widget _familyInfo(FamilyCase caseItem) {
    final dateFmt = DateFormat('yyyy/MM/dd');
    final entries = <(String, String)>[
      ('المحافظة', caseItem.governorate),
      ('العنوان بالتفصيل', caseItem.address),
      ('رقم الهاتف الأول', caseItem.phone1),
      if (caseItem.phone2.isNotEmpty) ('رقم الهاتف الثاني', caseItem.phone2),
      ('الحالة الاجتماعية', caseItem.socialStatus),
      ('نوع المساعدة المطلوبة', caseItem.helpType),
      ('تصنيف الحالة', caseItem.caseClassification),
      ('هناك عمل حاليًا', caseItem.hasWork ? 'نعم' : 'لا'),
      if (caseItem.pensionValue != null)
        ('قيمة المعاش / التأمينات', '${caseItem.pensionValue} ج.م'),
      ('تاريخ التسجيل', dateFmt.format(caseItem.registrationDate)),
    ];

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: [
        for (final (label, value) in entries)
          pw.Padding(
            padding: const pw.EdgeInsets.symmetric(vertical: 3.5),
            child: pw.Row(
              children: [
                pw.Expanded(
                  flex: 2,
                  child: pw.Text(
                    label,
                    style: const pw.TextStyle(
                      fontSize: 11,
                      color: PdfColors.grey600,
                    ),
                  ),
                ),
                pw.Expanded(
                  flex: 3,
                  child: pw.Text(
                    value,
                    textAlign: pw.TextAlign.right,
                    style: const pw.TextStyle(
                      fontSize: 11,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  static pw.Widget _routingInfo(FamilyCase caseItem) {
    final dateTimeFmt = DateFormat('yyyy/MM/dd HH:mm');
    final entries = <(String, String)>[
      ('حالة التوجيه', 'محولة إلى قسم البرامج'),
      if (caseItem.routedAt != null)
        ('تاريخ التوجيه', dateTimeFmt.format(caseItem.routedAt!)),
      if (caseItem.programAssigned != null)
        ('البرنامج المحدد', caseItem.programAssigned!),
      if (caseItem.programNotes?.isNotEmpty ?? false)
        ('ملاحظات البرنامج', caseItem.programNotes!),
    ];

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: [
        for (final (label, value) in entries)
          pw.Padding(
            padding: const pw.EdgeInsets.symmetric(vertical: 3.5),
            child: pw.Row(
              children: [
                pw.Expanded(
                  flex: 2,
                  child: pw.Text(
                    label,
                    style: const pw.TextStyle(
                      fontSize: 11,
                      color: PdfColors.grey600,
                    ),
                  ),
                ),
                pw.Expanded(
                  flex: 3,
                  child: pw.Text(
                    value,
                    textAlign: pw.TextAlign.right,
                    style: const pw.TextStyle(
                      fontSize: 11,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  static pw.Widget _questions(FamilyCase caseItem) {
    final answered = kQuestions.where((q) {
      final question = caseItem.questions[q.key];
      return question?.answered == true ||
          (question?.details.isNotEmpty ?? false);
    }).toList();

    if (answered.isEmpty) {
      return pw.Text(
        'لا توجد إجابات مسجلة عن الأسئلة.',
        style: pw.TextStyle(fontSize: 11, color: PdfColors.grey600),
      );
    }

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: [
        for (final q in answered) ...[
          pw.Text(
            q.title,
            style: pw.TextStyle(fontSize: 11.5, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 3),
          for (final f in q.fields)
            if (caseItem.questions[q.key]?.details[f.key] != null)
              pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 3, right: 12),
                child: pw.Row(
                  children: [
                    pw.Expanded(
                      flex: 2,
                      child: pw.Text(
                        f.label,
                        style: const pw.TextStyle(
                          fontSize: 10.5,
                          color: PdfColors.grey600,
                        ),
                      ),
                    ),
                    pw.Expanded(
                      flex: 3,
                      child: pw.Text(
                        '${caseItem.questions[q.key]!.details[f.key]}',
                        textAlign: pw.TextAlign.right,
                        style: const pw.TextStyle(
                          fontSize: 10.5,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          pw.SizedBox(height: 6),
        ],
      ],
    );
  }

  static pw.Widget _history(FamilyCase caseItem) {
    final dateTimeFmt = DateFormat('yyyy/MM/dd HH:mm');

    if (caseItem.statusHistory.isEmpty) {
      return pw.Text(
        'لا يوجد سجل حاليًا.',
        style: pw.TextStyle(fontSize: 11, color: PdfColors.grey600),
      );
    }

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: [
        for (final entry in caseItem.statusHistory.reversed)
          pw.Padding(
            padding: const pw.EdgeInsets.symmetric(vertical: 3),
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Container(
                  width: 8,
                  height: 8,
                  margin: const pw.EdgeInsets.only(top: 3),
                  decoration: pw.BoxDecoration(
                    shape: pw.BoxShape.circle,
                    color: PdfColor.fromInt(_brandColor),
                  ),
                ),
                pw.SizedBox(width: 8),
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        entry.status,
                        style: pw.TextStyle(
                          fontSize: 11,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.Text(
                        dateTimeFmt.format(entry.at),
                        style: const pw.TextStyle(
                          fontSize: 9.5,
                          color: PdfColors.grey600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  static pw.Widget _footer(DateFormat dateTimeFmt) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(
          'صادر عن نظام نبض العطاء',
          style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
        ),
        pw.Text(
          'تاريخ الطباعة: ${dateTimeFmt.format(DateTime.now())}',
          style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
        ),
      ],
    );
  }
}
