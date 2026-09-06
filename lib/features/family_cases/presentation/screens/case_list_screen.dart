import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart' show DateFormat;

import '../../data/models/family_case.dart';
import '../cubits/family_case_cubit.dart';
import '../cubits/family_case_state.dart';
import 'case_details_screen.dart';
import 'case_form_screen.dart';
import 'case_status_style.dart';

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
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const ClipOval(
              child: Image(
                image: AssetImage('assets/images/logo.jpg'),
                width: 30,
                height: 30,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              'استقبال الأسر',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'إضافة حالة جديدة',
            icon: const Icon(Icons.add_rounded),
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
              _StatsBar(state: state),
              const SizedBox(height: 4),
              SizedBox(
                height: 52,
                child: ListView.separated(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  scrollDirection: Axis.horizontal,
                  itemCount: _filters.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 8),
                  itemBuilder: (context, i) {
                    final f = _filters[i];
                    final selected = state.filter == f;
                    return FilterChip(
                      label: Text(f),
                      showCheckmark: false,
                      selected: selected,
                      onSelected: (_) =>
                          context.read<FamilyCaseCubit>().setFilter(f),
                      selectedColor: scheme.primaryContainer,
                      checkmarkColor: scheme.onPrimaryContainer,
                      labelStyle: TextStyle(
                        color: selected ? scheme.onPrimaryContainer : null,
                        fontWeight:
                            selected ? FontWeight.w700 : FontWeight.w500,
                      ),
                      shape: const StadiumBorder(),
                      side: BorderSide(
                        color: selected
                            ? scheme.primaryContainer
                            : scheme.outlineVariant.withValues(alpha: 0.5),
                      ),
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

class _StatsBar extends StatelessWidget {
  const _StatsBar({required this.state});

  final FamilyCaseState state;

  @override
  Widget build(BuildContext context) {
    final cases = state.cases;
    final underReview =
        cases.where((c) => c.status == CaseStatus.underReview).length;
    final needsResearch =
        cases.where((c) => c.status == CaseStatus.needsFieldResearch).length;
    final routed = cases.where((c) => c.routedToPrograms).length;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Row(
        children: [
          _StatTile(
            icon: Icons.groups_rounded,
            label: 'إجمالي الحالات',
            value: '${cases.length}',
            color: Theme.of(context).colorScheme.primary,
            expanded: true,
          ),
          const SizedBox(width: 10),
          _StatTile(
            icon: Icons.pending_outlined,
            label: 'تحت المراجعة',
            value: '$underReview',
            color: caseStatusColor(CaseStatus.underReview),
          ),
          const SizedBox(width: 10),
          _StatTile(
            icon: Icons.search_outlined,
            label: 'بانتظار البحث',
            value: '$needsResearch',
            color: caseStatusColor(CaseStatus.needsFieldResearch),
          ),
          const SizedBox(width: 10),
          _StatTile(
            icon: Icons.handshake_outlined,
            label: 'محولة',
            value: '$routed',
            color: const Color(0xFF7C3AED),
          ),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    this.expanded = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final bool expanded;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tile = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15, color: color),
            const SizedBox(width: 3),
            Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 16,
                color: scheme.onSurface,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            label,
            maxLines: 1,
            style: TextStyle(
              fontSize: 10.5,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
    return Expanded(
      flex: expanded ? 4 : 3,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: scheme.outlineVariant.withValues(alpha: 0.4),
          ),
        ),
        child: tile,
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
      return _EmptyView(
        message: 'لا توجد حالات مسجلة بعد',
        icon: Icons.inbox_outlined,
        onAdd: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const CaseFormScreen()),
          );
        },
      );
    }
    if (cases.isEmpty) {
      return const _EmptyView(
        message: 'لا توجد حالات مطابقة للفلتر',
        icon: Icons.filter_alt_off_outlined,
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: cases.length,
      itemBuilder: (context, i) => _CaseCard(caseItem: cases[i]),
    );
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView({required this.message, required this.icon, this.onAdd});

  final String message;
  final IconData icon;
  final VoidCallback? onAdd;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 84,
            height: 84,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: scheme.primary.withValues(alpha: 0.08),
            ),
            child: Icon(icon, size: 42, color: scheme.primary.withValues(alpha: 0.5)),
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
          ),
          if (onAdd != null) ...[
            const SizedBox(height: 4),
            TextButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add_rounded),
              label: const Text('إضافة حالة جديدة'),
            ),
          ],
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
    final statusColor = caseStatusColor(caseItem.status);
    final initial =
        caseItem.familyHeadName.isNotEmpty ? caseItem.familyHeadName[0] : 'ح';
    final dateFmt = DateFormat('yyyy/MM/dd');

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.4)),
      ),
      child: InkWell(
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: statusColor.withValues(alpha: 0.13),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      initial,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: statusColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          caseItem.familyHeadName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 5),
                        Row(
                          children: [
                            Icon(
                              Icons.location_on_outlined,
                              size: 14,
                              color: Colors.grey.shade600,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                '${caseItem.governorate} - ${caseItem.address}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 12.5,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            Icon(
                              Icons.phone_outlined,
                              size: 14,
                              color: Colors.grey.shade600,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                caseItem.phone2.isNotEmpty
                                    ? '${caseItem.phone1} • ${caseItem.phone2}'
                                    : caseItem.phone1,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 12.5,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      _StatusBadge(color: statusColor, label: caseItem.status.label),
                      if (caseItem.routedToPrograms) ...[
                        const SizedBox(height: 6),
                        _StatusBadge(
                          color: scheme.primary,
                          label: 'محولة للبرامج',
                        ),
                      ],
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.schedule,
                        size: 14,
                        color: Colors.grey.shade500,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        dateFmt.format(caseItem.registrationDate),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Text(
                        'عرض التفاصيل',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          color: scheme.primary,
                        ),
                      ),
                      const SizedBox(width: 3),
                      Icon(
                        Icons.arrow_back_ios_new,
                        size: 13,
                        color: scheme.primary,
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11.5,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}