import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../models/auth_session_model.dart';
import '../repositories/auth_repository.dart';

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepository(
    ref.watch(apiClientProvider),
    ref.watch(tokenStorageProvider),
  ),
);
final authControllerProvider =
    StateNotifierProvider<AuthController, AsyncValue<AuthSessionModel?>>(
  (ref) => AuthController(ref.watch(authRepositoryProvider)),
);

class AuthController extends StateNotifier<AsyncValue<AuthSessionModel?>> {
  AuthController(this._repository) : super(const AsyncData(null));
  final AuthRepository _repository;

  Future<void> restoreSession() async {
    state = const AsyncLoading();
    try {
      state = AsyncData(await _repository.currentUser());
    } catch (_) {
      await _repository.logout();
      state = const AsyncData(null);
    }
  }

  Future<void> login(String email, String password) async {
    state = const AsyncLoading();
    try {
      state = AsyncData(
        await _repository.login(email: email, password: password),
      );
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
    }
  }

  Future<void> logout() async {
    await _repository.logout();
    state = const AsyncData(null);
  }
}
