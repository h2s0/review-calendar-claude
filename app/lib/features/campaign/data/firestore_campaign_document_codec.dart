import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:review_calendar/features/campaign/data/campaign_document_mapper.dart';
import 'package:review_calendar/features/campaign/data/campaign_repository.dart';
import 'package:review_calendar/features/campaign/domain/campaign.dart';

final class FirestoreCampaignDocumentCodec {
  const FirestoreCampaignDocumentCodec({
    this.mapper = const CampaignDocumentMapper(),
  });

  final CampaignDocumentMapper mapper;

  Map<String, Object?> encodeCreate(Campaign campaign) {
    final document = mapper.toDocument(campaign);
    document
      ..['clientCreatedAt'] = campaign.createdAt.toIso8601String()
      ..['clientUpdatedAt'] = campaign.updatedAt.toIso8601String()
      ..['createdAt'] = FieldValue.serverTimestamp()
      ..['updatedAt'] = FieldValue.serverTimestamp()
      ..['revision'] = 1;
    return document;
  }

  Map<String, Object?> encodeUpdate(
    Campaign campaign, {
    required Object? storedCreatedAt,
    required Object? storedClientCreatedAt,
    required int nextRevision,
  }) {
    final document = mapper.toDocument(campaign);
    document
      ..['clientCreatedAt'] =
          storedClientCreatedAt ?? campaign.createdAt.toIso8601String()
      ..['clientUpdatedAt'] = campaign.updatedAt.toIso8601String()
      ..['createdAt'] = storedCreatedAt
      ..['updatedAt'] = FieldValue.serverTimestamp()
      ..['revision'] = nextRevision;
    return document;
  }

  StoredCampaign decode(
    Map<String, Object?> rawDocument, {
    required String documentId,
    required bool isFromCache,
    required bool hasPendingWrites,
  }) {
    final document = Map<String, Object?>.from(rawDocument);
    document['id'] = documentId;
    for (final (field, fallbackField) in [
      ('createdAt', 'clientCreatedAt'),
      ('updatedAt', 'clientUpdatedAt'),
    ]) {
      if (document[field] case final Timestamp timestamp) {
        document[field] = timestamp.toDate().toUtc().toIso8601String();
      } else if (document[fallbackField] case final String fallback) {
        document[field] = fallback;
      }
    }

    final revision = document['revision'];
    if (revision is! int || revision < 1) {
      throw const FormatException('revision must be a positive integer.');
    }
    return StoredCampaign(
      campaign: mapper.fromDocument(document),
      revision: revision,
      hasPendingWrites: hasPendingWrites,
      origin: isFromCache
          ? CampaignDataOrigin.cache
          : CampaignDataOrigin.server,
    );
  }
}
