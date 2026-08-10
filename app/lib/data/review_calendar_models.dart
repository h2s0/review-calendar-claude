import 'package:flutter/material.dart';

/// Presentation-layer models mirroring the shapes in the design
/// prototype's `data.jsx`. These are intentionally simpler than a real
/// domain model (no validation, no persistence) — this phase is about
/// matching the UI with dummy data; a richer domain model + Firestore
/// wiring comes in a later phase.

enum RewardType {
  sponsor('협찬'),
  fee('원고료');

  const RewardType(this.label);
  final String label;
}

enum CampaignStatus { upcoming, urgent, posted }

class Reward {
  const Reward({required this.type, required this.amount});
  final RewardType type;
  final int amount;
}

class Campaign {
  const Campaign({
    required this.id,
    required this.brand,
    required this.category,
    required this.visitStart,
    required this.visitEnd,
    required this.deadline,
    required this.reward,
    required this.alertDays,
    required this.platform,
    required this.status,
    this.notes = '',
    this.posted,
  });

  final String id;
  final String brand;
  final String category;
  final DateTime visitStart;
  final DateTime visitEnd;
  final DateTime deadline;
  final Reward reward;
  final int alertDays;
  final String platform;
  final CampaignStatus status;
  final String notes;
  final DateTime? posted;
}

class ReviewIdea {
  const ReviewIdea({
    required this.id,
    required this.title,
    required this.desc,
    this.plannedDate,
  });

  final String id;
  final String title;
  final String desc;
  final DateTime? plannedDate;
}

class VisitSlotValue {
  const VisitSlotValue({this.date, this.time});
  final DateTime? date;
  final String? time;

  VisitSlotValue copyWith({DateTime? date, String? time}) =>
      VisitSlotValue(date: date ?? this.date, time: time ?? this.time);
}

class VisitWindow {
  const VisitWindow({
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

class UndecidedVisit {
  const UndecidedVisit({
    required this.id,
    required this.campaignId,
    required this.brand,
    required this.category,
    required this.visit,
    required this.deadline,
    required this.visitWindow,
    required this.note,
  });

  final String id;
  final String campaignId;
  final String brand;
  final String category;
  final VisitSlotValue visit;
  final DateTime deadline;
  final VisitWindow visitWindow;
  final String note;
}

enum CalendarEventType { visit, deadline, posted, idea }

class CalendarEvent {
  const CalendarEvent({
    required this.date,
    required this.type,
    required this.label,
    this.campaignId,
    this.freeform = false,
  });

  final DateTime date;
  final CalendarEventType type;
  final String label;
  final String? campaignId;
  final bool freeform;
}

class MonthlyRevenue {
  const MonthlyRevenue({
    required this.month,
    required this.total,
    required this.sponsor,
    required this.fee,
  });
  final String month;
  final int total;
  final int sponsor;
  final int fee;
}

class CategoryRevenue {
  const CategoryRevenue({
    required this.name,
    required this.amount,
    required this.pct,
    required this.color,
  });
  final String name;
  final int amount;
  final int pct;
  final Color color;
}

class RevenueSummary {
  const RevenueSummary({
    required this.total,
    required this.sponsor,
    required this.fee,
    required this.thisMonth,
    required this.lastMonth,
    required this.trend,
    required this.byCategory,
  });
  final int total;
  final int sponsor;
  final int fee;
  final int thisMonth;
  final int lastMonth;
  final List<MonthlyRevenue> trend;
  final List<CategoryRevenue> byCategory;
}

class MonthlyRewardGoals {
  const MonthlyRewardGoals({this.total = 0, this.fee = 0});
  final int total;
  final int fee;

  MonthlyRewardGoals copyWith({int? total, int? fee}) =>
      MonthlyRewardGoals(total: total ?? this.total, fee: fee ?? this.fee);
}
