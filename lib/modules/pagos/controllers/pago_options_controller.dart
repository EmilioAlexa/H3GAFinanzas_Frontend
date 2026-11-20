import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../../auth/auth.dart';
import '../../contratos/contratos.dart';
import '../models/pago_api_mapping.dart';
import 'pagos_controller.dart';

typedef PagoOption = ({int id, String name});
typedef PaymentReceiver = ({String id, String name});
typedef PagoOptions = ({
  List<ContratoModel> contracts,
  List<PagoOption> methods,
  List<PagoOption> chargeTypes,
  List<PaymentReceiver> receivers,
  String? receiverMessage,
  Object? methodError,
  Object? chargeError,
});

final pagoOptionsProvider =
    FutureProvider.autoDispose.family<PagoOptions, UserRole>((ref, role) async {
  final repository = ref.watch(pagosRepositoryProvider);
  final contractsRepository = ref.watch(contratosRepositoryProvider);
  final session = ref.watch(authControllerProvider).valueOrNull!;
  final contractFuture = contractsRepository.load(role);
  Object? methodError;
  Object? chargeError;
  final methodsFuture = repository
      .readAll('/finanzas/catalogos/formas-pago')
      .catchError((Object error) {
    methodError = error;
    return <Map<String, dynamic>>[];
  });
  final chargesFuture = repository
      .readAll('/finanzas/catalogos/tipos-cobro')
      .catchError((Object error) {
    chargeError = error;
    return <Map<String, dynamic>>[];
  });
  final results = await Future.wait<Object?>(
      [contractFuture, methodsFuture, chargesFuture]);
  final receivers = <PaymentReceiver>[(id: session.id, name: session.name)];
  String? receiverMessage;
  if (role == UserRole.administrador) {
    try {
      final rows =
          (await ref.read(apiClientProvider).get<List<dynamic>>('/usuarios'))
              .data!;
      final users = rows.map(pagoMap).where((e) => e['activo'] == true);
      receivers
        ..clear()
        ..addAll(
            users.map((e) => (id: e['id'] as String, name: pagoPersonName(e))));
    } catch (_) {
      receiverMessage =
          'No se pudo consultar otros receptores. Puedes seleccionar tu propia sesión si recibiste el efectivo.';
    }
  } else {
    receiverMessage =
        'Selecciona tu sesión solo si recibiste el efectivo. Consultar otros receptores requiere un endpoint autorizado.';
  }
  List<PagoOption> options(Object? rows) => (rows as List<Map<String, dynamic>>)
      .map((e) => (id: e['id'] as int, name: e['nombre'] as String))
      .toList();
  return (
    contracts: results[0] as List<ContratoModel>? ?? [],
    methods: options(results[1]),
    chargeTypes: options(results[2]),
    receivers: receivers,
    receiverMessage: receiverMessage,
    methodError: methodError,
    chargeError: chargeError,
  );
});
