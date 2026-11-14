import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/auth.dart';
import '../models/global_search_hit_model.dart';
import '../repositories/global_search_repository.dart';

final globalSearchControllerProvider = StateNotifierProvider.family<
    GlobalSearchController, AsyncValue<List<GlobalSearchHitModel>>, UserRole>(
  (ref, role) => GlobalSearchController(
    ref.watch(globalSearchRepositoryProvider),
    role,
  ),
);

class GlobalSearchController
    extends StateNotifier<AsyncValue<List<GlobalSearchHitModel>>> {
  GlobalSearchController(this._repository, this._role)
      : super(const AsyncData([]));

  final GlobalSearchRepository _repository;
  final UserRole _role;
  Timer? _debounce;
  var _requestId = 0;

  void search(String query) {
    _debounce?.cancel();
    final value = query.trim();
    _requestId++;
    if (value.length < 2) {
      state = const AsyncData([]);
      return;
    }
    state = const AsyncLoading();
    _debounce = Timer(const Duration(milliseconds: 250), () {
      unawaited(searchNow(value));
    });
  }

  Future<List<GlobalSearchHitModel>> searchNow(String query) async {
    _debounce?.cancel();
    final value = query.trim();
    if (value.length < 2) {
      _requestId++;
      state = const AsyncData([]);
      return const [];
    }
    final requestId = ++_requestId;
    state = const AsyncLoading();
    try {
      final results = await _repository.search(value, _role);
      if (requestId != _requestId) return const [];
      state = AsyncData(results);
      return results;
    } catch (error, stackTrace) {
      if (requestId == _requestId) state = AsyncError(error, stackTrace);
      return const [];
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }
}
