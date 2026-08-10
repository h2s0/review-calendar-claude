import 'package:flutter/material.dart';
import 'package:review_calendar/core/formatters.dart';
import 'package:review_calendar/data/mock_review_calendar_data.dart';
import 'package:review_calendar/data/review_calendar_models.dart';
import 'package:review_calendar/ui/core/event_palette.dart';
import 'package:review_calendar/ui/core/icons/rc_icons.dart';
import 'package:review_calendar/ui/core/theme/rc_layout.dart';
import 'package:review_calendar/ui/core/theme/rc_theme.dart';

String _calcDDay(DateTime deadline) {
  final diff = deadline.difference(MockReviewCalendarData.today).inDays;
  if (diff == 0) return '오늘';
  if (diff > 0) return 'D-$diff';
  return 'D+${diff.abs()}';
}

/// Campaign detail bottom sheet — mirrors `screen-detail.jsx`'s `CampaignDetail`.
class CampaignDetailSheet extends StatelessWidget {
  const CampaignDetailSheet({required this.campaign, super.key});

  final Campaign campaign;

  @override
  Widget build(BuildContext context) {
    final colors = context.rcColors;
    final heroPalette = switch (campaign.status) {
      CampaignStatus.posted => colors.posted,
      CampaignStatus.urgent => colors.deadline,
      CampaignStatus.upcoming => colors.visit,
    };

    return DraggableScrollableSheet(
      initialChildSize: 0.86,
      maxChildSize: 0.92,
      minChildSize: 0.5,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: colors.background,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 10),
              Container(
                width: 38,
                height: 4,
                decoration: BoxDecoration(
                  color: colors.borderStrong,
                  borderRadius: BorderRadius.circular(RcRadius.pill),
                ),
              ),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 16),
                decoration: BoxDecoration(
                  color: heroPalette.soft,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(26),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [_HeroCornerButton()],
                    ),
                    Row(
                      children: [
                        _EventPill(
                          label: campaign.platform,
                          palette: heroPalette,
                        ),
                        const SizedBox(width: 6),
                        _EventPill(
                          label: campaign.category,
                          palette: colors.unscheduled,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      campaign.brand,
                      style: Theme.of(
                        context,
                      ).textTheme.headlineSmall?.copyWith(fontSize: 21),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                  children: [
                    _Section(
                      title: '진행 일정',
                      child: Column(
                        children: [
                          _TimelineRow(
                            palette: colors.visit,
                            label: '방문 가능',
                            value:
                                '${campaign.visitStart.month}월 ${campaign.visitStart.day}일 ~ ${campaign.visitEnd.month}월 ${campaign.visitEnd.day}일',
                          ),
                          _TimelineRow(
                            palette: colors.deadline,
                            label: '포스팅 마감',
                            value:
                                '${campaign.deadline.month}월 ${campaign.deadline.day}일',
                          ),
                          if (campaign.posted != null)
                            _TimelineRow(
                              palette: colors.posted,
                              label: '발행 완료',
                              value:
                                  '${campaign.posted!.month}월 ${campaign.posted!.day}일',
                              isLast: true,
                            )
                          else
                            _TimelineRow(
                              palette: colors.deadline,
                              label: 'D-day',
                              value: _calcDDay(campaign.deadline),
                              isLast: true,
                              dashed: true,
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    _Section(
                      title: null,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                campaign.reward.type == RewardType.fee
                                    ? '원고료'
                                    : '협찬 가치',
                                style: Theme.of(context).textTheme.labelMedium,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                formatWon(campaign.reward.amount),
                                style: Theme.of(context).textTheme.headlineSmall
                                    ?.copyWith(fontSize: 20),
                              ),
                            ],
                          ),
                          _EventPill(
                            label: campaign.reward.type.label,
                            palette: campaign.reward.type.paletteOf(context),
                          ),
                        ],
                      ),
                    ),
                    if (campaign.notes.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      _Section(
                        title: '필수 항목 · 메모',
                        child: Text(
                          campaign.notes,
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      ),
                    ],
                    const SizedBox(height: 10),
                    _Section(
                      title: null,
                      child: Row(
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: colors.deadline.soft,
                              borderRadius: BorderRadius.circular(
                                RcRadius.small,
                              ),
                            ),
                            child: Center(
                              child: RcIcon(
                                RcIconGlyph.bell,
                                size: 16,
                                color: colors.deadline.ink,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '마감 알림',
                                  style: Theme.of(context).textTheme.bodyLarge
                                      ?.copyWith(fontWeight: FontWeight.w600),
                                ),
                                Text(
                                  '${campaign.alertDays}일 전에 알려드려요',
                                  style: Theme.of(
                                    context,
                                  ).textTheme.labelMedium,
                                ),
                              ],
                            ),
                          ),
                          RcIcon(
                            RcIconGlyph.chevronRight,
                            size: 14,
                            color: colors.inkMuted,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              if (campaign.status != CampaignStatus.posted)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  child: SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () => showModalBottomSheet<void>(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (_) => PostCompleteSheet(campaign: campaign),
                      ),
                      icon: const RcIcon(
                        RcIconGlyph.check,
                        size: 16,
                        color: Colors.white,
                      ),
                      label: const Text('포스팅 완료 처리'),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

/// Hero corner button — screen-detail.jsx renders this as an edit-pencil
/// icon with no `onClick` at all (decorative in the prototype); dismissing
/// the sheet happens by tapping the backdrop outside it (the outer overlay
/// div's `onClick={handleClose}`), which `showModalBottomSheet`'s default
/// barrier-dismiss already replicates — so this button intentionally does
/// nothing on tap, matching the source exactly.
class _HeroCornerButton extends StatelessWidget {
  const _HeroCornerButton();

  @override
  Widget build(BuildContext context) {
    final colors = context.rcColors;
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: RcIcon(RcIconGlyph.edit, size: 15, color: colors.ink),
      ),
    );
  }
}

class _EventPill extends StatelessWidget {
  const _EventPill({required this.label, required this.palette});
  final String label;
  final dynamic palette;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: palette.ink.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(RcRadius.pill),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: palette.ink,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});
  final String? title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = context.rcColors;
    return Container(
      padding: const EdgeInsets.all(RcSpacing.section),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(RcRadius.large),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null) ...[
            Text(
              title!,
              style: Theme.of(
                context,
              ).textTheme.labelMedium?.copyWith(letterSpacing: 1),
            ),
            const SizedBox(height: 10),
          ],
          child,
        ],
      ),
    );
  }
}

class _TimelineRow extends StatelessWidget {
  const _TimelineRow({
    required this.palette,
    required this.label,
    required this.value,
    this.isLast = false,
    this.dashed = false,
  });
  final dynamic palette;
  final String label;
  final String value;
  final bool isLast;
  final bool dashed;

  @override
  Widget build(BuildContext context) {
    final colors = context.rcColors;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 16,
            child: Column(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  margin: const EdgeInsets.only(top: 4),
                  decoration: BoxDecoration(
                    color: palette.ink,
                    shape: BoxShape.circle,
                    border: Border.all(color: palette.soft, width: 3),
                  ),
                ),
                if (!isLast)
                  Expanded(child: Container(width: 2, color: colors.border)),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: Theme.of(context).textTheme.labelMedium),
                  Text(
                    value,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// "언제 발행하셨나요?" date picker sheet.
class PostCompleteSheet extends StatefulWidget {
  const PostCompleteSheet({required this.campaign, super.key});
  final Campaign campaign;

  @override
  State<PostCompleteSheet> createState() => _PostCompleteSheetState();
}

class _PostCompleteSheetState extends State<PostCompleteSheet> {
  late DateTime _selected = MockReviewCalendarData.today;

  @override
  Widget build(BuildContext context) {
    final colors = context.rcColors;
    final dates = List.generate(
      5,
      (i) => MockReviewCalendarData.today.add(Duration(days: i - 2)),
    );
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 30),
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 38,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: colors.borderStrong,
                borderRadius: BorderRadius.circular(RcRadius.pill),
              ),
            ),
          ),
          Text(
            '언제 발행하셨나요?',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontSize: 19),
          ),
          const SizedBox(height: 4),
          Text(
            '발행일을 선택하면 캘린더에 기록돼요',
            style: Theme.of(context).textTheme.labelMedium,
          ),
          const SizedBox(height: 18),
          Row(
            children: dates
                .map(
                  (d) => Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 3),
                      child: InkWell(
                        onTap: () => setState(() => _selected = d),
                        borderRadius: BorderRadius.circular(RcRadius.medium),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: isSameDay(_selected, d)
                                ? colors.brand
                                : colors.card,
                            border: Border.all(
                              color: isSameDay(_selected, d)
                                  ? colors.brand
                                  : colors.border,
                            ),
                            borderRadius: BorderRadius.circular(
                              RcRadius.medium,
                            ),
                          ),
                          child: Column(
                            children: [
                              Text(
                                weekdayKo(d),
                                style: TextStyle(
                                  fontSize: 10,
                                  color: isSameDay(_selected, d)
                                      ? Colors.white70
                                      : colors.inkSubtle,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${d.day}',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: isSameDay(_selected, d)
                                      ? Colors.white
                                      : colors.ink,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).maybePop();
              },
              child: const Text('기록하기'),
            ),
          ),
        ],
      ),
    );
  }
}
