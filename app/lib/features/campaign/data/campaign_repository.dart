import 'package:review_calendar/features/campaign/domain/campaign.dart';
import 'package:review_calendar/features/campaign/domain/campaign_id.dart';
import 'package:review_calendar/features/campaign/domain/campaign_status.dart';
import 'package:review_calendar/features/campaign/domain/local_date.dart';

enum CampaignDataOrigin { cache, server }

final class StoredCampaign {
  const StoredCampaign({
    required this.campaign,
    required this.revision,
    required this.hasPendingWrites,
    this.origin = CampaignDataOrigin.server,
  });

  final Campaign campaign;
  final int revision;
  final bool hasPendingWrites;
  final CampaignDataOrigin origin;

  bool get isFromCache => origin == CampaignDataOrigin.cache;
}

final class CampaignSnapshot {
  CampaignSnapshot({
    required Iterable<StoredCampaign> campaigns,
    required this.origin,
  }) : campaigns = List.unmodifiable(campaigns);

  final List<StoredCampaign> campaigns;
  final CampaignDataOrigin origin;

  bool get isFromCache => origin == CampaignDataOrigin.cache;
  bool get hasPendingWrites =>
      campaigns.any((campaign) => campaign.hasPendingWrites);
}

enum CampaignSaveOperation { create, update, delete }

enum CampaignSaveFailureKind {
  unavailable,
  conflict,
  permissionDenied,
  invalidData,
  unknown,
}

sealed class CampaignSaveResult {
  const CampaignSaveResult();
}

final class CampaignSaveSuccess extends CampaignSaveResult {
  const CampaignSaveSuccess({
    required this.operation,
    required this.campaignId,
    required this.revision,
  });

  final CampaignSaveOperation operation;
  final CampaignId campaignId;
  final int? revision;
}

final class CampaignSaveFailure extends CampaignSaveResult {
  const CampaignSaveFailure({
    required this.operation,
    required this.kind,
    required this.retainedCampaign,
    required this.message,
  });

  final CampaignSaveOperation operation;
  final CampaignSaveFailureKind kind;
  final Campaign retainedCampaign;
  final String message;

  bool get canRetry =>
      kind == CampaignSaveFailureKind.unavailable ||
      kind == CampaignSaveFailureKind.conflict ||
      kind == CampaignSaveFailureKind.unknown;
}

abstract interface class CampaignRepository {
  Future<CampaignSaveResult> create(Campaign campaign);

  Future<StoredCampaign?> getById(CampaignId id);

  Stream<CampaignSnapshot> watchAll();

  Stream<CampaignSnapshot> watchVisitsBetween({
    required LocalDate start,
    required LocalDate end,
  });

  Stream<CampaignSnapshot> watchByPostingStatuses(Set<PostingStatus> statuses);

  Stream<CampaignSnapshot> watchPublished({bool descending = true, int? limit});

  Future<CampaignSaveResult> update(
    Campaign campaign, {
    required int expectedRevision,
  });

  Future<CampaignSaveResult> delete(StoredCampaign storedCampaign);
}
