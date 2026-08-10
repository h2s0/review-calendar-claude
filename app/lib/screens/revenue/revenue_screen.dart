import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:review_calendar/core/formatters.dart';
import 'package:review_calendar/data/review_calendar_models.dart';
import 'package:review_calendar/features/revenue/presentation/revenue_view_model.dart';
import 'package:review_calendar/ui/core/theme/rc_layout.dart';
import 'package:review_calendar/ui/core/theme/rc_theme.dart';

/// 수익 정리 — mirrors `screen-rest.jsx`'s `RevenueScreen`.
class RevenueScreen extends StatefulWidget {
  const RevenueScreen({
    required this.viewModel,
    required this.goals,
    required this.onGoalsChanged,
    super.key,
  });

  final RevenueViewModel viewModel;
  final MonthlyRewardGoals goals;
  final ValueChanged<MonthlyRewardGoals> onGoalsChanged;

  @override
  State<RevenueScreen> createState() => _RevenueScreenState();
}

class _RevenueScreenState extends State<RevenueScreen> {
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

  @override
  Widget build(BuildContext context) {
    final colors = context.rcColors;
    final r = widget.viewModel.summary;

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
                  Text('수익 정리', style: Theme.of(context).textTheme.bodySmall),
                  Text(
                    '${_today.year}년 ${_today.month}월',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
              child: Container(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
                decoration: BoxDecoration(
                  color: colors.brand,
                  borderRadius: BorderRadius.circular(RcRadius.extraLarge),
                  boxShadow: [
                    BoxShadow(
                      color: colors.brand.withValues(alpha: 0.25),
                      blurRadius: 18,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '이번 달 총 수익',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          formatNumber(r.total),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -1.5,
                          ),
                        ),
                        const Text(
                          ' 원',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '지난 달보다 +${formatWon(r.total - r.lastMonth)}',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 11.5,
                      ),
                    ),
                    Container(
                      margin: const EdgeInsets.only(top: 14),
                      padding: const EdgeInsets.only(top: 10),
                      decoration: const BoxDecoration(
                        border: Border(top: BorderSide(color: Colors.white24)),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  '협찬 (아낀 돈)',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  formatWon(r.sponsor),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 17,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            width: 1,
                            height: 30,
                            color: Colors.white24,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  '원고료 (번 돈)',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  formatWon(r.fee),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 17,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 8),
              child: Text(
                '월별 추이',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _MonthlyTrendChart(trend: r.trend),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 8),
              child: Text(
                '카테고리별',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 18,
                ),
                decoration: BoxDecoration(
                  color: colors.card,
                  borderRadius: BorderRadius.circular(RcRadius.large),
                  border: Border.all(color: colors.border),
                ),
                child: _CategoryDonut(data: r.byCategory, total: r.total),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MonthlyTrendChart extends StatefulWidget {
  const _MonthlyTrendChart({required this.trend});
  final List<MonthlyRevenue> trend;

  @override
  State<_MonthlyTrendChart> createState() => _MonthlyTrendChartState();
}

enum _Metric { all, sponsor, fee }

class _MonthlyTrendChartState extends State<_MonthlyTrendChart> {
  late int _activeIdx = widget.trend.length - 1;
  _Metric _metric = _Metric.all;

  int _valueOf(MonthlyRevenue t) => switch (_metric) {
    _Metric.sponsor => t.sponsor,
    _Metric.fee => t.fee,
    _Metric.all => t.total,
  };

  @override
  Widget build(BuildContext context) {
    final colors = context.rcColors;
    final trend = widget.trend;
    final max = trend.map(_valueOf).reduce((a, b) => a > b ? a : b);
    final active = trend[_activeIdx];
    final prev = _activeIdx > 0 ? trend[_activeIdx - 1] : null;
    final diff = prev == null ? null : _valueOf(active) - _valueOf(prev);
    final metricLabel = switch (_metric) {
      _Metric.sponsor => '협찬',
      _Metric.fee => '원고료',
      _Metric.all => '수익',
    };

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(RcRadius.large),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${active.month} $metricLabel',
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                    Text(
                      formatWon(_valueOf(active)),
                      style: Theme.of(
                        context,
                      ).textTheme.headlineSmall?.copyWith(fontSize: 20),
                    ),
                    if (diff != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              diff >= 0
                                  ? Icons.arrow_upward
                                  : Icons.arrow_downward,
                              size: 12,
                              color: diff >= 0
                                  ? colors.brandDeep
                                  : colors.deadline.ink,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              formatWon(diff.abs()),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: diff >= 0
                                    ? colors.brandDeep
                                    : colors.deadline.ink,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: colors.backgroundAlternative,
                  borderRadius: BorderRadius.circular(RcRadius.pill),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _metricButton('협찬', _Metric.sponsor),
                    _metricButton('원고료', _Metric.fee),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 96,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: trend.asMap().entries.map((entry) {
                final i = entry.key;
                final t = entry.value;
                final isActive = i == _activeIdx;
                final h = (_valueOf(t) / max * 82).clamp(6, 82).toDouble();
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 5),
                    child: InkWell(
                      onTap: () => setState(() => _activeIdx = i),
                      child: Align(
                        alignment: Alignment.bottomCenter,
                        child: Container(
                          height: h,
                          decoration: BoxDecoration(
                            color: isActive ? colors.brand : colors.brandTint,
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(7),
                              bottom: Radius.circular(2),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: trend
                .asMap()
                .entries
                .map(
                  (e) => Expanded(
                    child: Text(
                      e.value.month,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        color: e.key == _activeIdx
                            ? colors.ink
                            : colors.inkMuted,
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _metricButton(String label, _Metric metric) {
    final colors = context.rcColors;
    final on = _metric == metric;
    return InkWell(
      onTap: () => setState(() => _metric = on ? _Metric.all : metric),
      borderRadius: BorderRadius.circular(RcRadius.pill),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: on ? colors.card : Colors.transparent,
          borderRadius: BorderRadius.circular(RcRadius.pill),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: on ? colors.brandDeep : colors.inkSubtle,
          ),
        ),
      ),
    );
  }
}

class _CategoryDonut extends StatefulWidget {
  const _CategoryDonut({required this.data, required this.total});
  final List<CategoryRevenue> data;
  final int total;

  @override
  State<_CategoryDonut> createState() => _CategoryDonutState();
}

class _CategoryDonutState extends State<_CategoryDonut> {
  int? _activeIdx;

  void _toggle(int i) =>
      setState(() => _activeIdx = _activeIdx == i ? null : i);

  /// Hit-tests a tap inside the 140x140 donut against its arc segments —
  /// mirrors the JSX where each `<circle>` arc has its own `onClick`.
  void _handleTap(Offset local) {
    const center = Offset(70, 70);
    const outerRadius = 70.0;
    const stroke = 22.0;
    final dist = (local - center).distance;
    if (dist < outerRadius - stroke - 4 || dist > outerRadius + 4) return;
    var angle =
        math.atan2(local.dy - center.dy, local.dx - center.dx) + math.pi / 2;
    if (angle < 0) angle += 2 * math.pi;
    final pct = angle / (2 * math.pi) * 100;
    var cumulative = 0.0;
    for (var i = 0; i < widget.data.length; i++) {
      cumulative += widget.data[i].pct;
      if (pct <= cumulative) {
        _toggle(i);
        return;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.rcColors;
    final active = _activeIdx == null ? null : widget.data[_activeIdx!];
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: 140,
          height: 140,
          child: Stack(
            alignment: Alignment.center,
            children: [
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTapUp: (details) => _handleTap(details.localPosition),
                child: CustomPaint(
                  size: const Size(140, 140),
                  painter: _DonutPainter(
                    data: widget.data,
                    activeIdx: _activeIdx,
                    trackColor: colors.backgroundAlternative,
                  ),
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    active?.name ?? '총합',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: colors.inkSubtle,
                    ),
                  ),
                  Text(
                    formatNumber(active?.amount ?? widget.total),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: colors.ink,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: widget.data.asMap().entries.map((entry) {
              final i = entry.key;
              final c = entry.value;
              final dim = _activeIdx != null && _activeIdx != i;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: InkWell(
                  onTap: () => _toggle(i),
                  child: Opacity(
                    opacity: dim ? 0.4 : 1,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: c.color,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              c.name,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: colors.ink,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          '${c.pct}%',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: colors.inkSubtle,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

class _DonutPainter extends CustomPainter {
  _DonutPainter({
    required this.data,
    required this.activeIdx,
    required this.trackColor,
  });
  final List<CategoryRevenue> data;
  final int? activeIdx;
  final Color trackColor;

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 22.0;
    final center = size.center(Offset.zero);
    final radius = (size.width - stroke) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    canvas.drawArc(
      rect,
      0,
      2 * math.pi,
      false,
      Paint()
        ..color = trackColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke,
    );

    var startAngle = -math.pi / 2;
    for (var i = 0; i < data.length; i++) {
      final sweep = data[i].pct / 100 * 2 * math.pi;
      final dim = activeIdx != null && activeIdx != i;
      canvas.drawArc(
        rect,
        startAngle,
        sweep,
        false,
        Paint()
          ..color = dim ? data[i].color.withValues(alpha: 0.35) : data[i].color
          ..style = PaintingStyle.stroke
          ..strokeWidth = activeIdx == i ? stroke + 4 : stroke
          ..strokeCap = StrokeCap.butt,
      );
      startAngle += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutPainter oldDelegate) =>
      oldDelegate.activeIdx != activeIdx || oldDelegate.data != data;
}
