import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/config/env.dart';
import '../../../core/network/api_client.dart';
import '../models/auth_session_model.dart';
import '../models/user_role_model.dart';
import '../repositories/auth_repository.dart';

final demoRoleProvider = StateProvider<UserRole>(
  (ref) => UserRole.administrador,
);

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepository(
    ref.watch(apiClientProvider),
    ref.watch(tokenStorageProvider),
  ),
);
final authControllerProvider =
    StateNotifierProvider<AuthController, AsyncValue<AuthSessionModel?>>(
  (ref) => AuthController(
    ref.watch(authRepositoryProvider),
    demoMode: AppEnv.demoMode,
    demoRole: ref.watch(demoRoleProvider),
  ),
);

class AuthController extends StateNotifier<AsyncValue<AuthSessionModel?>> {
  AuthController(
    this._repository, {
    required this.demoMode,
    required this.demoRole,
  }) : super(const AsyncData(null));

  final AuthRepository _repository;
  final bool demoMode;
  final UserRole demoRole;

  Future<void> restoreSession() async {
    if (demoMode) {
      state = const AsyncData(null);
      return;
    }

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
      if (demoMode) {
        await Future<void>.delayed(const Duration(milliseconds: 400));
        state = AsyncData(_demoSession());
        return;
      }
      state = AsyncData(
        await _repository.login(email: email, password: password),
      );
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
    }
  }

  Future<void> logout() async {
    if (demoMode) {
      state = const AsyncData(null);
      return;
    }
    await _repository.logout();
    state = const AsyncData(null);
  }

  AuthSessionModel _demoSession() => AuthSessionModel(
        id: 'demo-${demoRole.name}',
        name: 'Usuario de demostración',
        email: 'demo@h3ga.local',
        role: demoRole,
      );
}
