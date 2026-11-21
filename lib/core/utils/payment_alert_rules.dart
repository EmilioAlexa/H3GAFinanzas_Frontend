/// Read-only presentation rules for payment alerts; no notifications are persisted.
bool needsFinancialReview(String state) => const {
      'Por revisar',
      'Pendiente de revisi?n financiera',
      'Pendiente de autorizaci?n',
    }.contains(state);

/// America/Cancun uses UTC-5. Date-only due dates preserve their civil day.
int daysUntilPayment(DateTime due, DateTime now) {
  final local = now.toUtc().subtract(const Duration(hours: 5));
  return DateTime.utc(due.year, due.month, due.day)
      .difference(DateTime.utc(local.year, local.month, local.day))
      .inDays;
}

bool showsScheduledAlert(String state, DateTime? due, DateTime now) =>
    due != null &&
    const {'Pendiente', 'Vencido'}.contains(state) &&
    daysUntilPayment(due, now) <= 30;
