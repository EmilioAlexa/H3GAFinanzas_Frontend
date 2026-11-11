import 'package:dio/dio.dart';

class ApiErrorModel {
  const ApiErrorModel({
    required this.message,
    this.statusCode,
    this.isNetwork = false,
  });

  final String message;
  final int? statusCode;
  final bool isNetwork;

  factory ApiErrorModel.fromObject(Object error) {
    if (error is DioException) {
      if (error.response?.statusCode == 403) {
        return const ApiErrorModel(
          message: 'No tienes permiso para realizar esta acción.',
          statusCode: 403,
        );
      }
      if (error.response?.statusCode == 401) {
        return const ApiErrorModel(
          message: 'Tu sesión expiró. Inicia sesión nuevamente.',
          statusCode: 401,
        );
      }
      if (error.response == null) {
        return const ApiErrorModel(
          message: 'No se pudo conectar con el servidor.',
          isNetwork: true,
        );
      }
      return ApiErrorModel(
        message: 'Ocurrió un error al procesar la solicitud.',
        statusCode: error.response?.statusCode,
      );
    }
    return const ApiErrorModel(message: 'Ocurrió un error inesperado.');
  }
}
