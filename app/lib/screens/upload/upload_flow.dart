import 'dart:async';

import 'package:flutter/material.dart';
import 'package:review_calendar/core/formatters.dart';
import 'package:review_calendar/core/month_grid.dart';
import 'package:review_calendar/data/mock_review_calendar_data.dart';
import 'package:review_calendar/data/review_calendar_models.dart';
import 'package:review_calendar/features/campaign/data/campaign_repository.dart';
import 'package:review_calendar/features/notification/domain/notification_device_registration.dart';
import 'package:review_calendar/features/notification/presentation/notification_permission_prompt.dart';
import 'package:review_calendar/features/registration/data/apple_vision_campaign_ocr_engine.dart';
import 'package:review_calendar/features/registration/data/device_registration_image_source.dart';
import 'package:review_calendar/features/registration/domain/campaign_registration_draft.dart';
import 'package:review_calendar/features/registration/domain/local_campaign_ocr.dart';
import 'package:review_calendar/features/registration/domain/registration_image.dart';
import 'package:review_calendar/features/registration/presentation/registration_view_model.dart';
import 'package:review_calendar/ui/core/dashed_border.dart';
import 'package:review_calendar/ui/core/icons/rc_icons.dart';
import 'package:review_calendar/ui/core/theme/rc_layout.dart';
import 'package:review_calendar/ui/core/theme/rc_theme.dart';

enum _Step { select, analyzing, confirm, manual }

/// 스크린샷 자동 등록 — mirrors `screen-upload.jsx`'s `UploadFlow`.
class UploadFlow extends StatefulWidget {
  const UploadFlow({
    required this.categories,
    required this.campaignRepository,
    required this.ownerId,
    this.notificationRegistration,
    this.imageSource,
    this.analysisService,
    super.key,
  });
  final List<String> categories;
  final CampaignRepository campaignRepository;
  final String ownerId;
  final NotificationDeviceRegistrationController? notificationRegistration;
  // Both default to the real device/Vision-backed implementations; tests
  // inject fakes instead of touching the image_picker or native OCR
  // platform channels.
  final RegistrationImageSource? imageSource;
  final LocalCampaignAnalysisService? analysisService;

  @override
  State<UploadFlow> createState() => _UploadFlowState();
}

class _UploadFlowState extends State<UploadFlow> {
  _Step _step = _Step.select;
  double _progress = 0;
  Timer? _timer;
  CampaignRegistrationDraft? _analysisDraft;
  late final RegistrationImageSource _imageSource =
      widget.imageSource ?? DeviceRegistrationImageSource();
  late final LocalCampaignAnalysisService _analysisService =
      widget.analysisService ??
      const OcrCampaignAnalysisService(AppleVisionCampaignOcrEngine());

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  /// "갤러리에서 선택" — picks screenshots, then runs real on-device OCR
  /// (`OcrCampaignAnalysisService`/Apple Vision) over them. A cancelled or
  /// empty picker selection is a silent no-op, matching how gallery pickers
  /// normally behave.
  Future<void> _pickAndAnalyze() async {
    List<RegistrationImageCandidate> candidates;
    try {
      candidates = await _imageSource.pickGallery(
        limit: registrationImageLimit,
      );
    } catch (_) {
      candidates = const [];
    }
    if (candidates.isEmpty) return;

    final images = <RegistrationImage>[];
    for (final candidate in candidates) {
      try {
        images.add(
          RegistrationImage(
            id: candidate.id,
            name: candidate.name,
            bytes: await candidate.readBytes(),
            mimeType: candidate.mimeType,
          ),
        );
      } catch (_) {
        // Skip an unreadable image rather than failing the whole batch.
      }
    }
    if (images.isEmpty || !mounted) return;
    _startAnalyzing(images);
  }

  void _startAnalyzing(List<RegistrationImage> images) {
    setState(() {
      _step = _Step.analyzing;
      _progress = 0;
      _analysisDraft = null;
    });

    // The staged progress bar is a "working…" affordance running alongside
    // the real analysis below — the step transition is driven by the real
    // Future resolving, not by the animation reaching its last stage.
    const stages = [30.0, 65.0, 92.0];
    var idx = 0;
    void tick() {
      if (idx >= stages.length) return;
      setState(() => _progress = stages[idx]);
      _timer = Timer(const Duration(milliseconds: 550), () {
        idx++;
        tick();
      });
    }

    tick();

    _analysisService
        .analyze(images)
        .then((result) {
          _timer?.cancel();
          if (!mounted) return;
          setState(() {
            _progress = 100;
            _analysisDraft = result.toRegistrationDraft();
          });
          Future.delayed(const Duration(milliseconds: 350), () {
            if (mounted) setState(() => _step = _Step.confirm);
          });
        })
        .catchError((Object _) {
          _timer?.cancel();
          if (!mounted) return;
          setState(() => _step = _Step.manual);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('분석에 실패했어요. 직접 입력해 주세요.')),
          );
        });
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.rcColors;
    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: Column(
          children: [
            if (_step != _Step.manual) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _CircleButton(
                      glyph: RcIconGlyph.close,
                      onTap: () => Navigator.of(context).maybePop(),
                    ),
                    Text(
                      '스크린샷 자동 등록',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 36),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                child: Row(
                  children: [_Step.select, _Step.analyzing, _Step.confirm].map((
                    s,
                  ) {
                    final order = [
                      _Step.select,
                      _Step.analyzing,
                      _Step.confirm,
                    ];
                    final active = order.indexOf(_step) >= order.indexOf(s);
                    return Expanded(
                      child: Container(
                        height: 3,
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        decoration: BoxDecoration(
                          color: active ? colors.brand : colors.brandTint,
                          borderRadius: BorderRadius.circular(RcRadius.pill),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
            Expanded(
              child: switch (_step) {
                _Step.select => _StepSelect(
                  onPick: () => unawaited(_pickAndAnalyze()),
                  onManual: () => setState(() => _step = _Step.manual),
                ),
                _Step.analyzing => _StepAnalyzing(progress: _progress),
                _Step.confirm => _StepConfirm(
                  mode: _Mode.ai,
                  categories: widget.categories,
                  campaignRepository: widget.campaignRepository,
                  ownerId: widget.ownerId,
                  notificationRegistration: widget.notificationRegistration,
                  initialDraft: _analysisDraft,
                  onConfirm: () => Navigator.of(context).maybePop(),
                ),
                _Step.manual => _StepConfirm(
                  mode: _Mode.manual,
                  categories: widget.categories,
                  campaignRepository: widget.campaignRepository,
                  ownerId: widget.ownerId,
                  notificationRegistration: widget.notificationRegistration,
                  onConfirm: () => Navigator.of(context).maybePop(),
                  onBack: () => setState(() => _step = _Step.select),
                ),
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _CircleButton extends StatelessWidget {
  const _CircleButton({required this.glyph, required this.onTap});
  final RcIconGlyph glyph;
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
        child: Center(child: RcIcon(glyph, size: 16, color: colors.ink)),
      ),
    );
  }
}

class _StepSelect extends StatelessWidget {
  const _StepSelect({required this.onPick, required this.onManual});
  final VoidCallback onPick;
  final VoidCallback onManual;

  @override
  Widget build(BuildContext context) {
    final colors = context.rcColors;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
      children: [
        Text(
          '스크린샷만 올리면\n자동으로 정리해드려요',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 6),
        Text(
          '당첨 문자, 신청 화면, 공고 이미지 등\n어떤 형태든 인식할 수 있어요',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 20),
        InkWell(
          onTap: onPick,
          borderRadius: BorderRadius.circular(RcRadius.extraLarge),
          child: DashedBorderBox(
            color: colors.brand,
            background: colors.brandSoft,
            radius: RcRadius.extraLarge,
            strokeWidth: 2,
            dashWidth: 6,
            gapWidth: 4,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: Column(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: RcIcon(
                        RcIconGlyph.image,
                        size: 26,
                        color: colors.brand,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    '갤러리에서 선택',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: colors.brandDeep,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '여러 장 한번에 업로드 가능',
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        InkWell(
          onTap: onManual,
          borderRadius: BorderRadius.circular(RcRadius.large),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              color: colors.card,
              border: Border.all(color: colors.border),
              borderRadius: BorderRadius.circular(RcRadius.large),
            ),
            child: Column(
              children: [
                RcIcon(RcIconGlyph.edit, size: 20, color: colors.brand),
                const SizedBox(height: 6),
                Text(
                  '직접 입력',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: colors.ink,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 18),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: colors.card,
            borderRadius: BorderRadius.circular(RcRadius.large),
            border: Border.all(color: colors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '자동으로 인식하는 정보',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: colors.brandDeep,
                  letterSpacing: 0.4,
                ),
              ),
              const SizedBox(height: 6),
              for (final row in const [
                ('업체명', '가게·상품 이름'),
                ('방문 날짜', '캠페인 기간'),
                ('마감일', '포스팅 마감'),
                ('플랫폼', '레뷰·디너의여왕 등'),
              ])
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 5),
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(color: colors.border, width: 0.5),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        row.$1,
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: colors.ink,
                        ),
                      ),
                      Text(
                        row.$2,
                        style: TextStyle(
                          fontSize: 12.5,
                          color: colors.inkSubtle,
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
}

class _StepAnalyzing extends StatelessWidget {
  const _StepAnalyzing({required this.progress});
  final double progress;

  @override
  Widget build(BuildContext context) {
    final colors = context.rcColors;
    final message = progress < 40
        ? '이미지를 분석하는 중…'
        : progress < 80
        ? '날짜와 업체 정보를 추출하는 중…'
        : '정보를 정리하는 중…';
    final checklist = [
      ('업체명 인식', 25.0),
      ('방문 가능 날짜', 55.0),
      ('포스팅 마감일', 80.0),
      ('플랫폼 분류', 95.0),
    ];

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
      children: [
        Center(
          child: Container(
            width: 190,
            margin: const EdgeInsets.symmetric(vertical: 8),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: colors.card,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: colors.border),
            ),
            child: AspectRatio(
              aspectRatio: 9 / 16,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '[레뷰] 체험단 당첨 안내',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: colors.ink,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '안녕하세요. 르봉 파스타바 성수점 체험단에 당첨되셨습니다.\n\n'
                    '▪ 방문기간: 4/18 ~ 4/28\n▪ 리뷰마감: 5/2 까지\n▪ 제공내역: 2인 식사\n▪ 필수항목: 영수증 리뷰',
                    style: TextStyle(
                      fontSize: 8.5,
                      color: colors.inkSubtle,
                      height: 1.6,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          '내용을 읽고 있어요',
          textAlign: TextAlign.center,
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontSize: 20),
        ),
        const SizedBox(height: 6),
        Text(
          message,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 18),
        Center(
          child: SizedBox(
            width: MediaQuery.of(context).size.width * 0.6,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(RcRadius.pill),
              child: LinearProgressIndicator(
                value: progress / 100,
                minHeight: 6,
                backgroundColor: colors.brandTint,
                color: colors.brand,
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
        for (final row in checklist)
          Opacity(
            opacity: progress >= row.$2 ? 1 : 0.4,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: progress >= row.$2
                          ? colors.brand
                          : Colors.transparent,
                      shape: BoxShape.circle,
                      border: progress >= row.$2
                          ? null
                          : Border.all(color: colors.borderStrong, width: 1.5),
                    ),
                    child: progress >= row.$2
                        ? const Icon(Icons.check, size: 12, color: Colors.white)
                        : null,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    row.$1,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: colors.ink,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

enum _Mode { ai, manual }

class _StepConfirm extends StatefulWidget {
  const _StepConfirm({
    required this.mode,
    required this.categories,
    required this.campaignRepository,
    required this.ownerId,
    required this.onConfirm,
    this.notificationRegistration,
    this.initialDraft,
    this.onBack,
  });

  final _Mode mode;
  final List<String> categories;
  final CampaignRepository campaignRepository;
  final String ownerId;
  final NotificationDeviceRegistrationController? notificationRegistration;
  // AI-mode pre-fill from real on-device OCR (`_pickAndAnalyze`); null in
  // manual mode, where every field starts blank/at its baseline default.
  final CampaignRegistrationDraft? initialDraft;
  final VoidCallback onConfirm;
  final VoidCallback? onBack;

  @override
  State<_StepConfirm> createState() => _StepConfirmState();
}

class _StepConfirmState extends State<_StepConfirm> {
  late final TextEditingController _brandController;
  late final TextEditingController _platformController;
  late String _category;
  bool _visitConfirmed = true;
  late VisitSlotValue _visit;
  DateTime? _windowStart;
  DateTime? _windowEnd;
  String? _windowTime;
  String? _windowTimeEnd;
  late final TextEditingController _sponsorController;
  late final TextEditingController _feeController;
  late DateTime _deadline;
  bool _deadlineAuto = true;
  int? _alertDays = 3;
  bool _isSubmitting = false;

  late final RegistrationViewModel _registrationViewModel;

  @override
  void initState() {
    super.initState();
    _applyInitialFields();
    _registrationViewModel = RegistrationViewModel(
      repository: widget.campaignRepository,
      ownerId: widget.ownerId,
    );
    // `_canSubmit` reads the brand text directly rather than through
    // `setState`-driven fields, so it needs its own listener to keep the
    // submit button's enabled state in sync as the user types.
    _brandController.addListener(_handleBrandChanged);
  }

  /// Seeds every field from `widget.initialDraft` when present (AI mode with
  /// a real OCR result), otherwise falls back to the same baseline defaults
  /// manual mode has always started from. AI mode's confirmed-visit panel
  /// only ever displays a single date (see `build()` below), so a detected
  /// date *range* collapses to its start date here rather than populating
  /// the window fields, which AI mode never renders.
  void _applyInitialFields() {
    final draft = widget.initialDraft;
    _brandController = TextEditingController(text: draft?.brand ?? '');
    _platformController = TextEditingController(text: draft?.platform ?? '');

    final draftCategory = draft?.category ?? '';
    _category =
        draftCategory.isNotEmpty && widget.categories.contains(draftCategory)
        ? draftCategory
        : '맛집';

    _sponsorController = TextEditingController(
      text: draft?.sponsoredValue ?? '',
    );
    _feeController = TextEditingController(text: draft?.cashFee ?? '');

    final visitDateText = switch (draft?.visitAvailability) {
      VisitDateRangeDraft(:final start) => start,
      VisitDateOptionsDraft(dates: [final first, ...]) => first,
      _ => null,
    };
    final parsedVisitDate = visitDateText == null
        ? null
        : DateTime.tryParse(visitDateText);
    _visit = VisitSlotValue(
      date: parsedVisitDate ?? MockReviewCalendarData.d(4, 18),
      time: draft?.availableTimes.firstOrNull?.start,
    );

    final parsedDeadline = draft?.deadline == null
        ? null
        : DateTime.tryParse(draft!.deadline);
    if (parsedDeadline != null) {
      _deadline = parsedDeadline;
      _deadlineAuto = false;
    } else {
      _deadline = MockReviewCalendarData.d(5, 2);
    }
  }

  void _handleBrandChanged() => setState(() {});

  @override
  void dispose() {
    _brandController.removeListener(_handleBrandChanged);
    _brandController.dispose();
    _platformController.dispose();
    _sponsorController.dispose();
    _feeController.dispose();
    _registrationViewModel.dispose();
    super.dispose();
  }

  bool get _canSubmit =>
      !_isSubmitting &&
      _brandController.text.trim().isNotEmpty &&
      (_visitConfirmed || (_windowStart != null && _windowEnd != null));

  String _isoDate(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';

  CampaignRegistrationDraft _buildDraft() {
    final VisitAvailabilityDraft? availability = _visitConfirmed
        ? (_visit.date != null
              ? VisitDateRangeDraft(
                  start: _isoDate(_visit.date!),
                  end: _isoDate(_visit.date!),
                )
              : null)
        : (_windowStart != null && _windowEnd != null
              ? VisitDateRangeDraft(
                  start: _isoDate(_windowStart!),
                  end: _isoDate(_windowEnd!),
                )
              : null);
    final time = _visitConfirmed ? _visit.time : _windowTime;
    final timeEnd = _visitConfirmed
        ? _visit.time
        : (_windowTimeEnd ?? _windowTime);

    return CampaignRegistrationDraft(
      brand: _brandController.text,
      platform: _platformController.text,
      category: _category,
      visitAvailability: availability,
      deadline: _isoDate(_deadline),
      sponsoredValue: _sponsorController.text,
      cashFee: _feeController.text,
      availableTimes: [
        if (time != null)
          VisitTimeRangeDraft(start: time, end: timeEnd ?? time),
      ],
      deadlineAlertDaysBefore: _alertDays,
    );
  }

  Future<void> _handleConfirm() async {
    setState(() => _isSubmitting = true);
    _registrationViewModel.update(_buildDraft());
    final success = await _registrationViewModel.save();
    if (!mounted) return;
    setState(() => _isSubmitting = false);
    if (success) {
      final registration = widget.notificationRegistration;
      if (registration != null) {
        await offerCampaignNotifications(
          context: context,
          controller: registration,
        );
        if (!mounted) return;
      }
      widget.onConfirm();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _registrationViewModel.message ?? '저장하지 못했어요. 다시 시도해 주세요.',
          ),
        ),
      );
    }
  }

  Future<void> _editVisit() async {
    final result = await showModalBottomSheet<VisitSlotValue>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _VisitEditSheet(visit: _visit),
    );
    if (result != null) setState(() => _visit = result);
  }

  Future<void> _editWindow() async {
    final result = await showModalBottomSheet<_WindowPickResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _WindowEditSheet(
        start: _windowStart,
        end: _windowEnd,
        time: _windowTime,
        timeEnd: _windowTimeEnd,
      ),
    );
    if (result != null) {
      setState(() {
        _windowStart = result.start;
        _windowEnd = result.end;
        _windowTime = result.time;
        _windowTimeEnd = result.timeEnd;
        // 체험 종료일 다음날로 자동 설정 — 사용자가 직접 수정한 적 없을 때만.
        if (_deadlineAuto) _deadline = result.end.add(const Duration(days: 1));
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.rcColors;
    final isManual = widget.mode == _Mode.manual;
    return Stack(
      children: [
        Positioned.fill(
          child: ListView(
            padding: EdgeInsets.fromLTRB(16, isManual ? 8 : 4, 16, 190),
            children: [
              if (isManual)
                Row(
                  children: [
                    _CircleButton(
                      glyph: RcIconGlyph.chevronLeft,
                      onTap: widget.onBack ?? () {},
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '직접 입력하기',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        Text(
                          '체험단 정보를 채워주세요',
                          style: Theme.of(context).textTheme.labelMedium,
                        ),
                      ],
                    ),
                  ],
                )
              else ...[
                // Align so the pill hugs the text instead of stretching to
                // the ListView's full cross-axis width.
                Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: colors.brandSoft,
                      borderRadius: BorderRadius.circular(RcRadius.pill),
                    ),
                    child: Text(
                      '분석 완료',
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        color: colors.brandDeep,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '내용이 맞는지 확인해주세요',
                  style: Theme.of(
                    context,
                  ).textTheme.headlineSmall?.copyWith(fontSize: 20),
                ),
                Text(
                  '수정하고 싶은 항목을 탭해서 바꿀 수 있어요',
                  style: Theme.of(context).textTheme.labelMedium,
                ),
              ],
              const SizedBox(height: 12),
              _FieldCard(
                children: [
                  _LabeledField(label: '업체명', controller: _brandController),
                  _LabeledField(label: '플랫폼', controller: _platformController),
                  Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '카테고리',
                          style: Theme.of(context).textTheme.labelMedium,
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: widget.categories.map((cat) {
                            final on = _category == cat;
                            return InkWell(
                              onTap: () => setState(() => _category = cat),
                              borderRadius: BorderRadius.circular(
                                RcRadius.pill,
                              ),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 7,
                                ),
                                decoration: BoxDecoration(
                                  color: on
                                      ? colors.brand
                                      : colors.backgroundAlternative,
                                  borderRadius: BorderRadius.circular(
                                    RcRadius.pill,
                                  ),
                                ),
                                child: Text(
                                  cat,
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w600,
                                    color: on ? Colors.white : colors.ink,
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              _FieldCard(
                header: '일정',
                children: [
                  if (isManual)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(14, 12, 14, 4),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '방문일이 확정됐나요?',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: colors.inkSubtle,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.all(3),
                            decoration: BoxDecoration(
                              color: colors.backgroundAlternative,
                              borderRadius: BorderRadius.circular(
                                RcRadius.pill,
                              ),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: _toggleButton(
                                    '네, 확정됐어요',
                                    _visitConfirmed,
                                    () =>
                                        setState(() => _visitConfirmed = true),
                                  ),
                                ),
                                Expanded(
                                  child: _toggleButton(
                                    '아직 미정이에요',
                                    !_visitConfirmed,
                                    () =>
                                        setState(() => _visitConfirmed = false),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (!isManual || _visitConfirmed)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '방문 날짜 · 시간',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: colors.inkSubtle,
                            ),
                          ),
                          const SizedBox(height: 8),
                          _VisitSlot(visit: _visit, onEdit: _editVisit),
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text.rich(
                              TextSpan(
                                style: TextStyle(
                                  fontSize: 10.5,
                                  color: colors.inkSubtle,
                                  height: 1.5,
                                ),
                                children: [
                                  const TextSpan(text: '아직 정해지지 않았다면 '),
                                  TextSpan(
                                    text: '미정',
                                    style: TextStyle(
                                      color: colors.ink,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const TextSpan(text: '으로 둘 수 있어요'),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    Padding(
                      padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '방문 가능한 기간 · 시간',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: colors.inkSubtle,
                            ),
                          ),
                          const SizedBox(height: 8),
                          InkWell(
                            onTap: _editWindow,
                            borderRadius: BorderRadius.circular(
                              RcRadius.medium,
                            ),
                            child: DashedBorderBox(
                              color: _windowStart != null
                                  ? colors.visit.chip
                                  : colors.borderStrong,
                              background: _windowStart != null
                                  ? colors.visit.soft
                                  : Colors.white,
                              radius: RcRadius.medium,
                              strokeWidth: 1.5,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 10,
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      _windowStart != null && _windowEnd != null
                                          ? '${shortDateLabel(_windowStart!)} ~ ${shortDateLabel(_windowEnd!)}'
                                          : '기간을 선택해주세요',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: _windowStart != null
                                            ? colors.ink
                                            : colors.inkMuted,
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
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '가능 시간 · ${_windowTime != null ? '$_windowTime ~ ${_windowTimeEnd ?? _windowTime}' : '미정'}',
                            style: TextStyle(
                              fontSize: 11,
                              color: colors.inkSubtle,
                              fontStyle: _windowTime != null
                                  ? FontStyle.normal
                                  : FontStyle.italic,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '이 기간 중 하루를 골라 방문할 수 있어요. 등록하면 미정 일정에 담겨서, 나중에 캘린더에서 날짜를 확정할 수 있어요',
                            style: TextStyle(
                              fontSize: 10.5,
                              color: colors.inkSubtle,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  Container(
                    padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
                    decoration: BoxDecoration(
                      border: Border(
                        top: BorderSide(color: colors.border, width: 0.5),
                      ),
                    ),
                    child: isManual
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '포스팅 마감',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: colors.inkSubtle,
                                ),
                              ),
                              const SizedBox(height: 6),
                              _DateField(
                                date: _deadline,
                                onChanged: (d) => setState(() {
                                  _deadline = d;
                                  _deadlineAuto = false;
                                }),
                              ),
                              if (!_visitConfirmed)
                                Padding(
                                  padding: const EdgeInsets.only(top: 6),
                                  child: Text(
                                    _deadlineAuto
                                        ? '체험 종료일 다음날로 자동 설정했어요 · 다르다면 직접 수정하세요'
                                        : '직접 수정한 마감일이에요',
                                    style: TextStyle(
                                      fontSize: 10.5,
                                      color: colors.inkSubtle,
                                    ),
                                  ),
                                ),
                            ],
                          )
                        : Row(
                            children: [
                              SizedBox(
                                width: 74,
                                child: Text(
                                  '포스팅 마감',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: colors.inkSubtle,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: colors.deadline.soft,
                                  borderRadius: BorderRadius.circular(
                                    RcRadius.pill,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 5,
                                      height: 5,
                                      decoration: BoxDecoration(
                                        color: colors.deadline.ink,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 5),
                                    Text(
                                      '${_deadline.year}.${_deadline.month.toString().padLeft(2, '0')}.${_deadline.day.toString().padLeft(2, '0')}',
                                      style: TextStyle(
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w600,
                                        color: colors.deadline.ink,
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
              const SizedBox(height: 10),
              _FieldCard(
                header: '수익',
                children: isManual
                    ? [
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '협찬 금액',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: colors.inkSubtle,
                                ),
                              ),
                              const SizedBox(height: 6),
                              _AmountField(controller: _sponsorController),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            border: Border(
                              top: BorderSide(color: colors.border, width: 0.5),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '원고료 (있는 경우만)',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: colors.inkSubtle,
                                ),
                              ),
                              const SizedBox(height: 6),
                              _AmountField(controller: _feeController),
                            ],
                          ),
                        ),
                      ]
                    : [
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                          child: Row(
                            children: [
                              SizedBox(
                                width: 74,
                                child: Text(
                                  '구분',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: colors.inkSubtle,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  '협찬',
                                  style: TextStyle(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w600,
                                    color: colors.ink,
                                  ),
                                ),
                              ),
                              RcIcon(
                                RcIconGlyph.edit,
                                size: 14,
                                color: colors.inkMuted,
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            border: Border(
                              top: BorderSide(color: colors.border, width: 0.5),
                            ),
                          ),
                          child: Row(
                            children: [
                              SizedBox(
                                width: 74,
                                child: Text(
                                  '금액',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: colors.inkSubtle,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  formatWon(68000),
                                  style: TextStyle(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w600,
                                    color: colors.ink,
                                  ),
                                ),
                              ),
                              RcIcon(
                                RcIconGlyph.edit,
                                size: 14,
                                color: colors.inkMuted,
                              ),
                            ],
                          ),
                        ),
                      ],
              ),
              const SizedBox(height: 10),
              _FieldCard(
                header: '마감 알림',
                children: [
                  Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                '마감 며칠 전에 알려드릴까요?',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: colors.inkSubtle,
                                ),
                              ),
                            ),
                            InkWell(
                              onTap: () => setState(
                                () =>
                                    _alertDays = _alertDays == null ? 3 : null,
                              ),
                              customBorder: const CircleBorder(),
                              child: Container(
                                width: 30,
                                height: 30,
                                decoration: BoxDecoration(
                                  color: _alertDays == null
                                      ? colors.ink
                                      : colors.backgroundAlternative,
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: RcIcon(
                                    RcIconGlyph.bell,
                                    size: 15,
                                    color: _alertDays == null
                                        ? Colors.white
                                        : colors.inkSubtle,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Opacity(
                          opacity: _alertDays == null ? 0.4 : 1,
                          child: Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: [1, 2, 3, 5, 7].map((n) {
                              final on = _alertDays == n;
                              return InkWell(
                                onTap: _alertDays == null
                                    ? null
                                    : () => setState(() => _alertDays = n),
                                borderRadius: BorderRadius.circular(
                                  RcRadius.medium,
                                ),
                                child: Container(
                                  width: 60,
                                  height: 38,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: on
                                        ? colors.brand
                                        : colors.backgroundAlternative,
                                    borderRadius: BorderRadius.circular(
                                      RcRadius.medium,
                                    ),
                                  ),
                                  child: Text(
                                    '$n일 전',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: on ? Colors.white : colors.ink,
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: Container(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 30),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  colors.background.withValues(alpha: 0),
                  colors.background,
                ],
                stops: const [0, 0.3],
              ),
            ),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _canSubmit ? _handleConfirm : null,
                child: const Text('캘린더에 등록하기'),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _toggleButton(String label, bool on, VoidCallback onTap) {
    final colors = context.rcColors;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(RcRadius.pill),
      child: Container(
        height: 32,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: on ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(RcRadius.pill),
          boxShadow: on
              ? [
                  BoxShadow(
                    color: colors.ink.withValues(alpha: 0.06),
                    blurRadius: 2,
                    offset: const Offset(0, 1),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
            color: on ? colors.brandDeep : colors.inkSubtle,
          ),
        ),
      ),
    );
  }
}

class _FieldCard extends StatelessWidget {
  const _FieldCard({required this.children, this.header});
  final String? header;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final colors = context.rcColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (header != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 0, 4, 6),
            child: Text(
              header!,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
                color: colors.inkMuted,
                letterSpacing: 1,
              ),
            ),
          ),
        Container(
          decoration: BoxDecoration(
            color: colors.card,
            borderRadius: BorderRadius.circular(RcRadius.large),
            border: Border.all(color: colors.border),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(children: children),
        ),
      ],
    );
  }
}

class _LabeledField extends StatelessWidget {
  const _LabeledField({required this.label, required this.controller});
  final String label;
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    final colors = context.rcColors;
    final valueStyle = TextStyle(
      fontSize: 13.5,
      fontWeight: FontWeight.w600,
      color: colors.ink,
    );
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: colors.border, width: 0.5)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 74,
            child: Text(
              label,
              style: TextStyle(fontSize: 12, color: colors.inkSubtle),
            ),
          ),
          // Always editable — even in AI mode, since OCR extraction can
          // miss or misread a field (e.g. an unlabeled brand name) and the
          // user needs a way to fix it without backing out to manual entry.
          Expanded(
            child: TextField(
              controller: controller,
              style: valueStyle,
              decoration: const InputDecoration(
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          RcIcon(RcIconGlyph.edit, size: 14, color: colors.inkMuted),
        ],
      ),
    );
  }
}

class _AmountField extends StatelessWidget {
  const _AmountField({required this.controller});
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    final colors = context.rcColors;
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: controller,
      builder: (context, value, _) {
        final hint = formatKoreanWon(value.text);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: colors.ink,
              ),
              decoration: InputDecoration(
                hintText: '0',
                isDense: true,
                filled: true,
                fillColor: colors.background,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                // Pin every border state explicitly — otherwise Material's
                // default focused/error borders (theme primary, 2px) show
                // through instead of the design's plain 1px hairline.
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(9),
                  borderSide: BorderSide(color: colors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(9),
                  borderSide: BorderSide(color: colors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(9),
                  borderSide: BorderSide(color: colors.border),
                ),
              ),
            ),
            if (hint.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  hint,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: colors.brandDeep,
                    letterSpacing: -0.2,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _DateField extends StatelessWidget {
  const _DateField({required this.date, required this.onChanged});
  final DateTime date;
  final ValueChanged<DateTime> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.rcColors;
    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: date,
          firstDate: DateTime(2026, 1),
          lastDate: DateTime(2026, 12),
        );
        if (picked != null) onChanged(picked);
      },
      child: Container(
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        alignment: Alignment.centerLeft,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(9),
          border: Border.all(color: colors.border),
        ),
        child: Text(
          '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: colors.ink,
          ),
        ),
      ),
    );
  }
}

class _VisitSlot extends StatelessWidget {
  const _VisitSlot({required this.visit, required this.onEdit});
  final VisitSlotValue visit;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final colors = context.rcColors;
    final dateUndecided = visit.date == null;
    final timeUndecided = visit.time == null;
    final bothDecided = !dateUndecided && !timeUndecided;
    final allUndecided = dateUndecided && timeUndecided;
    final dividerColor = allUndecided
        ? colors.borderStrong
        : bothDecided
        ? colors.visit.chip
        : colors.borderStrong;

    Widget chunk(String label, String value, bool undecided) => Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 9.5,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.4,
                color: undecided ? colors.inkMuted : colors.visit.ink,
              ),
            ),
            Text(
              value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: undecided ? colors.inkMuted : colors.ink,
                fontStyle: undecided ? FontStyle.italic : FontStyle.normal,
              ),
            ),
          ],
        ),
      ),
    );

    final content = IntrinsicHeight(
      child: Row(
        children: [
          chunk(
            'DATE',
            visit.date == null
                ? '미정'
                : '${visit.date!.month}월 ${visit.date!.day}일 (${weekdayKo(visit.date!)})',
            dateUndecided,
          ),
          DashedVerticalDivider(color: dividerColor),
          chunk('TIME', visit.time ?? '미정', timeUndecided),
        ],
      ),
    );

    return InkWell(
      onTap: onEdit,
      borderRadius: BorderRadius.circular(RcRadius.medium),
      child: allUndecided
          ? DashedBorderBox(
              color: colors.borderStrong,
              background: Colors.white,
              radius: RcRadius.medium,
              strokeWidth: 1.5,
              child: content,
            )
          : Container(
              decoration: BoxDecoration(
                color: bothDecided ? colors.visit.soft : Colors.white,
                border: Border.all(
                  color: bothDecided ? colors.visit.chip : colors.border,
                ),
                borderRadius: BorderRadius.circular(RcRadius.medium),
              ),
              child: content,
            ),
    );
  }
}

class _VisitEditSheet extends StatefulWidget {
  const _VisitEditSheet({required this.visit});
  final VisitSlotValue visit;

  @override
  State<_VisitEditSheet> createState() => _VisitEditSheetState();
}

class _VisitEditSheetState extends State<_VisitEditSheet> {
  late DateTime? _date = widget.visit.date;
  late String? _time = widget.visit.time;

  static const _times = [
    '11:30',
    '12:00',
    '12:30',
    '13:00',
    '13:30',
    '18:00',
    '18:30',
    '19:00',
    '19:30',
    '20:00',
  ];

  @override
  Widget build(BuildContext context) {
    final colors = context.rcColors;
    final dates = List.generate(16, (i) => MockReviewCalendarData.d(4, 15 + i));
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
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
              margin: const EdgeInsets.only(bottom: 14),
              decoration: BoxDecoration(
                color: colors.borderStrong,
                borderRadius: BorderRadius.circular(RcRadius.pill),
              ),
            ),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '방문 날짜 · 시간',
                style: Theme.of(
                  context,
                ).textTheme.headlineSmall?.copyWith(fontSize: 18),
              ),
              Text(
                '미정이면 비워두세요',
                style: TextStyle(fontSize: 11, color: colors.inkSubtle),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '날짜',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: colors.inkSubtle,
                ),
              ),
              _PickerMetaButton(
                on: _date == null,
                label: '미정으로 두기',
                onTap: () => setState(() => _date = null),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 60,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: dates.length,
              separatorBuilder: (_, _) => const SizedBox(width: 6),
              itemBuilder: (context, i) {
                final d = dates[i];
                final sel = _date != null && isSameDay(_date!, d);
                return InkWell(
                  onTap: () => setState(() => _date = d),
                  borderRadius: BorderRadius.circular(RcRadius.medium),
                  child: Container(
                    width: 44,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: sel ? colors.brand : colors.card,
                      border: Border.all(
                        color: sel ? colors.brand : colors.border,
                      ),
                      borderRadius: BorderRadius.circular(RcRadius.medium),
                    ),
                    child: Column(
                      children: [
                        Text(
                          weekdayKo(d),
                          style: TextStyle(
                            fontSize: 10,
                            color: sel ? Colors.white70 : colors.inkSubtle,
                          ),
                        ),
                        Text(
                          '${d.day}',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: sel ? Colors.white : colors.ink,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '시간',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: colors.inkSubtle,
                ),
              ),
              _PickerMetaButton(
                on: _time == null,
                label: '미정으로 두기',
                onTap: () => setState(() => _time = null),
              ),
            ],
          ),
          const SizedBox(height: 8),
          GridView.count(
            crossAxisCount: 5,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 6,
            crossAxisSpacing: 6,
            childAspectRatio: 1.8,
            children: _times.map((t) {
              final sel = _time == t;
              return InkWell(
                onTap: () => setState(() => _time = t),
                borderRadius: BorderRadius.circular(RcRadius.medium),
                child: Container(
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: sel ? colors.brand : colors.card,
                    border: Border.all(
                      color: sel ? colors.brand : colors.border,
                    ),
                    borderRadius: BorderRadius.circular(RcRadius.medium),
                  ),
                  child: Text(
                    t,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: sel ? Colors.white : colors.ink,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () => Navigator.of(
                context,
              ).pop(VisitSlotValue(date: _date, time: _time)),
              child: const Text('저장'),
            ),
          ),
        ],
      ),
    );
  }
}

class _WindowPickResult {
  const _WindowPickResult({
    required this.start,
    required this.end,
    this.time,
    this.timeEnd,
  });
  final DateTime start;
  final DateTime end;
  final String? time;
  final String? timeEnd;
}

/// 방문 가능한 기간 — mirrors `screen-upload.jsx`'s `WindowEditSheet`: a real
/// month calendar (not a flat day list) for the date range, plus a
/// "가능 시간" time-range picker with its own 미정으로 두기 toggle.
class _WindowEditSheet extends StatefulWidget {
  const _WindowEditSheet({this.start, this.end, this.time, this.timeEnd});
  final DateTime? start;
  final DateTime? end;
  final String? time;
  final String? timeEnd;

  @override
  State<_WindowEditSheet> createState() => _WindowEditSheetState();
}

class _WindowEditSheetState extends State<_WindowEditSheet> {
  static const _timeOptions = [
    '11:30',
    '12:00',
    '12:30',
    '13:00',
    '13:30',
    '18:00',
    '18:30',
    '19:00',
    '19:30',
    '20:00',
  ];

  late DateTime? _start = widget.start;
  late DateTime? _end = widget.end;
  late String? _time = widget.time;
  late String? _timeEnd = widget.timeEnd;
  int _viewYear = 2026;
  int _viewMonth = 4;

  void _pickDate(DateTime d) {
    setState(() {
      if (_start == null || (_start != null && _end != null)) {
        _start = d;
        _end = null;
      } else if (d.isBefore(_start!)) {
        _start = d;
      } else {
        _end = d;
      }
    });
  }

  void _pickTime(String t) {
    setState(() {
      if (_time == null || (_time != null && _timeEnd != null)) {
        _time = t;
        _timeEnd = null;
      } else if (t.compareTo(_time!) < 0) {
        _time = t;
      } else {
        _timeEnd = t;
      }
    });
  }

  void _goPrevMonth() => setState(() {
    if (_viewMonth == 1) {
      _viewMonth = 12;
      _viewYear -= 1;
    } else {
      _viewMonth -= 1;
    }
  });

  void _goNextMonth() => setState(() {
    if (_viewMonth == 12) {
      _viewMonth = 1;
      _viewYear += 1;
    } else {
      _viewMonth += 1;
    }
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.rcColors;
    final cells = buildMonthGrid(_viewYear, _viewMonth);
    final canConfirm = _start != null && _end != null;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.86,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 38,
                height: 4,
                margin: const EdgeInsets.only(bottom: 14),
                decoration: BoxDecoration(
                  color: colors.borderStrong,
                  borderRadius: BorderRadius.circular(RcRadius.pill),
                ),
              ),
            ),
            Text(
              '방문 가능한 기간',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontSize: 18),
            ),
            const SizedBox(height: 4),
            Text(
              _start == null
                  ? '시작일을 선택해주세요'
                  : _end == null
                  ? '종료일을 선택해주세요'
                  : '${shortDateLabel(_start!)} ~ ${shortDateLabel(_end!)}',
              style: TextStyle(fontSize: 11.5, color: colors.inkSubtle),
            ),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '$_viewYear.${_viewMonth.toString().padLeft(2, '0')}',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: colors.ink,
                  ),
                ),
                Row(
                  children: [
                    _MiniNavButton(
                      glyph: RcIconGlyph.chevronLeft,
                      onTap: _goPrevMonth,
                    ),
                    const SizedBox(width: 6),
                    _MiniNavButton(
                      glyph: RcIconGlyph.chevronRight,
                      onTap: _goNextMonth,
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: ['일', '월', '화', '수', '목', '금', '토']
                  .asMap()
                  .entries
                  .map(
                    (e) => Expanded(
                      child: Center(
                        child: Text(
                          e.value,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: e.key == 0
                                ? const Color(0xFFC25E5E)
                                : e.key == 6
                                ? const Color(0xFF5980B8)
                                : colors.inkSubtle,
                          ),
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
            Container(
              decoration: BoxDecoration(
                color: colors.card,
                borderRadius: BorderRadius.circular(RcRadius.medium),
                border: Border.all(color: colors.border),
              ),
              clipBehavior: Clip.antiAlias,
              child: GridView.builder(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: cells.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 7,
                ),
                itemBuilder: (context, i) {
                  final cell = cells[i];
                  final inRange =
                      _start != null &&
                      _end != null &&
                      !cell.date.isBefore(_start!) &&
                      !cell.date.isAfter(_end!);
                  final isEndpoint =
                      (_start != null && isSameDay(_start!, cell.date)) ||
                      (_end != null && isSameDay(_end!, cell.date));
                  return InkWell(
                    onTap: cell.outside ? null : () => _pickDate(cell.date),
                    child: Container(
                      decoration: BoxDecoration(
                        color: isEndpoint
                            ? colors.brand
                            : inRange
                            ? colors.brandSoft
                            : Colors.transparent,
                        border: Border(
                          top: i >= 7
                              ? BorderSide(color: colors.border, width: 0.5)
                              : BorderSide.none,
                          left: i % 7 != 0
                              ? BorderSide(color: colors.border, width: 0.5)
                              : BorderSide.none,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Opacity(
                        opacity: cell.outside ? 0.3 : 1,
                        child: Text(
                          '${cell.date.day}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: isEndpoint
                                ? FontWeight.w700
                                : FontWeight.w500,
                            color: isEndpoint
                                ? Colors.white
                                : cell.outside
                                ? colors.inkMuted
                                : colors.ink,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '가능 시간',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: colors.inkSubtle,
                    letterSpacing: 0.3,
                  ),
                ),
                _PickerMetaButton(
                  on: _time == null,
                  label: '미정으로 두기',
                  onTap: () => setState(() {
                    _time = null;
                    _timeEnd = null;
                  }),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              _time == null
                  ? '시작 시간을 선택해주세요'
                  : _timeEnd == null
                  ? '종료 시간을 선택해주세요'
                  : '$_time ~ $_timeEnd',
              style: TextStyle(fontSize: 11, color: colors.inkSubtle),
            ),
            const SizedBox(height: 8),
            GridView.count(
              crossAxisCount: 5,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 6,
              crossAxisSpacing: 6,
              childAspectRatio: 1.8,
              children: _timeOptions.map((t) {
                final inRange =
                    _time != null &&
                    _timeEnd != null &&
                    t.compareTo(_time!) >= 0 &&
                    t.compareTo(_timeEnd!) <= 0;
                final isEndpoint = t == _time || t == _timeEnd;
                return InkWell(
                  onTap: () => _pickTime(t),
                  borderRadius: BorderRadius.circular(RcRadius.medium),
                  child: Container(
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: isEndpoint
                          ? colors.brand
                          : inRange
                          ? colors.brandSoft
                          : colors.card,
                      border: Border.all(
                        color: isEndpoint ? colors.brand : colors.border,
                      ),
                      borderRadius: BorderRadius.circular(RcRadius.medium),
                    ),
                    child: Text(
                      t,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: isEndpoint ? Colors.white : colors.ink,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
            Center(
              child: InkWell(
                onTap: canConfirm
                    ? () => Navigator.of(context).pop(
                        _WindowPickResult(
                          start: _start!,
                          end: _end!,
                          time: _time,
                          timeEnd: _timeEnd,
                        ),
                      )
                    : null,
                customBorder: const CircleBorder(),
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: canConfirm ? colors.brand : colors.borderStrong,
                    shape: BoxShape.circle,
                    boxShadow: canConfirm
                        ? [
                            BoxShadow(
                              color: colors.brand.withValues(alpha: 0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ]
                        : null,
                  ),
                  child: const Icon(Icons.check, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniNavButton extends StatelessWidget {
  const _MiniNavButton({required this.glyph, required this.onTap});
  final RcIconGlyph glyph;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.rcColors;
    return InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: Container(
        width: 26,
        height: 26,
        decoration: BoxDecoration(
          color: colors.card,
          shape: BoxShape.circle,
          border: Border.all(color: colors.border),
        ),
        child: Center(child: RcIcon(glyph, size: 12, color: colors.ink)),
      ),
    );
  }
}

class _PickerMetaButton extends StatelessWidget {
  const _PickerMetaButton({
    required this.on,
    required this.label,
    required this.onTap,
  });
  final bool on;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.rcColors;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(RcRadius.pill),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: on ? colors.ink : Colors.transparent,
          borderRadius: BorderRadius.circular(RcRadius.pill),
          border: on ? null : Border.all(color: colors.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (on) ...[
              const SizedBox(
                width: 5,
                height: 5,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
                color: on ? Colors.white : colors.inkSubtle,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
