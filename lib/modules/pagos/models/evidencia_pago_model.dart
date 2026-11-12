class EvidenciaPagoModel {
  const EvidenciaPagoModel({
    required this.id,
    required this.name,
    required this.mimeType,
    required this.sizeBytes,
    required this.uploadedAt,
    this.demoOnly = true,
  });

  final String id;
  final String name;
  final String mimeType;
  final int sizeBytes;
  final DateTime uploadedAt;
  final bool demoOnly;
}
