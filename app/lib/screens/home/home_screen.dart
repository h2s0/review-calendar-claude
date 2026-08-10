import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:review_calendar/core/formatters.dart';
import 'package:review_calendar/data/review_calendar_models.dart';
import 'package:review_calendar/features/home/presentation/home_view_model.dart';
import 'package:review_calendar/ui/core/event_palette.dart';
import 'package:review_calendar/ui/core/icons/rc_icons.dart';
import 'package:review_calendar/ui/core/theme/rc_layout.dart';
import 'package:review_calendar/ui/core/theme/rc_theme.dart';

/// Home dashboard — mirrors `screen-home.jsx`'s `HomeDashboard`.
class HomeDashboard extends StatefulWidget {
  const HomeDashboard({
    required this.viewModel,
    required this.goals,
    required this.onOpenUpload,
    required this.onOpenCampaign,
    required this.onOpenSettings,
    required this.onGoRevenue,
    super.key,
  });

  final HomeViewModel viewModel;
  final MonthlyRewardGoals goals;
  final VoidCallback onOpenUpload;
  final ValueChanged<Campaign> onOpenCampaign;
  final VoidCallback onOpenSettings;
  final VoidCallback onGoRevenue;

  @override
  State<HomeDashboard> createState() => _HomeDashboardState();
}

class _HomeDashboardState extends State<HomeDashboard> {
  final _today = DateTime.now();

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

  List<CalendarEvent> _weekEvents() {
    final start = _today.subtract(Duration(days: _today.weekday % 7));
    final end = start.add(const Duration(days: 6));
    final events =
        widget.viewModel.events
            .where((e) => !e.date.isBefore(start) && !e.date.isAfter(end))
            .toList()
          ..sort((a, b) => a.date.compareTo(b.date));
    return events;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.rcColors;
    final weekEvents = _weekEvents();
    final monthEvents = widget.viewModel.events
        .where(
          (e) => e.date.month == _today.month && e.date.year == _today.year,
        )
        .toList();
    final visitCount = monthEvents
        .where((e) => e.type == CalendarEventType.visit)
        .length;
    final deadlineCount = monthEvents
        .where((e) => e.type == CalendarEventType.deadline)
        .length;
    final postedCount = monthEvents
        .where((e) => e.type == CalendarEventType.posted)
        .length;
    final undecidedCount = widget.viewModel.undecidedCount;

    return ColoredBox(
      color: colors.background,
      child: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.only(bottom: 120),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${monthDayLabel(_today)} ${weekdayKo(_today)}요일',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '안녕하세요 👋',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                      ],
                    ),
                  ),
                  _SettingsButton(onTap: widget.onOpenSettings),
                ],
              ),
            ),
            _SectionBlock(
              title: '다가오는 일정',
              subtitle: '${weekEvents.length}건',
              child: weekEvents.isEmpty
                  ? const _EmptyRow(text: '이번 주는 예정된 일정이 없어요')
                  : SizedBox(
                      height: 108,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: weekEvents.length.clamp(0, 8),
                        separatorBuilder: (_, _) => const SizedBox(width: 8),
                        itemBuilder: (context, i) => _WeekEventCard(
                          event: weekEvents[i],
                          campaignById: widget.viewModel.campaignById,
                          onOpenCampaign: widget.onOpenCampaign,
                        ),
                      ),
                    ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
              child: _HomeGoalPush(
                goals: widget.goals,
                current: widget.viewModel.thisMonthRevenueTotal,
                currentFee: widget.viewModel.thisMonthRevenueFee,
                onGoRevenue: widget.onGoRevenue,
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 8),
              child: Text(
                '이번 달 요약',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                childAspectRatio: 1.7,
                children: [
                  _SummaryCard(
                    type: CalendarEventType.visit,
                    label: '방문 예정',
                    value: visitCount,
                  ),
                  _SummaryCard(
                    type: CalendarEventType.deadline,
                    label: '마감 예정',
                    value: deadlineCount,
                  ),
                  _SummaryCard(
                    type: CalendarEventType.posted,
                    label: '포스팅 완료',
                    value: postedCount,
                  ),
                  _SummaryCard(
                    type: CalendarEventType.idea,
                    label: '미정 일정',
                    value: undecidedCount,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Header gear button — the design's inline settings SVG isn't part of the
/// shared `Icons` glyph set (design-system.jsx), so this uses Material's
/// equivalent gear glyph rather than hand-transcribing a 12-arc path.
class _SettingsButton extends StatelessWidget {
  const _SettingsButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.rcColors;
    return InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: colors.card,
          shape: BoxShape.circle,
          border: Border.all(color: colors.border),
        ),
        child: Icon(Icons.settings_outlined, size: 17, color: colors.ink),
      ),
    );
  }
}

class _SectionBlock extends StatelessWidget {
  const _SectionBlock({
    required this.title,
    required this.subtitle,
    required this.child,
  });
  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = context.rcColors;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleMedium),
                Text(
                  subtitle,
                  style: Theme.of(
                    context,
                  ).textTheme.labelMedium?.copyWith(color: colors.inkMuted),
                ),
              ],
            ),
          ),
          child,
        ],
      ),
    );
  }
}

class _EmptyRow extends StatelessWidget {
  const _EmptyRow({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    final colors = context.rcColors;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(RcRadius.medium),
        border: Border.all(
          color: colors.borderStrong,
          style: BorderStyle.solid,
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        text,
        style: Theme.of(
          context,
        ).textTheme.bodyMedium?.copyWith(color: colors.inkMuted),
      ),
    );
  }
}

class _WeekEventCard extends StatelessWidget {
  const _WeekEventCard({
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
    final palette = event.type.paletteOf(context);
    final campaign = event.campaignId == null
        ? null
        : campaignById(event.campaignId!);
    return InkWell(
      onTap: campaign == null ? null : () => onOpenCampaign(campaign),
      borderRadius: BorderRadius.circular(RcRadius.medium),
      child: Container(
        width: 98,
        height: 108,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: colors.card,
          border: Border.all(color: colors.border),
          borderRadius: BorderRadius.circular(RcRadius.medium),
        ),
        child: Stack(
          children: [
            Positioned(
              top: -10,
              left: -10,
              right: -10,
              child: Container(height: 3, color: palette.ink),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      '${event.date.day}',
                      style: Theme.of(
                        context,
                      ).textTheme.headlineSmall?.copyWith(fontSize: 18),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      weekdayKo(event.date),
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: palette.soft,
                    borderRadius: BorderRadius.circular(RcRadius.pill),
                  ),
                  child: Text(
                    event.type.label,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: palette.ink,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Expanded(
                  child: Text(
                    event.label,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.type,
    required this.label,
    required this.value,
  });
  final CalendarEventType type;
  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    final colors = context.rcColors;
    final palette = type.paletteOf(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: colors.card,
        border: Border.all(color: colors.border),
        borderRadius: BorderRadius.circular(RcRadius.medium),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: palette.ink,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 5),
              Text(label, style: Theme.of(context).textTheme.labelMedium),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '$value',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontSize: 20),
          ),
        ],
      ),
    );
  }
}

class _HomeGoalPush extends StatelessWidget {
  const _HomeGoalPush({
    required this.goals,
    required this.current,
    required this.currentFee,
    required this.onGoRevenue,
  });
  final MonthlyRewardGoals goals;
  final int current;
  final int currentFee;
  final VoidCallback onGoRevenue;

  @override
  Widget build(BuildContext context) {
    final colors = context.rcColors;
    final hasTotal = goals.total > 0;
    final hasFee = goals.fee > 0;

    if (!hasTotal && !hasFee) {
      return InkWell(
        onTap: onGoRevenue,
        borderRadius: BorderRadius.circular(RcRadius.large),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colors.card,
            borderRadius: BorderRadius.circular(RcRadius.large),
            border: Border.all(color: colors.borderStrong),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '이번 달 목표가 없어요',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '수익 탭에서 총 수익·원고료 목표를 설정해보세요',
                      style: Theme.of(context).textTheme.labelMedium,
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
      );
    }

    return InkWell(
      onTap: onGoRevenue,
      borderRadius: BorderRadius.circular(RcRadius.large),
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
        decoration: BoxDecoration(
          color: colors.card,
          borderRadius: BorderRadius.circular(RcRadius.large),
          border: Border.all(color: colors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('이번 달 목표', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 10),
            if (hasTotal)
              _GoalPushRow(label: '총 수익', current: current, goal: goals.total),
            if (hasTotal && hasFee) const SizedBox(height: 16),
            if (hasFee)
              _GoalPushRow(label: '원고료', current: currentFee, goal: goals.fee),
          ],
        ),
      ),
    );
  }
}

class _GoalPushRow extends StatelessWidget {
  const _GoalPushRow({
    required this.label,
    required this.current,
    required this.goal,
  });
  final String label;
  final int current;
  final int goal;

  @override
  Widget build(BuildContext context) {
    final colors = context.rcColors;
    final pct = goal > 0 ? (current / goal * 100).clamp(0, 100).round() : 0;
    final remain = (goal - current).clamp(0, 1 << 31);
    final reached = pct >= 100;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            Text(
              '${formatNumber(current)} / ${formatWon(goal)}',
              style: Theme.of(context).textTheme.labelMedium,
            ),
          ],
        ),
        const SizedBox(height: 6),
        SizedBox(
          height: 34,
          child: LayoutBuilder(
            builder: (context, constraints) {
              // Mascot's *center* sits exactly on the fill's tip (JSX:
              // `left: calc(${pct}% - 15px)` with a 30px-wide mascot) —
              // not trailing behind it — so it visibly reaches the end.
              const mascotSize = 26.0;
              final trackWidth = constraints.maxWidth;
              final tipX = trackWidth * pct / 100;
              final mascotLeft = (tipX - mascotSize / 2).clamp(
                0.0,
                trackWidth - mascotSize,
              );
              return Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 6,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(RcRadius.pill),
                      child: Container(
                        height: 9,
                        color: colors.backgroundAlternative,
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: FractionallySizedBox(
                            widthFactor: pct / 100,
                            child: Container(color: colors.brand),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: mascotLeft,
                    bottom: 6,
                    child: const _MascotPush(),
                  ),
                ],
              );
            },
          ),
        ),
        const SizedBox(height: 2),
        Text(
          reached
              ? '$label 목표를 달성했어요! 대단해요'
              : '목표까지 ${formatWon(remain)} 남았어요, 영차영차',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.labelMedium,
        ),
      ],
    );
  }
}

/// Looping "영차영차" push wobble — mirrors design-system.jsx's
/// `@keyframes rcPush` (0%/100%: `translateY(0) rotate(-5deg)`, 50%:
/// `translateY(-3px) rotate(5deg)`, 0.6s ease-in-out infinite, pivoting from
/// the bottom center).
class _MascotPush extends StatefulWidget {
  const _MascotPush();

  @override
  State<_MascotPush> createState() => _MascotPushState();
}

class _MascotPushState extends State<_MascotPush>
    with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 300),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final brand = context.rcColors.brand;
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final t = Curves.easeInOut.transform(_controller.value);
        return Transform.translate(
          offset: Offset(0, -3 * t),
          child: Transform.rotate(
            angle: (-5 + 10 * t) * math.pi / 180,
            alignment: Alignment.bottomCenter,
            child: child,
          ),
        );
      },
      child: SizedBox(
        width: 26,
        height: 26,
        child: CustomPaint(painter: _MascotPainter(brand)),
      ),
    );
  }
}

class _MascotPainter extends CustomPainter {
  _MascotPainter(this.brand);
  final Color brand;

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / 30;
    canvas.scale(scale);
    final body = Paint()..color = brand;
    canvas.drawCircle(const Offset(14, 9), 6, body);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(8, 13, 12, 11),
        const Radius.circular(5.5),
      ),
      body,
    );
    canvas.drawLine(
      const Offset(6, 20),
      const Offset(1, 24),
      Paint()
        ..color = brand
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round,
    );
    final eye = Paint()..color = Colors.white;
    canvas.drawCircle(const Offset(11.5, 8), 1, eye);
    canvas.drawCircle(const Offset(16.5, 8), 1, eye);
    canvas.drawPath(
      Path()
        ..moveTo(11.5, 11.5)
        ..quadraticBezierTo(14, 13, 16.5, 11.5),
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant _MascotPainter oldDelegate) =>
      oldDelegate.brand != brand;
}
