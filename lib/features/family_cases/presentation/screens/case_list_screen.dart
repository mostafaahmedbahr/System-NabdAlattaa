import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../cubits/family_case_cubit.dart';
import '../cubits/family_case_state.dart';
import '../../data/models/family_case.dart';
import 'case_details_screen.dart';
import 'case_form_screen.dart';

class CaseListScreen extends StatelessWidget {
  const CaseListScreen({super.key});

  static const _filters = [
    'الكل',
    'تحت المراجعة',
    'مرفوضة',
    'تحتاج إلى بحث ميداني',
    'تم إجراء بحث ميداني',
    'محولة للبرامج',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('استقبال الأسر'),
        actions: [
          IconButton(
            tooltip: 'إضافة حالة جديدة',
            icon: const Icon(Icons.add),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const CaseFormScreen()),
              );
            },
          ),
        ],
      ),
      body: BlocBuilder<FamilyCaseCubit, FamilyCaseState>(
        builder: (context, state) {
          return Column(
            children: [
              SizedBox(
                height: 56,
                child: ListView.separated(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  scrollDirection: Axis.horizontal,
                  itemCount: _filters.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 8),
                  itemBuilder: (context, i) {
                    final f = _filters[i];
                    return FilterChip(
                      label: Text(f),
                      selected: state.filter == f,
                      onSelected: (_) =>
                          context.read<FamilyCaseCubit>().setFilter(f),
                    );
                  },
                ),
              ),
              Expanded(
                child: state.errorMessage != null
                    ? Center(child: Text(state.errorMessage!))
                    : _CaseList(state: state),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _CaseList extends StatelessWidget {
  const _CaseList({required this.state});

  final FamilyCaseState state;

  @override
  Widget build(BuildContext context) {
    final cases = state.filteredCases;
    if (state.cases.isEmpty) {
      return const _EmptyView(
        message: 'لا توجد حالات مسجلة',
        icon: Icons.inbox_outlined,
      );
    }
    if (cases.isEmpty) {
      return const _EmptyView(
        message: 'لا توجد حالات مطابقة للفلتر',
        icon: Icons.filter_alt_off_outlined,
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: cases.length,
      itemBuilder: (context, i) => _CaseCard(caseItem: cases[i]),
    );
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView({required this.message, required this.icon});

  final String message;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 8),
          Text(message),
        ],
      ),
    );
  }
}

class _CaseCard extends StatelessWidget {
  const _CaseCard({required this.caseItem});

  final FamilyCase caseItem;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final statusColor = switch (caseItem.status) {
      CaseStatus.underReview => Colors.blue,
      CaseStatus.rejected => Colors.red,
      CaseStatus.needsFieldResearch => Colors.orange,
      CaseStatus.fieldResearchDone => Colors.green,
    };

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade300),
      ),
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => CaseDetailsScreen(caseId: caseItem.id!),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      caseItem.familyHeadName,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      caseItem.status.label,
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.location_on_outlined,
                      size: 16, color: Colors.grey.shade600),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      '${caseItem.governorate} - ${caseItem.address}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ),
                ],
              ),
              if (caseItem.routedToPrograms) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.handshake_outlined,
                        size: 16, color: scheme.primary),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        'محولة إلى قسم البرامج',
                        style: TextStyle(
                          fontSize: 13,
                          color: scheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}