import 'dart:async';

import 'package:review_calendar/features/campaign/data/campaign_repository.dart';
import 'package:review_calendar/features/campaign/domain/campaign.dart';
import 'package:review_calendar/features/campaign/domain/campaign_id.dart';
import 'package:review_calendar/features/campaign/domain/campaign_status.dart';
import 'package:review_calendar/features/campaign/domain/local_date.dart';

final class FakeCampaignRepository implements CampaignRepository {
  FakeCampaignRepository({
    Iterable<StoredCampaign> seed = const [],
    this.isOnline = true,
  }) : _campaigns = {
         for (final stored in seed) stored.campaign.id.value: stored,
       };

  final Map<String, StoredCampaign> _campaigns;
  final StreamController<void> _changes = StreamController<void>.broadcast();

  bool isOnline;
  CampaignSaveFailureKind? failNextSaveWith;
  Future<void>? createDelay;
  int createCallCount = 0;
  final List<Campaign> createCalls = [];

  CampaignDataOrigin get _origin =>
      isOnline ? CampaignDataOrigin.server : CampaignDataOrigin.cache;

  @override
  Future<CampaignSaveResult> create(Campaign campaign) async {
    createCallCount += 1;
    createCalls.add(campaign);
    await createDelay;
    final failure = _takeFailure(CampaignSaveOperation.create, campaign);
    if (failure != null) {
      return failure;
    }
    if (_campaigns.containsKey(campaign.id.value)) {
      return CampaignSaveFailure(
        operation: CampaignSaveOperation.create,
        kind: CampaignSaveFailureKind.conflict,
        retainedCampaign: campaign,
        message: '같은 일정이 이미 존재해요.',
      );
    }
    _campaigns[campaign.id.value] = StoredCampaign(
      campaign: campaign,
      revision: 1,
      hasPendingWrites: !isOnline,
    );
    _changes.add(null);
    return CampaignSaveSuccess(
      operation: CampaignSaveOperation.create,
      campaignId: campaign.id,
      revision: 1,
    );
  }

  @override
  Future<StoredCampaign?> getById(CampaignId id) async {
    final stored = _campaigns[id.value];
    return stored == null ? null : _withCurrentMetadata(stored);
  }

  @override
  Stream<CampaignSnapshot> watchAll() => _watch((_) => true);

  @override
  Stream<CampaignSnapshot> watchVisitsBetween({
    required LocalDate start,
    required LocalDate end,
  }) {
    return _watch((stored) {
      final date = stored.campaign.visit.date;
      return date != null &&
          date.compareTo(start) >= 0 &&
          date.compareTo(end) <= 0;
    });
  }

  @override
  Stream<CampaignSnapshot> watchByPostingStatuses(Set<PostingStatus> statuses) {
    return _watch(
      (stored) => statuses.contains(stored.campaign.status.posting),
    );
  }

  @override
  Stream<CampaignSnapshot> watchPublished({
    bool descending = true,
    int? limit,
  }) {
    return _watch((stored) {
      final campaign = stored.campaign;
      return campaign.status.posting == PostingStatus.published &&
          campaign.publishedDate != null;
    }).map((snapshot) {
      final campaigns = snapshot.campaigns.toList()
        ..sort((left, right) {
          final order = left.campaign.publishedDate!.compareTo(
            right.campaign.publishedDate!,
          );
          final byDate = descending ? -order : order;
          if (byDate != 0) return byDate;
          return left.campaign.id.value.compareTo(right.campaign.id.value);
        });
      return CampaignSnapshot(
        campaigns: limit == null ? campaigns : campaigns.take(limit).toList(),
        origin: snapshot.origin,
      );
    });
  }

  @override
  Future<CampaignSaveResult> update(
    Campaign campaign, {
    required int expectedRevision,
  }) async {
    final failure = _takeFailure(CampaignSaveOperation.update, campaign);
    if (failure != null) {
      return failure;
    }
    final current = _campaigns[campaign.id.value];
    if (current == null || current.revision != expectedRevision) {
      return CampaignSaveFailure(
        operation: CampaignSaveOperation.update,
        kind: CampaignSaveFailureKind.conflict,
        retainedCampaign: campaign,
        message: '다른 변경이 먼저 저장됐어요. 최신 내용을 확인해 주세요.',
      );
    }
    final nextRevision = expectedRevision + 1;
    _campaigns[campaign.id.value] = StoredCampaign(
      campaign: campaign,
      revision: nextRevision,
      hasPendingWrites: !isOnline,
    );
    _changes.add(null);
    return CampaignSaveSuccess(
      operation: CampaignSaveOperation.update,
      campaignId: campaign.id,
      revision: nextRevision,
    );
  }

  @override
  Future<CampaignSaveResult> delete(StoredCampaign storedCampaign) async {
    final campaign = storedCampaign.campaign;
    final failure = _takeFailure(CampaignSaveOperation.delete, campaign);
    if (failure != null) {
      return failure;
    }
    final current = _campaigns[campaign.id.value];
    if (current == null || current.revision != storedCampaign.revision) {
      return CampaignSaveFailure(
        operation: CampaignSaveOperation.delete,
        kind: CampaignSaveFailureKind.conflict,
        retainedCampaign: campaign,
        message: '삭제 전에 일정이 변경됐어요. 최신 내용을 확인해 주세요.',
      );
    }
    _campaigns.remove(campaign.id.value);
    _changes.add(null);
    return CampaignSaveSuccess(
      operation: CampaignSaveOperation.delete,
      campaignId: campaign.id,
      revision: null,
    );
  }

  Future<void> dispose() => _changes.close();

  Stream<CampaignSnapshot> _watch(
    bool Function(StoredCampaign stored) include,
  ) async* {
    yield _snapshot(include);
    await for (final _ in _changes.stream) {
      yield _snapshot(include);
    }
  }

  CampaignSnapshot _snapshot(bool Function(StoredCampaign stored) include) {
    final campaigns =
        _campaigns.values.where(include).map(_withCurrentMetadata).toList()
          ..sort(
            (left, right) =>
                left.campaign.deadline.compareTo(right.campaign.deadline),
          );
    return CampaignSnapshot(campaigns: campaigns, origin: _origin);
  }

  StoredCampaign _withCurrentMetadata(StoredCampaign stored) {
    return StoredCampaign(
      campaign: stored.campaign,
      revision: stored.revision,
      hasPendingWrites: stored.hasPendingWrites,
      origin: _origin,
    );
  }

  CampaignSaveFailure? _takeFailure(
    CampaignSaveOperation operation,
    Campaign campaign,
  ) {
    final kind = failNextSaveWith;
    failNextSaveWith = null;
    if (kind == null) {
      return null;
    }
    return CampaignSaveFailure(
      operation: operation,
      kind: kind,
      retainedCampaign: campaign,
      message: '저장하지 못했어요. 입력 내용은 유지했어요.',
    );
  }
}
