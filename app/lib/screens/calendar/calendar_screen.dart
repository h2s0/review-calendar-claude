import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:review_calendar/core/formatters.dart';
import 'package:review_calendar/core/month_grid.dart';
import 'package:review_calendar/data/review_calendar_models.dart';
import 'package:review_calendar/features/calendar/presentation/calendar_view_model.dart';
import 'package:review_calendar/ui/core/dashed_border.dart';
import 'package:review_calendar/ui/core/event_palette.dart';
import 'package:review_calendar/ui/core/icons/rc_icons.dart';
import 'package:review_calendar/ui/core/theme/rc_layout.dart';
import 'package:review_calendar/ui/core/theme/rc_theme.dart';

/// Main calendar screen — mirrors `screen-calendar.jsx`'s `MainCalendar`.
class CalendarScreen extends StatefulWidget {
  const CalendarScreen({
    required this.viewModel,
    required this.onOpenCampaign,
    super.key,
  });

  final CalendarViewModel viewModel;
  final ValueChanged<Campaign> onOpenCampaign;

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  late final _today = DateTime.now();
  late int _viewYear = _today.year;
  late int _viewMonth = _today.month;
  late DateTime _selectedDate = _today;
  // Campaigns resolved via the undecided-strip tap flow, hidden locally as
  // an optimistic update while `confirmVisitDate` writes the real
  // `visit.date` back through the repository — reverted if that write
  // fails, otherwise made redundant (harmlessly) once the next snapshot
  // excludes the campaign from `undecided` for real.
  final Set<String> _locallyResolvedIds = {};
  String? _selectingId;
  String? _justResolvedText;

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

  void _goPrevMonth() {
    setState(() {
      if (_viewMonth == 1) {
        _viewMonth = 12;
        _viewYear -= 1;
      } else {
        _viewMonth -= 1;
      }
    });
  }

  void _goNextMonth() {
    setState(() {
      if (_viewMonth == 12) {
        _viewMonth = 1;
        _viewYear += 1;
      } else {
        _viewMonth += 1;
      }
    });
  }

  void _handleCellTap(DateTime date, bool inWindow) async {
    if (inWindow && _selectingId != null) {
      final item = widget.viewModel.undecided.firstWhere(
        (u) => u.id == _selectingId,
      );
      final resolvingId = _selectingId!;
      setState(() {
        _locallyResolvedIds.add(resolvingId);
        _justResolvedText =
            '${item.brand} 방문일을 ${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')}로 확정했어요';
        _selectingId = null;
      });
      final success = await widget.viewModel.confirmVisitDate(
        campaignId: item.campaignId,
        date: date,
      );
      if (!mounted) return;
      if (!success) {
        setState(() {
          _locallyResolvedIds.remove(resolvingId);
          _justResolvedText = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('방문일을 저장하지 못했어요. 다시 시도해 주세요.')),
        );
        return;
      }
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) setState(() => _justResolvedText = null);
      });
      return;
    }
    setState(() => _selectedDate = date);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.rcColors;
    final cells = buildMonthGrid(_viewYear, _viewMonth);
    final undecided = widget.viewModel.undecided
        .where((u) => !_locallyResolvedIds.contains(u.id))
        .toList();
    final monthEvents = widget.viewModel.events
        .where((e) => e.date.year == _viewYear && e.date.month == _viewMonth)
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
    final selectingItem = _selectingId == null
        ? null
        : undecided.firstWhere((u) => u.id == _selectingId);

    return ColoredBox(
      color: colors.background,
      child: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.only(bottom: 120),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
              child: Text(
                '리뷰캘린더',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            '$_viewYear.${_viewMonth.toString().padLeft(2, '0')}',
                            style: Theme.of(
                              context,
                            ).textTheme.headlineSmall?.copyWith(fontSize: 26),
                          ),
                          const SizedBox(width: 6),
                          _TodayPill(
                            onTap: () => setState(() {
                              _viewYear = _today.year;
                              _viewMonth = _today.month;
                            }),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          _NavCircleButton(
                            glyph: RcIconGlyph.chevronLeft,
                            onTap: _goPrevMonth,
                          ),
                          const SizedBox(width: 6),
                          _NavCircleButton(
                            glyph: RcIconGlyph.chevronRight,
                            onTap: _goNextMonth,
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      _StatChip(
                        type: CalendarEventType.visit,
                        label: '방문',
                        count: visitCount,
                      ),
                      _StatChip(
                        type: CalendarEventType.deadline,
                        label: '마감',
                        count: deadlineCount,
                      ),
                      _StatChip(
                        type: CalendarEventType.posted,
                        label: '발행',
                        count: postedCount,
                      ),
                      _StatChip(
                        type: CalendarEventType.idea,
                        label: '미정',
                        count: undecided.length,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (undecided.isNotEmpty)
              _UndecidedStrip(
                items: undecided,
                selectingId: _selectingId,
                onToggle: (id) => setState(
                  () => _selectingId = _selectingId == id ? null : id,
                ),
              ),
            if (_justResolvedText != null)
              Container(
                margin: const EdgeInsets.fromLTRB(12, 10, 12, 0),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: colors.posted.soft,
                  border: Border.all(color: colors.posted.chip),
                  borderRadius: BorderRadius.circular(RcRadius.medium),
                ),
                child: Text(
                  _justResolvedText!,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: colors.posted.ink,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            GestureDetector(
              onHorizontalDragEnd: (details) {
                final v = details.primaryVelocity ?? 0;
                if (v < -200) {
                  _goNextMonth();
                } else if (v > 200) {
                  _goPrevMonth();
                }
              },
              child: Container(
                margin: const EdgeInsets.fromLTRB(12, 10, 12, 0),
                decoration: BoxDecoration(
                  color: colors.card,
                  borderRadius: BorderRadius.circular(RcRadius.large),
                  border: Border.all(color: colors.border),
                ),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  children: [
                    Row(
                      children: List.generate(7, (i) {
                        const dow = ['일', '월', '화', '수', '목', '금', '토'];
                        final color = i == 0
                            ? const Color(0xFFC25E5E)
                            : i == 6
                            ? const Color(0xFF5980B8)
                            : colors.inkSubtle;
                        return Expanded(
                          child: Container(
                            alignment: Alignment.center,
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              border: Border(
                                bottom: BorderSide(color: colors.border),
                              ),
                            ),
                            child: Text(
                              dow[i],
                              style: Theme.of(
                                context,
                              ).textTheme.labelSmall?.copyWith(color: color),
                            ),
                          ),
                        );
                      }),
                    ),
                    GridView.builder(
                      padding: EdgeInsets.zero,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: cells.length,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 7,
                            mainAxisExtent: 84,
                          ),
                      itemBuilder: (context, i) {
                        final cell = cells[i];
                        final inWindow =
                            selectingItem != null &&
                            !cell.outside &&
                            !cell.date.isBefore(
                              selectingItem.visitWindow.start,
                            ) &&
                            !cell.date.isAfter(selectingItem.visitWindow.end);
                        return _CalendarCell(
                          key: ValueKey(cell.date),
                          index: i,
                          cell: cell,
                          isToday: isSameDay(cell.date, _today),
                          isSelected: isSameDay(cell.date, _selectedDate),
                          inWindow: inWindow,
                          events: widget.viewModel.eventsOn(cell.date),
                          campaignById: widget.viewModel.campaignById,
                          onTap: () => _handleCellTap(cell.date, inWindow),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: _SelectedDayPanel(
                date: _selectedDate,
                events: widget.viewModel.eventsOn(_selectedDate),
                campaignById: widget.viewModel.campaignById,
                onOpenCampaign: widget.onOpenCampaign,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TodayPill extends StatelessWidget {
  const _TodayPill({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.rcColors;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(RcRadius.pill),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: colors.brandSoft,
          borderRadius: BorderRadius.circular(RcRadius.pill),
        ),
        child: Text(
          '오늘',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: colors.brandDeep,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _NavCircleButton extends StatelessWidget {
  const _NavCircleButton({required this.glyph, required this.onTap});
  final RcIconGlyph glyph;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.rcColors;
    return InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: colors.card,
          shape: BoxShape.circle,
          border: Border.all(color: colors.border),
        ),
        child: Center(child: RcIcon(glyph, size: 16, color: colors.ink)),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.type,
    required this.label,
    required this.count,
  });
  final CalendarEventType type;
  final String label;
  final int count;

  @override
  Widget build(BuildContext context) {
    final palette = type.paletteOf(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(9, 5, 10, 5),
      decoration: BoxDecoration(
        color: palette.soft,
        borderRadius: BorderRadius.circular(RcRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
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
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.labelMedium?.copyWith(color: palette.ink),
          ),
          const SizedBox(width: 2),
          Text(
            '$count',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: palette.ink,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

/// One rotate+scale keyframe of the "wobble" — mirrors design-system.jsx's
/// `@keyframes rcCellWobble`.
class _WobbleKeyframe {
  const _WobbleKeyframe(this.t, this.rotationDeg, this.scale);
  final double t;
  final double rotationDeg;
  final double scale;
}

const _wobbleKeyframes = [
  _WobbleKeyframe(0, 0, 1.06),
  _WobbleKeyframe(0.2, -4, 1.08),
  _WobbleKeyframe(0.4, 3, 1.08),
  _WobbleKeyframe(0.6, -2, 1.07),
  _WobbleKeyframe(0.8, 1.5, 1.06),
  _WobbleKeyframe(1, 0, 1.06),
];

({double rotation, double scale}) _wobbleAt(double t) {
  for (var i = 0; i < _wobbleKeyframes.length - 1; i++) {
    final a = _wobbleKeyframes[i];
    final b = _wobbleKeyframes[i + 1];
    if (t >= a.t && t <= b.t) {
      final localT = b.t == a.t ? 0.0 : (t - a.t) / (b.t - a.t);
      final deg = a.rotationDeg + (b.rotationDeg - a.rotationDeg) * localT;
      final scale = a.scale + (b.scale - a.scale) * localT;
      return (rotation: deg * math.pi / 180, scale: scale);
    }
  }
  return (rotation: 0, scale: 1.06);
}

class _CalendarCell extends StatefulWidget {
  const _CalendarCell({
    super.key,
    required this.index,
    required this.cell,
    required this.isToday,
    required this.isSelected,
    required this.inWindow,
    required this.events,
    required this.campaignById,
    required this.onTap,
  });

  final int index;
  final MonthCell cell;
  final bool isToday;
  final bool isSelected;
  final bool inWindow;
  final List<CalendarEvent> events;
  final Campaign? Function(String id) campaignById;
  final VoidCallback onTap;

  @override
  State<_CalendarCell> createState() => _CalendarCellState();
}

class _CalendarCellState extends State<_CalendarCell>
    with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 500),
  );

  @override
  void didUpdateWidget(covariant _CalendarCell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.inWindow && !oldWidget.inWindow) {
      final delayMs = (widget.index * 30).clamp(0, 300);
      _controller.value = 0;
      Future.delayed(Duration(milliseconds: delayMs), () {
        if (mounted) _controller.forward(from: 0);
      });
    } else if (!widget.inWindow && oldWidget.inWindow) {
      _controller.stop();
      _controller.value = 0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        if (!widget.inWindow || _controller.value == 0) return child!;
        final wobble = _wobbleAt(_controller.value);
        return Transform.scale(
          scale: wobble.scale,
          child: Transform.rotate(angle: wobble.rotation, child: child),
        );
      },
      child: _CalendarCellContent(
        cell: widget.cell,
        isToday: widget.isToday,
        isSelected: widget.isSelected,
        inWindow: widget.inWindow,
        events: widget.events,
        campaignById: widget.campaignById,
        onTap: widget.onTap,
      ),
    );
  }
}

class _CalendarCellContent extends StatelessWidget {
  const _CalendarCellContent({
    required this.cell,
    required this.isToday,
    required this.isSelected,
    required this.inWindow,
    required this.events,
    required this.campaignById,
    required this.onTap,
  });

  final MonthCell cell;
  final bool isToday;
  final bool isSelected;
  final bool inWindow;
  final List<CalendarEvent> events;
  final Campaign? Function(String id) campaignById;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.rcColors;
    final deadlineEvents = events
        .where((e) => e.type == CalendarEventType.deadline)
        .toList();
    final chipEvents = events
        .where(
          (e) =>
              e.type != CalendarEventType.deadline &&
              e.type != CalendarEventType.posted,
        )
        .toList();
    final hasPosted = events.any((e) => e.type == CalendarEventType.posted);
    final dow = cell.date.weekday % 7;
    final dayColor = cell.outside
        ? colors.inkMuted
        : dow == 0
        ? const Color(0xFFC25E5E)
        : dow == 6
        ? const Color(0xFF5980B8)
        : colors.ink;

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.fromLTRB(3, 4, 3, 3),
        decoration: BoxDecoration(
          color: inWindow
              ? colors.visit.soft
              : isSelected
              ? colors.brandSoft
              : Colors.transparent,
          border: Border(
            top: BorderSide(color: colors.border),
            left: BorderSide(color: colors.border),
          ),
        ),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 18,
                      height: 18,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: isToday ? colors.brand : Colors.transparent,
                        shape: BoxShape.circle,
                      ),
                      child: Opacity(
                        opacity: cell.outside ? 0.35 : 1,
                        child: Text(
                          '${cell.date.day}',
                          style: Theme.of(context).textTheme.labelMedium
                              ?.copyWith(
                                color: isToday ? Colors.white : dayColor,
                                fontWeight: isToday
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                              ),
                        ),
                      ),
                    ),
                    if (!cell.outside && hasPosted) ...[
                      const SizedBox(width: 3),
                      Container(
                        width: 5,
                        height: 5,
                        decoration: BoxDecoration(
                          color: colors.posted.ink,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ],
                ),
                if (!cell.outside && chipEvents.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        for (final e in chipEvents.take(2))
                          Container(
                            margin: const EdgeInsets.only(top: 2),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 4,
                              vertical: 1,
                            ),
                            decoration: BoxDecoration(
                              color: e.type.paletteOf(context).soft,
                              borderRadius: BorderRadius.circular(4),
                              border: Border(
                                left: BorderSide(
                                  color: e.type.paletteOf(context).ink,
                                  width: 2,
                                ),
                              ),
                            ),
                            child: Text(
                              e.label,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 8.5,
                                fontWeight: FontWeight.w600,
                                letterSpacing: -0.2,
                                height: 1.2,
                                color: e.type.paletteOf(context).ink,
                              ),
                            ),
                          ),
                        if (chipEvents.length > 2)
                          Padding(
                            padding: const EdgeInsets.only(top: 1, left: 3),
                            child: Text(
                              '+${chipEvents.length - 2}',
                              style: TextStyle(
                                fontSize: 8,
                                color: colors.inkMuted,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                if (!cell.outside && deadlineEvents.isNotEmpty) ...[
                  const Spacer(),
                  _DeadlineFooter(
                    event: deadlineEvents.first,
                    campaignById: campaignById,
                  ),
                ],
              ],
            ),
            if (!cell.outside && deadlineEvents.isNotEmpty)
              Positioned(
                right: 0,
                bottom: 0,
                child: SizedBox(
                  width: 11,
                  height: 11,
                  child: CustomPaint(
                    painter: _DeadlineCornerBracket(colors.deadline.ink),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Bottom-right "⌐" corner accent on deadline cells — `borderBottom` +
/// `borderRight` of an 11x11 box in screen-calendar.jsx.
class _DeadlineCornerBracket extends CustomPainter {
  _DeadlineCornerBracket(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(
      Path()
        ..moveTo(size.width, 0)
        ..lineTo(size.width, size.height)
        ..lineTo(0, size.height),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _DeadlineCornerBracket oldDelegate) =>
      oldDelegate.color != color;
}

/// Brand name + done/undone indicator row under a deadline cell.
class _DeadlineFooter extends StatelessWidget {
  const _DeadlineFooter({required this.event, required this.campaignById});
  final CalendarEvent event;
  final Campaign? Function(String id) campaignById;

  @override
  Widget build(BuildContext context) {
    final colors = context.rcColors;
    final campaign = event.campaignId == null
        ? null
        : campaignById(event.campaignId!);
    final done = campaign?.posted != null;
    final brandShort = campaign?.brand ?? event.label;
    return Padding(
      padding: const EdgeInsets.fromLTRB(2, 2, 4, 1),
      child: Row(
        children: [
          Expanded(
            child: Text(
              brandShort,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 8,
                fontWeight: FontWeight.w600,
                color: done ? colors.inkMuted : colors.deadline.ink,
              ),
            ),
          ),
          const SizedBox(width: 2),
          // O/X 표기 — 발행 완료면 빨간 동그라미, 아직이면 빨간 엑스.
          if (done)
            Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: colors.deadline.ink, width: 1.3),
              ),
            )
          else
            Icon(Icons.close, size: 8, color: colors.deadline.ink),
        ],
      ),
    );
  }
}

class _UndecidedStrip extends StatelessWidget {
  const _UndecidedStrip({
    required this.items,
    required this.selectingId,
    required this.onToggle,
  });
  final List<UndecidedVisit> items;
  final String? selectingId;
  final ValueChanged<String> onToggle;

  @override
  Widget build(BuildContext context) {
    final colors = context.rcColors;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
      child: DashedBorderBox(
        color: colors.border,
        background: colors.card,
        radius: RcRadius.large,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  RcIcon(RcIconGlyph.clock, size: 12, color: colors.inkSubtle),
                  const SizedBox(width: 6),
                  Text(
                    '미정 일정 · ${items.length}',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '· 탭해서 방문일 정하기',
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 56,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: items.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 6),
                  itemBuilder: (context, i) {
                    final item = items[i];
                    final active = selectingId == item.id;
                    final hasDate = item.visit.date != null;
                    final dateLabel = hasDate
                        ? '${item.visit.date!.month}.${item.visit.date!.day} · 시간 미정'
                        : '방문일 미정';
                    return InkWell(
                      onTap: () => onToggle(item.id),
                      borderRadius: BorderRadius.circular(RcRadius.medium),
                      child: SizedBox(
                        width: 150,
                        child: DashedBorderBox(
                          color: active ? colors.visit.ink : colors.inkMuted,
                          background: active
                              ? colors.visit.soft
                              : colors.backgroundAlternative,
                          radius: RcRadius.medium,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 8,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  item.brand,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context).textTheme.bodyMedium
                                      ?.copyWith(fontWeight: FontWeight.w700),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  active ? '날짜를 선택해주세요 ↓' : dateLabel,
                                  style: Theme.of(context).textTheme.labelSmall
                                      ?.copyWith(
                                        color: active
                                            ? colors.visit.ink
                                            : colors.inkSubtle,
                                        fontStyle: FontStyle.italic,
                                      ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SelectedDayPanel extends StatelessWidget {
  const _SelectedDayPanel({
    required this.date,
    required this.events,
    required this.campaignById,
    required this.onOpenCampaign,
  });
  final DateTime date;
  final List<CalendarEvent> events;
  final Campaign? Function(String id) campaignById;
  final ValueChanged<Campaign> onOpenCampaign;

  @override
  Widget build(BuildContext context) {
    final colors = context.rcColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 0, 4, 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '${monthDayLabel(date)} ${weekdayKo(date)}요일',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              Text(
                events.isEmpty ? '일정 없음' : '${events.length}건의 일정',
                style: Theme.of(context).textTheme.labelMedium,
              ),
            ],
          ),
        ),
        if (events.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 24),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: colors.card,
              borderRadius: BorderRadius.circular(RcRadius.large),
              border: Border.all(color: colors.borderStrong),
            ),
            child: Text(
              '이 날은 일정이 없어요',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: colors.inkMuted),
            ),
          )
        else
          Column(
            children: events
                .map(
                  (ev) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _EventRow(
                      event: ev,
                      campaignById: campaignById,
                      onOpenCampaign: onOpenCampaign,
                    ),
                  ),
                )
                .toList(),
          ),
      ],
    );
  }
}

class _EventRow extends StatelessWidget {
  const _EventRow({
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
      borderRadius: BorderRadius.circular(RcRadius.large),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: colors.card,
          border: Border.all(color: colors.border),
          borderRadius: BorderRadius.circular(RcRadius.large),
        ),
        child: Row(
          children: [
            Container(width: 3, height: 40, color: palette.ink),
            const SizedBox(width: 10),
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: palette.soft,
                borderRadius: BorderRadius.circular(RcRadius.medium),
              ),
              child: Center(
                child: RcIcon(
                  switch (event.type) {
                    CalendarEventType.visit => RcIconGlyph.pin,
                    CalendarEventType.deadline => RcIconGlyph.clock,
                    _ => RcIconGlyph.check,
                  },
                  size: 18,
                  color: palette.ink,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        event.type.label,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: palette.ink,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (campaign != null) ...[
                        const SizedBox(width: 6),
                        Text(
                          '· ${campaign.platform}',
                          style: Theme.of(context).textTheme.labelSmall,
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 3),
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
                        '${campaign.reward.type.label} · ${formatWon(campaign.reward.amount)}',
                        style: Theme.of(context).textTheme.labelMedium,
                      ),
                    ),
                ],
              ),
            ),
            if (campaign != null)
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
}
