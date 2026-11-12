import 'package:decimal/decimal.dart';

enum DashboardMetricIcon {
  chart,
  clock,
  check,
  document,
  briefcase,
  people,
  warning
}

enum DashboardMetricTone { positive, info, warning, soft, navy }

enum DashboardTaskKind {
  validation,
  overdue,
  contract,
  calendar,
  evidence,
  commission
}

enum DashboardActivityKind { success, info, danger, neutral }

typedef DashboardMetric = ({
  String label,
  String value,
  String detail,
  DashboardMetricIcon icon,
  DashboardMetricTone tone,
});

typedef DashboardChartPoint = ({String label, Decimal amount});

typedef DashboardServiceBreakdown = ({
  String label,
  Decimal amount,
  Decimal percentage,
});

typedef DashboardTask = ({
  String title,
  String detail,
  DashboardTaskKind kind,
  String route,
});

typedef DashboardCollection = ({
  DateTime dueDate,
  String client,
  String service,
  String description,
  Decimal amount,
});

typedef DashboardActivity = ({
  String title,
  String detail,
  String elapsed,
  DashboardActivityKind kind,
});

class DashboardModel {
  const DashboardModel({
    required this.isAdvisor,
    required this.metrics,
    this.totalValidated,
    this.periodChange,
    this.periodLabel = '',
    this.weeklyIncome = const [],
    this.serviceBreakdown = const [],
    this.attentionCount = 0,
    this.attentionItems = const [],
    this.collections = const [],
    this.recentActivity = const [],
    this.advisorPriorities = const [],
    this.advisorAgenda = const [],
  });

  final bool isAdvisor;
  final List<DashboardMetric> metrics;
  final Decimal? totalValidated;
  final Decimal? periodChange;
  final String periodLabel;
  final List<DashboardChartPoint> weeklyIncome;
  final List<DashboardServiceBreakdown> serviceBreakdown;
  final int attentionCount;
  final List<DashboardTask> attentionItems;
  final List<DashboardCollection> collections;
  final List<DashboardActivity> recentActivity;
  final List<DashboardTask> advisorPriorities;
  final List<DashboardTask> advisorAgenda;
}
