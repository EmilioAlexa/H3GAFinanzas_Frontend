import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../../auth/auth.dart';
import '../models/servicio_model.dart';
import '../repositories/contratos_repository.dart';

typedef ContractPerson = ({String id, String name});
typedef ContractOptions = ({
  List<ContractPerson> clients,
  List<ContractPerson> advisors,
  List<ServicioModel> services,
  List<({int id, String name})> states,
  String? advisorMessage,
  bool documentsReady,
  List<({int id, String name})> saleTypes,
});

final contratoOptionsProvider = FutureProvider.autoDispose
    .family<ContractOptions, UserRole>((ref, role) async {
  final repository = ref.watch(contratosRepositoryProvider);
  final dio = ref.watch(apiClientProvider);
  String name(Map<String, dynamic> row) => [
        row['nombre'],
        row['apellido_paterno'],
        row['apellido_materno']
      ].whereType<String>().where((s) => s.isNotEmpty).join(' ');
  final options =
      (await dio.get<Map<String, dynamic>>('/finanzas/contratos/opciones'))
          .data!;
  final services = (options['servicios'] as List)
      .map((e) => ServicioModel.fromJson(Map<String, dynamic>.from(e as Map)))
      .toList();
  List<({int id, String name})> catalog(String key) => (options[key] as List)
      .map((e) => (id: (e as Map)['id'] as int, name: e['nombre'] as String))
      .toList();
  final states = catalog('estados');
  final saleTypes = catalog('tipos_venta');
  final clients = await repository.readAll('/clientes');
  var advisors = <ContractPerson>[];
  String? advisorMessage;
  if (role == UserRole.administrador) {
    try {
      final rows = (await dio.get<List<dynamic>>('/usuarios')).data!;
      advisors = rows
          .map((e) => Map<String, dynamic>.from(e as Map))
          .where((e) =>
              e['activo'] == true &&
              (e['roles'] as Map<String, dynamic>)['nombre'] == 'asesor')
          .map((e) => (id: e['id'] as String, name: name(e)))
          .toList();
      if (advisors.isEmpty) {
        advisorMessage = 'No hay asesores activos disponibles.';
      }
    } catch (_) {
      advisorMessage =
          'No se pudieron consultar los asesores. Reintenta la carga.';
    }
  } else if (role == UserRole.administradorFinanciero) {
    advisorMessage =
        'El alta requiere un asesor. Falta un endpoint de asesores autorizado para Administrador Financiero.';
  }
  return (
    clients:
        clients.map((e) => (id: e['id'] as String, name: name(e))).toList(),
    advisors: advisors,
    services: services,
    saleTypes: saleTypes,
    states: states,
    documentsReady: (options['capacidades'] as Map?)?['documentos'] == true,
    advisorMessage: advisorMessage,
  );
});
