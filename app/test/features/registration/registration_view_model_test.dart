import 'package:flutter_test/flutter_test.dart';
import 'package:review_calendar/features/campaign/data/fake_campaign_repository.dart';
import 'package:review_calendar/features/registration/domain/campaign_registration_draft.dart';
import 'package:review_calendar/features/registration/presentation/registration_view_model.dart';
import 'package:review_calendar/features/settings/domain/notification_settings.dart';

CampaignRegistrationDraft _validDraft({int? deadlineAlertDaysBefore}) {
  return CampaignRegistrationDraft(
    brand: '르봉 파스타바 성수점',
    visitAvailability: const VisitDateRangeDraft(
      start: '2026-04-18',
      end: '2026-04-18',
    ),
    deadline: '2026-05-02',
    deadlineAlertDaysBefore: deadlineAlertDaysBefore,
  );
}

void main() {
  test(
    'save() carries the chosen deadline alert-days into notificationSettings',
    () async {
      final repository = FakeCampaignRepository();
      final viewModel = RegistrationViewModel(
        repository: repository,
        ownerId: 'user-001',
      );
      addTearDown(viewModel.dispose);

      viewModel.update(_validDraft(deadlineAlertDaysBefore: 5));
      final success = await viewModel.save();

      expect(success, isTrue);
      expect(repository.createCalls, hasLength(1));
      final saved = repository.createCalls.single.notificationSettings.deadline;
      expect(saved, isA<CustomNotification>());
      expect((saved as CustomNotification).schedule.daysBefore, [5]);
    },
  );

  test(
    'save() disables deadline notifications when alerts are turned off',
    () async {
      final repository = FakeCampaignRepository();
      final viewModel = RegistrationViewModel(
        repository: repository,
        ownerId: 'user-001',
      );
      addTearDown(viewModel.dispose);

      viewModel.update(_validDraft());
      final success = await viewModel.save();

      expect(success, isTrue);
      final saved = repository.createCalls.single.notificationSettings.deadline;
      expect(saved, isA<DisableNotification>());
    },
  );
}
