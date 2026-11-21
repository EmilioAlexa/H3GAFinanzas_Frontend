import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'api_client.dart';

final finanzasApiProvider =
    Provider((ref) => FinanzasApi(ref.watch(apiClientProvider)));

/// Financial decisions and calculations remain exclusively in NestJS.
class FinanzasApi {
  FinanzasApi(this.dio);
  final Dio dio;

  Future<List<Map<String, dynamic>>> list(String path,
      {Map<String, dynamic> filters = const {}}) async {
    final rows = <Map<String, dynamic>>[];
    var page = 1;
    while (true) {
      final response = await dio.get<dynamic>(path,
          queryParameters: {...filters, 'page': page, 'limit': 100});
      final body = response.data;
      if (body is List) return body.map(apiMap).toList();
      final data = apiMap(body);
      if (data['data'] is! List) {
        throw const FormatException('Respuesta sin data');
      }
      final batch = (data['data'] as List).map(apiMap).toList();
      rows.addAll(batch);
      final total = data['total'] ?? apiMap(data['pagination'])['total'];
      if (batch.isEmpty ||
          total is num && rows.length >= total ||
          total == null && batch.length < 100) {
        break;
      }
      page++;
    }
    return rows;
  }

  Future<Map<String, dynamic>> detail(String path) async =>
      apiMap((await dio.get<dynamic>(path)).data);
  Future<List<Map<String, dynamic>>> configuration(String contractId) =>
      list('/finanzas/contratos/$contractId/comisiones');
  Future<List<Map<String, dynamic>>> configurationHistory(String contractId) =>
      list('/finanzas/contratos/$contractId/comisiones/historial');
  Future<void> saveConfiguration(
      String contractId, List<Map<String, Object?>> lines) async {
    await dio.put<dynamic>('/finanzas/contratos/$contractId/comisiones',
        data: {'configuracion': lines});
  }

  Future<void> createReceiver(Map<String, Object?> payload) async {
    await dio.post<dynamic>('/finanzas/receptores-dispersion', data: payload);
  }

  Future<void> deactivateReceiver(String id) async {
    await dio.patch<dynamic>('/finanzas/receptores-dispersion/$id/desactivar');
  }

  Future<Map<String, dynamic>> disperse(
      {required String commissionId,
      required String idempotencyKey,
      required String reference,
      required Uint8List bytes,
      required String fileName}) async {
    final response =
        await dio.put<dynamic>('/finanzas/comisiones/$commissionId/dispersar',
            data: FormData.fromMap({
              'idempotency_key': idempotencyKey,
              'referencia_transferencia': reference,
              'file': MultipartFile.fromBytes(bytes, filename: fileName)
            }));
    return apiMap(response.data);
  }

  Future<Uint8List> proof(String dispersionId) async {
    final response = await dio.get<List<int>>(
        '/finanzas/dispersiones-comision/$dispersionId/comprobante',
        options: Options(responseType: ResponseType.bytes));
    return Uint8List.fromList(response.data!);
  }

  Future<Map<String, dynamic>> createCut(String civilFriday) async =>
      apiMap((await dio.post<dynamic>('/finanzas/cortes',
              data: {'periodo_inicio': civilFriday}))
          .data);
  Future<Map<String, dynamic>> cutAction(
      String id, String action, String comment) async {
    if (!{'generar', 'cerrar', 'cancelar'}.contains(action)) {
      throw ArgumentError.value(action);
    }
    return apiMap((await dio.post<dynamic>('/finanzas/cortes/$id/$action',
            data: {'comentario': comment}))
        .data);
  }

  Future<Map<String, dynamic>> generatePayroll(
          String cutId, int stateId, String? observations) async =>
      apiMap((await dio.post<dynamic>(
              '/finanzas/cortes/$cutId/prenomina/generar',
              data: {
            'estado_id': stateId,
            if (observations != null) 'observaciones': observations
          }))
          .data);
}

Map<String, dynamic> apiMap(Object? value) => value is Map
    ? value.map((key, value) => MapEntry(key.toString(), value))
    : {};
String apiText(Object? value) => value?.toString() ?? '';
