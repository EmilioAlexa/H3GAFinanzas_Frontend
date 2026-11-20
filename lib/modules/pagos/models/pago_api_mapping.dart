Map<String, dynamic> pagoMap(Object? value) =>
    value is Map ? Map<String, dynamic>.from(value) : {};

String pagoPersonName(Object? value) {
  final row = pagoMap(value);
  return [row['nombre'], row['apellido_paterno'], row['apellido_materno']]
      .whereType<String>()
      .where((s) => s.isNotEmpty)
      .join(' ');
}

DateTime? pagoDate(Object? value) =>
    value == null ? null : DateTime.parse(value as String);
DateTime? pagoInstant(Object? value) => pagoDate(value)?.toLocal();

String? requiredEvidenceType(String method) {
  final name = method.toLowerCase().replaceAll('ó', 'o').replaceAll('é', 'e');
  if (name.contains('efectivo')) return 'Comprobante de efectivo';
  if (name.contains('transferencia') || name.contains('deposito')) {
    return 'Comprobante bancario';
  }
  if (name.contains('cheque')) return 'Comprobante de cheque';
  return null;
}
