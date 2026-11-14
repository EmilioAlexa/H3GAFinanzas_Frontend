import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/config/env.dart';
import '../../../core/network/api_client.dart';
import '../../auth/auth.dart';
import '../../clientes/clientes.dart';
import '../../contratos/contratos.dart';
import '../../pagos/pagos.dart';
import '../models/global_search_hit_model.dart';

final globalSearchRepositoryProvider = Provider<GlobalSearchRepository>(
  (ref) => GlobalSearchRepository(
    dio: ref.watch(apiClientProvider),
    demoMode: AppEnv.demoMode,
  ),
);

class GlobalSearchRepository {
  const GlobalSearchRepository({required this.dio, required this.demoMode});

  final Dio dio;
  final bool demoMode;

  Future<List<GlobalSearchHitModel>> search(String query, UserRole role) async {
    final normalizedQuery = _normalize(query);
    if (normalizedQuery.length < 2) return const [];
    return demoMode
        ? _searchDemo(normalizedQuery, role)
        : _searchApi(query.trim());
  }

  List<GlobalSearchHitModel> _searchDemo(String query, UserRole role) {
    final hits = <GlobalSearchHitModel>[];
    final clients = ClientesDemoFixtures.clients.where((client) =>
        role != UserRole.asesor ||
        (client.demoMetadata?.assignedToCurrentAdvisor ?? false));
    for (final client in clients) {
      if (_matches(query, [
        client.nombreCompleto,
        client.correoElectronico,
      ])) {
        hits.add(GlobalSearchHitModel(
          id: client.id,
          title: client.nombreCompleto,
          subtitle: [
            client.telefono,
            client.correoElectronico,
          ].whereType<String>().where((value) => value.isNotEmpty).join(' · '),
          route: '/clientes/${client.id}',
          type: GlobalSearchHitType.cliente,
        ));
      }
    }

    final contracts = ContratosDemoFixtures.contracts.where((contract) =>
        role != UserRole.asesor || contract.assignedToCurrentAdvisor);
    for (final contract in contracts) {
      if (_matches(query, [contract.folio, contract.clienteNombre])) {
        hits.add(GlobalSearchHitModel(
          id: contract.id,
          title: contract.folio,
          subtitle: '${contract.clienteNombre} · ${contract.servicioNombre}',
          route: '/contratos/${contract.id}',
          type: GlobalSearchHitType.contrato,
        ));
      }
    }

    final payments = PagosDemoFixtures.payments.where((payment) =>
        role != UserRole.asesor || payment.assignedToCurrentAdvisor);
    for (final payment in payments) {
      if (_matches(query, [
        payment.folio,
        payment.referencia,
        payment.folioRecibo,
        payment.clienteNombre,
      ])) {
        hits.add(GlobalSearchHitModel(
          id: payment.id,
          title: payment.folio,
          subtitle: '${payment.clienteNombre} · ${payment.contratoFolio}',
          route: '/pagos/${payment.id}',
          type: GlobalSearchHitType.pago,
        ));
      }
    }
    return hits.take(12).toList(growable: false);
  }

  Future<List<GlobalSearchHitModel>> _searchApi(String query) async {
    final responses = await Future.wait([
      dio.get<Map<String, dynamic>>(
        _apiPath('/clientes'),
        queryParameters: {'page': 1, 'limit': 5, 'q': query},
      ),
      dio.get<Map<String, dynamic>>(
        _apiPath('/finanzas/contratos'),
        queryParameters: {'page': 1, 'limit': 5, 'q': _bounded(query, 50)},
      ),
      dio.get<Map<String, dynamic>>(
        _apiPath('/finanzas/pagos'),
        queryParameters: {'page': 1, 'limit': 5, 'q': _bounded(query, 100)},
      ),
    ]);

    final clientRecords = _records(responses[0].data);
    final clientIds = clientRecords
        .map((record) => _string(record['id']))
        .where((id) => id.isNotEmpty)
        .toSet();
    final relatedContracts = clientIds.isEmpty
        ? <Response<Map<String, dynamic>>>[]
        : await Future.wait([
            for (final clientId in clientIds)
              dio.get<Map<String, dynamic>>(
                _apiPath('/finanzas/contratos'),
                queryParameters: {
                  'page': 1,
                  'limit': 5,
                  'cliente_id': clientId,
                },
              ),
          ]);
    final relatedPayments = clientIds.isEmpty
        ? <Response<Map<String, dynamic>>>[]
        : await Future.wait([
            for (final clientId in clientIds)
              dio.get<Map<String, dynamic>>(
                _apiPath('/finanzas/pagos'),
                queryParameters: {
                  'page': 1,
                  'limit': 5,
                  'cliente_id': clientId,
                },
              ),
          ]);

    final hits = <GlobalSearchHitModel>[];
    for (final record in clientRecords) {
      final id = _string(record['id']);
      final title = [
        record['nombre'],
        record['apellido_paterno'],
        record['apellido_materno'],
      ].map(_string).where((part) => part.isNotEmpty).join(' ');
      if (id.isEmpty || title.isEmpty) continue;
      hits.add(GlobalSearchHitModel(
        id: id,
        title: title,
        subtitle: _string(record['correo_electronico']).isNotEmpty
            ? _string(record['correo_electronico'])
            : _string(record['telefono']),
        route: '/clientes/$id',
        type: GlobalSearchHitType.cliente,
      ));
    }

    final contractIds = <String>{};
    final contractRecords = [
      ..._records(responses[1].data),
      for (final response in relatedContracts) ..._records(response.data),
    ];
    for (final record in contractRecords) {
      final id = _string(record['id']);
      final folio = _string(record['folio']);
      if (id.isEmpty || folio.isEmpty || !contractIds.add(id)) continue;
      final client = _map(record['clientes']);
      final clientName = [
        client['nombre'],
        client['apellido_paterno'],
        client['apellido_materno'],
      ].map(_string).where((part) => part.isNotEmpty).join(' ');
      final serviceName = _string(_map(record['servicios'])['nombre']);
      hits.add(GlobalSearchHitModel(
        id: id,
        title: folio,
        subtitle: [clientName, serviceName]
            .where((value) => value.isNotEmpty)
            .join(' · '),
        route: '/contratos/$id',
        type: GlobalSearchHitType.contrato,
      ));
    }

    final paymentIds = <String>{};
    final paymentRecords = [
      ..._records(responses[2].data),
      for (final response in relatedPayments) ..._records(response.data),
    ];
    for (final record in paymentRecords) {
      final id = _string(record['id']);
      if (id.isEmpty || !paymentIds.add(id)) continue;
      final contract = _map(record['contratos']);
      final client = _map(contract['clientes']);
      final clientName = [
        client['nombre'],
        client['apellido_paterno'],
        client['apellido_materno'],
      ].map(_string).where((part) => part.isNotEmpty).join(' ');
      final paymentReference = _string(record['folio_recibo']).isNotEmpty
          ? _string(record['folio_recibo'])
          : _string(record['referencia_pago']);
      final folio = _string(contract['folio']);
      final title = paymentReference.isNotEmpty
          ? paymentReference
          : (folio.isNotEmpty ? 'Pago · $folio' : 'Pago');
      hits.add(GlobalSearchHitModel(
        id: id,
        title: title,
        subtitle:
            [clientName, folio].where((value) => value.isNotEmpty).join(' · '),
        route: '/pagos/$id',
        type: GlobalSearchHitType.pago,
      ));
    }
    return hits.take(12).toList(growable: false);
  }

  String _apiPath(String path) =>
      '${dio.options.baseUrl.replaceFirst(RegExp(r'/+$'), '')}$path';

  List<Map<String, dynamic>> _records(Map<String, dynamic>? response) {
    final values = response?['data'];
    if (values is! List) return const [];
    return values
        .whereType<Map<Object?, Object?>>()
        .map((value) => _map(value))
        .toList();
  }

  Map<String, dynamic> _map(Object? value) => value is Map<Object?, Object?>
      ? value.map((key, item) => MapEntry(key.toString(), item))
      : const {};

  String _string(Object? value) => value is String ? value.trim() : '';

  String _bounded(String value, int maxLength) =>
      value.length <= maxLength ? value : value.substring(0, maxLength);

  bool _matches(String query, Iterable<String?> values) => values
      .whereType<String>()
      .any((value) => _normalize(value).contains(query));

  String _normalize(String value) => value
      .trim()
      .toLowerCase()
      .replaceAll(RegExp('[áàäâ]'), 'a')
      .replaceAll(RegExp('[éèëê]'), 'e')
      .replaceAll(RegExp('[íìïî]'), 'i')
      .replaceAll(RegExp('[óòöô]'), 'o')
      .replaceAll(RegExp('[úùüû]'), 'u')
      .replaceAll('ñ', 'n');
}
