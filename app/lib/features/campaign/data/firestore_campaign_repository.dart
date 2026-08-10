import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:review_calendar/features/campaign/data/campaign_repository.dart';
import 'package:review_calendar/features/campaign/data/firestore_campaign_document_codec.dart';
import 'package:review_calendar/features/campaign/domain/campaign.dart';
import 'package:review_calendar/features/campaign/domain/campaign_id.dart';
import 'package:review_calendar/features/campaign/domain/campaign_status.dart';
import 'package:review_calendar/features/campaign/domain/local_date.dart';

final class FirestoreCampaignRepository implements CampaignRepository {
  FirestoreCampaignRepository({
    required FirebaseFirestore firestore,
    required UserId currentUserId,
    this._codec = const FirestoreCampaignDocumentCodec(),
  }) : _campaigns = firestore
           .collection('users')
           .doc(currentUserId.value)
           .collection('campaigns'),
       _currentUserId = currentUserId;

  final CollectionReference<Map<String, dynamic>> _campaigns;
  final UserId _currentUserId;
  final FirestoreCampaignDocumentCodec _codec;

  @override
  Future<CampaignSaveResult> create(Campaign campaign) async {
    if (!_owns(campaign)) {
      return _invalidOwner(CampaignSaveOperation.create, campaign);
    }
    try {
      final document = _codec.encodeCreate(campaign);
      await _campaigns.doc(campaign.id.value).set(document);
      return CampaignSaveSuccess(
        operation: CampaignSaveOperation.create,
        campaignId: campaign.id,
        revision: 1,
      );
    } on FirebaseException catch (error) {
      return _firebaseFailure(CampaignSaveOperation.create, campaign, error);
    } on Object {
      return _unknownFailure(CampaignSaveOperation.create, campaign);
    }
  }

  @override
  Future<StoredCampaign?> getById(CampaignId id) async {
    final snapshot = await _campaigns.doc(id.value).get();
    if (!snapshot.exists) {
      return null;
    }
    return _storedCampaign(snapshot);
  }

  @override
  Stream<CampaignSnapshot> watchAll() {
    return _watch(_campaigns.orderBy('deadline'));
  }

  @override
  Stream<CampaignSnapshot> watchVisitsBetween({
    required LocalDate start,
    required LocalDate end,
  }) {
    if (end.compareTo(start) < 0) {
      throw ArgumentError.value(end, 'end', 'must not precede start');
    }
    return _watch(
      _campaigns
          .where('visit.date', isGreaterThanOrEqualTo: start.toString())
          .where('visit.date', isLessThanOrEqualTo: end.toString())
          .orderBy('visit.date'),
    );
  }

  @override
  Stream<CampaignSnapshot> watchByPostingStatuses(Set<PostingStatus> statuses) {
    if (statuses.isEmpty || statuses.length > 10) {
      throw ArgumentError.value(
        statuses,
        'statuses',
        'must contain between 1 and 10 values',
      );
    }
    if (statuses.any((status) => !status.canBeStored)) {
      throw ArgumentError.value(
        statuses,
        'statuses',
        'must contain only stored statuses',
      );
    }
    return _watch(
      _campaigns
          .where(
            'postingStatus',
            whereIn: statuses.map((status) => status.name).toList(),
          )
          .orderBy('deadline'),
    );
  }

  @override
  Stream<CampaignSnapshot> watchPublished({
    bool descending = true,
    int? limit,
  }) {
    Query<Map<String, dynamic>> query = _campaigns
        .where('postingStatus', isEqualTo: PostingStatus.published.name)
        .orderBy('publishedDate', descending: descending);
    if (limit != null) {
      query = query.limit(limit);
    }
    return _watch(query);
  }

  @override
  Future<CampaignSaveResult> update(
    Campaign campaign, {
    required int expectedRevision,
  }) async {
    if (!_owns(campaign)) {
      return _invalidOwner(CampaignSaveOperation.update, campaign);
    }
    final reference = _campaigns.doc(campaign.id.value);
    try {
      final nextRevision = await _campaigns.firestore.runTransaction<int>((
        transaction,
      ) async {
        final current = await transaction.get(reference);
        final currentData = current.data();
        if (currentData == null ||
            currentData['revision'] != expectedRevision) {
          throw const _CampaignConflict();
        }
        final document = _codec.encodeUpdate(
          campaign,
          storedCreatedAt: currentData['createdAt'],
          storedClientCreatedAt: currentData['clientCreatedAt'],
          nextRevision: expectedRevision + 1,
        );
        transaction.set(reference, document);
        return expectedRevision + 1;
      });
      return CampaignSaveSuccess(
        operation: CampaignSaveOperation.update,
        campaignId: campaign.id,
        revision: nextRevision,
      );
    } on _CampaignConflict {
      return _conflictFailure(CampaignSaveOperation.update, campaign);
    } on FirebaseException catch (error) {
      return _firebaseFailure(CampaignSaveOperation.update, campaign, error);
    } on Object {
      return _unknownFailure(CampaignSaveOperation.update, campaign);
    }
  }

  @override
  Future<CampaignSaveResult> delete(StoredCampaign storedCampaign) async {
    final campaign = storedCampaign.campaign;
    if (!_owns(campaign)) {
      return _invalidOwner(CampaignSaveOperation.delete, campaign);
    }
    final reference = _campaigns.doc(campaign.id.value);
    try {
      await _campaigns.firestore.runTransaction<void>((transaction) async {
        final current = await transaction.get(reference);
        if (!current.exists ||
            current.data()?['revision'] != storedCampaign.revision) {
          throw const _CampaignConflict();
        }
        transaction.delete(reference);
      });
      return CampaignSaveSuccess(
        operation: CampaignSaveOperation.delete,
        campaignId: campaign.id,
        revision: null,
      );
    } on _CampaignConflict {
      return _conflictFailure(CampaignSaveOperation.delete, campaign);
    } on FirebaseException catch (error) {
      return _firebaseFailure(CampaignSaveOperation.delete, campaign, error);
    } on Object {
      return _unknownFailure(CampaignSaveOperation.delete, campaign);
    }
  }

  Stream<CampaignSnapshot> _watch(Query<Map<String, dynamic>> query) {
    return query
        .snapshots(includeMetadataChanges: true)
        .map(
          (snapshot) => CampaignSnapshot(
            campaigns: snapshot.docs.map(_storedCampaign),
            origin: snapshot.metadata.isFromCache
                ? CampaignDataOrigin.cache
                : CampaignDataOrigin.server,
          ),
        );
  }

  StoredCampaign _storedCampaign(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    return _codec.decode(
      snapshot.data()!,
      documentId: snapshot.id,
      isFromCache: snapshot.metadata.isFromCache,
      hasPendingWrites: snapshot.metadata.hasPendingWrites,
    );
  }

  bool _owns(Campaign campaign) =>
      campaign.ownerId.value == _currentUserId.value;

  CampaignSaveFailure _invalidOwner(
    CampaignSaveOperation operation,
    Campaign campaign,
  ) {
    return CampaignSaveFailure(
      operation: operation,
      kind: CampaignSaveFailureKind.invalidData,
      retainedCampaign: campaign,
      message: '현재 사용자와 일정 소유자가 일치하지 않아요.',
    );
  }

  CampaignSaveFailure _conflictFailure(
    CampaignSaveOperation operation,
    Campaign campaign,
  ) {
    return CampaignSaveFailure(
      operation: operation,
      kind: CampaignSaveFailureKind.conflict,
      retainedCampaign: campaign,
      message: '다른 변경이 먼저 저장됐어요. 최신 내용을 확인해 주세요.',
    );
  }

  CampaignSaveFailure _firebaseFailure(
    CampaignSaveOperation operation,
    Campaign campaign,
    FirebaseException error,
  ) {
    final kind = switch (error.code) {
      'unavailable' ||
      'deadline-exceeded' ||
      'failed-precondition' => CampaignSaveFailureKind.unavailable,
      'permission-denied' ||
      'unauthenticated' => CampaignSaveFailureKind.permissionDenied,
      'aborted' ||
      'already-exists' ||
      'not-found' => CampaignSaveFailureKind.conflict,
      'invalid-argument' => CampaignSaveFailureKind.invalidData,
      _ => CampaignSaveFailureKind.unknown,
    };
    return CampaignSaveFailure(
      operation: operation,
      kind: kind,
      retainedCampaign: campaign,
      message: switch (kind) {
        CampaignSaveFailureKind.unavailable => '연결을 확인한 뒤 다시 저장해 주세요.',
        CampaignSaveFailureKind.conflict => '다른 변경이 먼저 저장됐어요. 최신 내용을 확인해 주세요.',
        CampaignSaveFailureKind.permissionDenied => '이 일정을 저장할 권한이 없어요.',
        CampaignSaveFailureKind.invalidData => '입력 내용을 다시 확인해 주세요.',
        CampaignSaveFailureKind.unknown => '저장하지 못했어요. 입력 내용은 유지했어요.',
      },
    );
  }

  CampaignSaveFailure _unknownFailure(
    CampaignSaveOperation operation,
    Campaign campaign,
  ) {
    return CampaignSaveFailure(
      operation: operation,
      kind: CampaignSaveFailureKind.unknown,
      retainedCampaign: campaign,
      message: '저장하지 못했어요. 입력 내용은 유지했어요.',
    );
  }
}

final class _CampaignConflict implements Exception {
  const _CampaignConflict();
}
