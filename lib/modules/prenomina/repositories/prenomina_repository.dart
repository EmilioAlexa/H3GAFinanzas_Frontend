import '../fixtures/prenomina_demo_fixtures.dart';
import '../models/prenomina_model.dart';

class PrenominaRepository {
  List<PrenominaModel> _recipients =
      List<PrenominaModel>.of(PrenominaDemoFixtures.recipients);

  List<PrenominaModel> listDemo() => List.unmodifiable(_recipients);

  List<PrenominaModel> recipientsForCut(String cutId) =>
      List.unmodifiable(_recipients.where((item) => item.cutId == cutId));

  PrenominaModel? findDemo(String id) {
    for (final item in _recipients) {
      if (item.id == id) return item;
    }
    return null;
  }

  void generateDemo(String cutId) {
    final matching = _recipients.where((item) => item.cutId == cutId);
    if (matching.isEmpty) throw StateError('No hay movimientos para generar.');
    if (matching.every((item) => item.status == 'Preparada')) {
      throw StateError('Este corte ya tiene una prenómina demo.');
    }
    _recipients = [
      for (final item in _recipients)
        if (item.cutId == cutId)
          PrenominaModel(
            id: item.id,
            cutId: item.cutId,
            cutName: item.cutName,
            period: item.period,
            recipientId: item.recipientId,
            recipient: item.recipient,
            position: item.position,
            status: 'Preparada',
            movements: item.movements
                .map((movement) => movement.status == 'En preparación'
                    ? movement.copyWithStatus('Incluida')
                    : movement)
                .toList(),
          )
        else
          item,
    ];
  }
}
