import 'package:flutter/material.dart';
import 'package:review_calendar/core/formatters.dart';
import 'package:review_calendar/data/review_calendar_models.dart';
import 'package:review_calendar/features/calendar/presentation/calendar_view_model.dart';
import 'package:review_calendar/ui/core/dashed_border.dart';
import 'package:review_calendar/ui/core/icons/rc_icons.dart';
import 'package:review_calendar/ui/core/theme/rc_layout.dart';
import 'package:review_calendar/ui/core/theme/rc_theme.dart';

enum _SortOrder { latest, oldest }

/// 발행 이력 — mirrors `screen-records.jsx`'s `RecordsScreen`.
class RecordsScreen extends StatefulWidget {
  const RecordsScreen({
    required this.viewModel,
    required this.onOpenCampaign,
    super.key,
  });
  final CalendarViewModel viewModel;
  final ValueChanged<Campaign> onOpenCampaign;

  @override
  State<RecordsScreen> createState() => _RecordsScreenState();
}

class _RecordsScreenState extends State<RecordsScreen> {
  final _today = DateTime.now();
  String _category = '전체';
  _SortOrder _sort = _SortOrder.latest;
  int _monthOffset = 0;

  @override
  void initState() {
    super.initState();
    widget.viewModel.addListener(_onViewModelChanged);
  }

  @override
  void dispose() {
    widget.viewModel.removeListener(_onViewModelChanged);
    super.dispose();
  }

  void _onViewModelChanged() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final colors = context.rcColors;
    final categories = [
      '전체',
      ...{for (final c in widget.viewModel.campaigns) c.category},
    ];
    final base = DateTime(_today.year, _today.month + _monthOffset, 1);
    final monthLabel = '${base.year}년 ${base.month}월';

    var posted = widget.viewModel.events
        .where(
          (e) =>
              e.type == CalendarEventType.posted &&
              e.date.year == base.year &&
              e.date.month == base.month,
        )
        .toList();
    if (_category != '전체') {
      posted = posted.where((e) {
        final c = e.campaignId == null
            ? null
            : widget.viewModel.campaignById(e.campaignId!);
        return c != null && c.category == _category;
      }).toList();
    }
    posted.sort(
      (a, b) => _sort == _SortOrder.latest
          ? b.date.compareTo(a.date)
          : a.date.compareTo(b.date),
    );

    return ColoredBox(
      color: colors.background,
      child: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.only(bottom: 120),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('포스팅 기록', style: Theme.of(context).textTheme.bodySmall),
                  Text(
                    '발행 이력',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
              child: Row(
                children: [
                  Expanded(
                    child: _MiniStat(label: '총 발행', value: '${posted.length}건'),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _MiniStat(
                      label: '이번 달',
                      value: '${_monthOffset == 0 ? posted.length : 0}건',
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _NavCircle(
                    glyph: RcIconGlyph.chevronLeft,
                    onTap: () => setState(() => _monthOffset -= 1),
                  ),
                  SizedBox(
                    width: 90,
                    child: Text(
                      monthLabel,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                  ),
                  _NavCircle(
                    glyph: RcIconGlyph.chevronRight,
                    onTap: () => setState(() => _monthOffset += 1),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 36,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                scrollDirection: Axis.horizontal,
                itemCount: categories.length,
                separatorBuilder: (_, _) => const SizedBox(width: 6),
                itemBuilder: (context, i) {
                  final cat = categories[i];
                  final on = _category == cat;
                  return InkWell(
                    onTap: () => setState(() => _category = cat),
                    borderRadius: BorderRadius.circular(RcRadius.pill),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: on ? colors.brand : colors.card,
                        border: Border.all(
                          color: on ? colors.brand : colors.border,
                        ),
                        borderRadius: BorderRadius.circular(RcRadius.pill),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        cat,
                        style: Theme.of(context).textTheme.labelMedium
                            ?.copyWith(
                              color: on ? Colors.white : colors.inkSubtle,
                            ),
                      ),
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
              child: Align(
                alignment: Alignment.centerRight,
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: colors.backgroundAlternative,
                    borderRadius: BorderRadius.circular(RcRadius.pill),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _SortButton(
                        label: '최신순',
                        on: _sort == _SortOrder.latest,
                        onTap: () => setState(() => _sort = _SortOrder.latest),
                      ),
                      _SortButton(
                        label: '오래된순',
                        on: _sort == _SortOrder.oldest,
                        onTap: () => setState(() => _sort = _SortOrder.oldest),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: posted.isEmpty
                  ? DashedBorderBox(
                      color: colors.borderStrong,
                      background: colors.card,
                      radius: RcRadius.medium,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(24),
                        alignment: Alignment.center,
                        child: Text(
                          '해당 달에 발행 기록이 없어요',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: colors.inkMuted),
                        ),
                      ),
                    )
                  : Column(
                      children: posted
                          .map(
                            (ev) => Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: _RecordRow(
                                event: ev,
                                campaignById: widget.viewModel.campaignById,
                                onOpenCampaign: widget.onOpenCampaign,
                              ),
                            ),
                          )
                          .toList(),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = context.rcColors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: colors.card,
        border: Border.all(color: colors.border),
        borderRadius: BorderRadius.circular(RcRadius.medium),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.labelMedium),
          Text(value, style: Theme.of(context).textTheme.titleLarge),
        ],
      ),
    );
  }
}

class _NavCircle extends StatelessWidget {
  const _NavCircle({required this.glyph, required this.onTap});
  final RcIconGlyph glyph;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.rcColors;
    return InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: Container(
        width: 28,
        height: 28,
        margin: const EdgeInsets.symmetric(horizontal: 7),
        decoration: BoxDecoration(
          color: colors.backgroundAlternative,
          shape: BoxShape.circle,
        ),
        child: Center(child: RcIcon(glyph, size: 13, color: colors.ink)),
      ),
    );
  }
}

class _SortButton extends StatelessWidget {
  const _SortButton({
    required this.label,
    required this.on,
    required this.onTap,
  });
  final String label;
  final bool on;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.rcColors;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(RcRadius.pill),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: on ? colors.card : Colors.transparent,
          borderRadius: BorderRadius.circular(RcRadius.pill),
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: on ? colors.brandDeep : colors.inkSubtle,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _RecordRow extends StatelessWidget {
  const _RecordRow({
    required this.event,
    required this.campaignById,
    required this.onOpenCampaign,
  });
  final CalendarEvent event;
  final Campaign? Function(String id) campaignById;
  final ValueChanged<Campaign> onOpenCampaign;

  @override
  Widget build(BuildContext context) {
    final colors = context.rcColors;
    final campaign = event.campaignId == null
        ? null
        : campaignById(event.campaignId!);
    return InkWell(
      onTap: campaign == null ? null : () => onOpenCampaign(campaign),
      borderRadius: BorderRadius.circular(RcRadius.medium),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: colors.card,
          border: Border.all(color: colors.border),
          borderRadius: BorderRadius.circular(RcRadius.medium),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: colors.posted.soft,
                borderRadius: BorderRadius.circular(RcRadius.small),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '${event.date.day}',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: colors.posted.ink,
                    ),
                  ),
                  Text(
                    weekdayKo(event.date),
                    style: TextStyle(
                      fontSize: 8.5,
                      fontWeight: FontWeight.w600,
                      color: colors.posted.ink,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (campaign != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        '${campaign.platform} · ${campaign.reward.type.label} ${formatWon(campaign.reward.amount)}',
                        style: Theme.of(context).textTheme.labelMedium,
                      ),
                    ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: colors.posted.soft,
                borderRadius: BorderRadius.circular(RcRadius.pill),
              ),
              child: Text(
                '발행완료',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: colors.posted.ink,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
