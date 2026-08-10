import 'package:flutter/foundation.dart';
import 'package:review_calendar/core/errors/user_recovery_policy.dart';
import 'package:review_calendar/core/identity/id_generator.dart';
import 'package:review_calendar/core/time/clock.dart';
import 'package:review_calendar/features/campaign/data/campaign_repository.dart';
import 'package:review_calendar/features/campaign/domain/campaign.dart';
import 'package:review_calendar/features/campaign/domain/campaign_id.dart';
import 'package:review_calendar/features/campaign/domain/campaign_status.dart';
import 'package:review_calendar/features/campaign/domain/visit_schedule.dart';
import 'package:review_calendar/features/registration/domain/campaign_registration_draft.dart';
import 'package:review_calendar/features/settings/domain/notification_settings.dart';

/// Ported verbatim from
/// review-calendar/app/lib/features/registration/presentation/registration_view_model.dart
enum RegistrationActionStatus { idle, saving, success, failure }

class RegistrationViewModel extends ChangeNotifier {
  factory RegistrationViewModel({
    required CampaignRepository repository,
    required String ownerId,
    IdGenerator? idGenerator,
    Clock clock = const SystemClock(),
    CampaignRegistrationDraft draft = const CampaignRegistrationDraft(),
  }) {
    return RegistrationViewModel._(
      repository,
      UserId(ownerId),
      idGenerator ?? RandomIdGenerator(),
      clock,
      draft,
      null,
    );
  }

  factory RegistrationViewModel.forEditing({
    required CampaignRepository repository,
    required StoredCampaign campaign,
    Clock clock = const SystemClock(),
  }) {
    return RegistrationViewModel._(
      repository,
      campaign.campaign.ownerId,
      RandomIdGenerator(),
      clock,
      _draftFromCampaign(campaign.campaign),
      campaign,
    );
  }

  RegistrationViewModel._(
    this._repository,
    this._ownerId,
    this._idGenerator,
    this._clock,
    this._draft,
    this._editingCampaign,
  );

  final CampaignRepository _repository;
  final UserId _ownerId;
  final IdGenerator _idGenerator;
  final Clock _clock;
  final StoredCampaign? _editingCampaign;

  CampaignRegistrationDraft _draft;
  Map<CampaignDraftField, String> _errors = const {};
  RegistrationActionStatus _status = RegistrationActionStatus.idle;
  String? _message;
  Campaign? _pendingCampaign;

  CampaignRegistrationDraft get draft => _draft;
  Map<CampaignDraftField, String> get errors => _errors;
  RegistrationActionStatus get status => _status;
  String? get message => _message;
  bool get isSaving => _status == RegistrationActionStatus.saving;
  bool get isEditing => _editingCampaign != null;
  bool get hasInput =>
      _draft.brand.trim().isNotEmpty ||
      _draft.visitAvailability != null ||
      _draft.deadline.trim().isNotEmpty ||
      _draft.platform.trim().isNotEmpty ||
      _draft.category.trim().isNotEmpty ||
      _draft.contactName.trim().isNotEmpty ||
      _draft.contactPhone.trim().isNotEmpty ||
      _draft.notes.trim().isNotEmpty ||
      _draft.sponsoredValue.trim().isNotEmpty ||
      _draft.cashFee.trim().isNotEmpty ||
      _draft.availableTimes.isNotEmpty;

  void update(CampaignRegistrationDraft draft) {
    _draft = draft;
    _errors = const {};
    _status = RegistrationActionStatus.idle;
    _message = null;
    _pendingCampaign = null;
    notifyListeners();
  }

  bool validate() {
    final result = _draft.validate();
    switch (result) {
      case CampaignDraftValid():
        _errors = const {};
        notifyListeners();
        return true;
      case CampaignDraftInvalid(:final errors):
        _errors = errors;
        notifyListeners();
        return false;
    }
  }

  Future<bool> save() async {
    if (isSaving) {
      return false;
    }
    final validation = _draft.validate();
    if (validation case CampaignDraftInvalid(:final errors)) {
      _errors = errors;
      _status = RegistrationActionStatus.failure;
      _message = recoveryPresentationFor(
        UserRecoveryScenario.missingRequired,
      ).message;
      notifyListeners();
      return false;
    }

    _errors = const {};
    _status = RegistrationActionStatus.saving;
    _message = null;
    notifyListeners();

    final valid = (validation as CampaignDraftValid).value;
    final campaign = _pendingCampaign ?? _toCampaign(valid);
    _pendingCampaign = campaign;
    final result = _editingCampaign == null
        ? await _repository.create(campaign)
        : await _repository.update(
            campaign,
            expectedRevision: _editingCampaign.revision,
          );
    switch (result) {
      case CampaignSaveSuccess():
        if (!isEditing) {
          _draft = const CampaignRegistrationDraft();
        }
        _pendingCampaign = null;
        _status = RegistrationActionStatus.success;
        _message = isEditing ? '일정 정보를 수정했어요.' : '일정을 등록했어요.';
        notifyListeners();
        return true;
      case CampaignSaveFailure(:final message):
        _status = RegistrationActionStatus.failure;
        _message = message;
        notifyListeners();
        return false;
    }
  }

  Campaign _toCampaign(ValidatedCampaignRegistrationDraft value) {
    final now = _clock.now().toUtc();
    final hasContact = value.contactName != null || value.contactPhone != null;
    final existing = _editingCampaign?.campaign;
    return Campaign(
      id: existing?.id ?? CampaignId(_idGenerator.nextId()),
      ownerId: _ownerId,
      brand: value.brand,
      platform: value.platform,
      category: value.category,
      visitAvailability: value.visitAvailability,
      availableTimes: value.availableTimes,
      status:
          existing?.status ??
          CampaignStatus(
            visit: VisitStatus.unscheduled,
            posting: PostingStatus.pending,
          ),
      visit: existing?.visit ?? const VisitSchedule(),
      deadline: value.deadline,
      originalDeadline:
          existing?.originalDeadline ??
          (existing != null && existing.deadline != value.deadline
              ? existing.deadline
              : null),
      contact: hasContact
          ? CampaignContact(name: value.contactName, phone: value.contactPhone)
          : null,
      notes: value.notes,
      sponsoredValue: value.sponsoredValue,
      cashFee: value.cashFee,
      publishedDate: existing?.publishedDate,
      postUrl: existing?.postUrl?.toString(),
      notificationSettings:
          existing?.notificationSettings ??
          CampaignNotificationSettings(
            deadline: value.deadlineAlertDaysBefore != null
                ? CustomNotification([value.deadlineAlertDaysBefore!])
                : const DisableNotification(),
          ),
      createdAt: existing?.createdAt ?? now,
      updatedAt: now,
    );
  }
}

CampaignRegistrationDraft _draftFromCampaign(Campaign campaign) {
  final availability = campaign.visitAvailability;
  return CampaignRegistrationDraft(
    brand: campaign.brand,
    visitAvailability: switch (availability) {
      VisitDateOptions(:final dates) => VisitDateOptionsDraft(
        dates.map((date) => date.toString()).toList(),
      ),
      VisitDateRange(:final start, :final end) => VisitDateRangeDraft(
        start: start.toString(),
        end: end.toString(),
      ),
    },
    deadline: campaign.deadline.toString(),
    platform: campaign.platform ?? '',
    category: campaign.category ?? '',
    contactName: campaign.contact?.name ?? '',
    contactPhone: campaign.contact?.phone ?? '',
    notes: campaign.notes,
    sponsoredValue: campaign.sponsoredValue?.amount.toString() ?? '',
    cashFee: campaign.cashFee?.amount.toString() ?? '',
    availableTimes: campaign.availableTimes
        .map(
          (range) => VisitTimeRangeDraft(
            start: range.start.toString(),
            end: range.end.toString(),
          ),
        )
        .toList(),
  );
}
