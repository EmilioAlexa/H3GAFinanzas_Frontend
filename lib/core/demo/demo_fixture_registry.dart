import '../../modules/auth/auth.dart';
import '../../modules/clientes/clientes.dart';
import '../../modules/comisiones/comisiones.dart';
import '../../modules/contratos/contratos.dart';
import '../../modules/cortes/cortes.dart';
import '../../modules/dashboard/dashboard.dart';
import '../../modules/pagos/pagos.dart';
import '../../modules/prenomina/prenomina.dart';
import '../../modules/reportes/reportes.dart';
import '../../modules/usuarios/usuarios.dart';
import '../../modules/validacion/validacion.dart';
import 'demo_dataset.dart';

abstract final class DemoFixtureRegistry {
  static const all = <String, DemoDataset>{
    'auth': AuthDemoFixtures.dataset,
    'dashboard': DashboardDemoFixtures.dataset,
    'clientes': ClientesDemoFixtures.dataset,
    'contratos': ContratosDemoFixtures.dataset,
    'pagos': PagosDemoFixtures.dataset,
    'validacion': ValidacionDemoFixtures.dataset,
    'comisiones': ComisionesDemoFixtures.dataset,
    'cortes': CortesDemoFixtures.dataset,
    'prenomina': PrenominaDemoFixtures.dataset,
    'reportes': ReportesDemoFixtures.dataset,
    'usuarios': UsuariosDemoFixtures.dataset,
  };

  static DemoDataset forModule(String module) {
    final dataset = all[module];
    if (dataset == null) {
      throw ArgumentError.value(module, 'module', 'Módulo sin fixtures demo');
    }
    return dataset;
  }
}
