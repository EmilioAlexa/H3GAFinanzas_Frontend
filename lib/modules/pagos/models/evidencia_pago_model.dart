import 'dart:typed_data';
import 'pago_api_mapping.dart';

class EvidenciaPagoModel {
  const EvidenciaPagoModel({
    required this.id,
    required this.name,
    required this.mimeType,
    required this.sizeBytes,
    required this.uploadedAt,
    this.tipoCompatibleConMetodo = false,
    this.demoOnly = true,
    this.previewBytes,
    this.vigente = true,
    this.tipoNombre,
  });

  factory EvidenciaPagoModel.fromJson(Map<String, dynamic> json,
      {String? method}) {
    final type = pagoMap(json['tipos_evidencia_pago'])['nombre'] as String?;
    final active = json['vigente'] == true;
    return EvidenciaPagoModel(
      id: json['id'] as String,
      name: json['nombre_original'] as String? ?? 'Evidencia sin nombre',
      mimeType: json['tipo_archivo'] as String? ?? 'application/octet-stream',
      sizeBytes: json['tamano_bytes'] as int?,
      uploadedAt: pagoInstant(json['fecha_carga']),
      demoOnly: false,
      vigente: active,
      tipoNombre: type,
      tipoCompatibleConMetodo:
          active && type != null && type == requiredEvidenceType(method ?? ''),
    );
  }

  final bool vigente;
  final String? tipoNombre;
  final String id;
  final String name;
  final String mimeType;
  final int? sizeBytes;
  final DateTime? uploadedAt;
  final bool tipoCompatibleConMetodo;
  final bool demoOnly;
  final Uint8List? previewBytes;
}
