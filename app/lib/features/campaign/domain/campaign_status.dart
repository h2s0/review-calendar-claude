import 'package:review_calendar/features/campaign/domain/local_date.dart';

enum VisitStatus { unscheduled, scheduled, visited, stopped }

enum PostingStatus {
  pending,
  writing,
  overdue,
  published,
  stopped;

  bool get canBeStored => this != PostingStatus.overdue;
}

final class CampaignStatus {
  CampaignStatus({required this.visit, required this.posting}) {
    if (!posting.canBeStored) {
      throw ArgumentError('PostingStatus.overdue is computed, not stored.');
    }
    if ((visit == VisitStatus.stopped) != (posting == PostingStatus.stopped)) {
      throw ArgumentError(
        'Stopped visit and posting states must move together.',
      );
    }
    if (posting == PostingStatus.published && visit != VisitStatus.visited) {
      throw ArgumentError('A published campaign must have been visited.');
    }
  }

  final VisitStatus visit;
  final PostingStatus posting;

  bool get isActive =>
      visit != VisitStatus.stopped && posting != PostingStatus.stopped;
}

enum CampaignTransition {
  scheduleVisit,
  unscheduleVisit,
  markVisited,
  startWriting,
  publish,
  stop,
  delete,
}

enum CampaignEffect {
  cancelVisitNotifications,
  cancelDeadlineNotifications,
  includeInRevenue,
  removeFromRevenue,
  removeFromActiveViews,
  deleteCampaignData,
}

sealed class CampaignTransitionResult {
  const CampaignTransitionResult();
}

final class CampaignTransitionSuccess extends CampaignTransitionResult {
  const CampaignTransitionSuccess({
    required this.status,
    this.effects = const {},
  });

  final CampaignStatus status;
  final Set<CampaignEffect> effects;
}

final class CampaignTransitionFailure extends CampaignTransitionResult {
  const CampaignTransitionFailure({
    required this.transition,
    required this.currentStatus,
    required this.reason,
  });

  final CampaignTransition transition;
  final CampaignStatus currentStatus;
  final String reason;
}

CampaignTransitionResult applyCampaignTransition({
  required CampaignStatus current,
  required CampaignTransition transition,
}) {
  CampaignTransitionSuccess success(
    VisitStatus visit,
    PostingStatus posting, {
    Set<CampaignEffect> effects = const {},
  }) {
    return CampaignTransitionSuccess(
      status: CampaignStatus(visit: visit, posting: posting),
      effects: effects,
    );
  }

  CampaignTransitionFailure failure(String reason) {
    return CampaignTransitionFailure(
      transition: transition,
      currentStatus: current,
      reason: reason,
    );
  }

  return switch (transition) {
    CampaignTransition.scheduleVisit
        when current.visit == VisitStatus.unscheduled &&
            current.posting == PostingStatus.pending =>
      success(VisitStatus.scheduled, PostingStatus.pending),
    CampaignTransition.unscheduleVisit
        when current.visit == VisitStatus.scheduled &&
            current.posting == PostingStatus.pending =>
      success(VisitStatus.unscheduled, PostingStatus.pending),
    CampaignTransition.markVisited
        when (current.visit == VisitStatus.unscheduled ||
                current.visit == VisitStatus.scheduled) &&
            current.posting == PostingStatus.pending =>
      success(VisitStatus.visited, PostingStatus.writing),
    CampaignTransition.startWriting
        when current.visit == VisitStatus.visited &&
            current.posting == PostingStatus.pending =>
      success(VisitStatus.visited, PostingStatus.writing),
    CampaignTransition.publish
        when current.visit == VisitStatus.visited &&
            current.posting == PostingStatus.writing =>
      success(
        VisitStatus.visited,
        PostingStatus.published,
        effects: {
          CampaignEffect.cancelDeadlineNotifications,
          CampaignEffect.includeInRevenue,
        },
      ),
    CampaignTransition.stop
        when current.visit != VisitStatus.stopped &&
            current.posting != PostingStatus.published =>
      success(
        VisitStatus.stopped,
        PostingStatus.stopped,
        effects: {
          CampaignEffect.cancelVisitNotifications,
          CampaignEffect.cancelDeadlineNotifications,
          CampaignEffect.removeFromRevenue,
          CampaignEffect.removeFromActiveViews,
        },
      ),
    CampaignTransition.delete => success(
      current.visit,
      current.posting,
      effects: {
        CampaignEffect.cancelVisitNotifications,
        CampaignEffect.cancelDeadlineNotifications,
        CampaignEffect.removeFromRevenue,
        CampaignEffect.removeFromActiveViews,
        CampaignEffect.deleteCampaignData,
      },
    ),
    _ => failure(
      '${transition.name} is not allowed from '
      '${current.visit.name}/${current.posting.name}.',
    ),
  };
}

PostingStatus resolvePostingStatus({
  required PostingStatus storedStatus,
  required LocalDate deadline,
  required LocalDate today,
}) {
  if (!storedStatus.canBeStored) {
    throw ArgumentError('PostingStatus.overdue must not be stored.');
  }
  if (storedStatus == PostingStatus.pending ||
      storedStatus == PostingStatus.writing) {
    if (today.compareTo(deadline) > 0) {
      return PostingStatus.overdue;
    }
  }
  return storedStatus;
}
