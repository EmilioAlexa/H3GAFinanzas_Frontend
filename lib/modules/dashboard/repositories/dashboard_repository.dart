import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/config/env.dart';
import '../../auth/auth.dart';
import '../fixtures/dashboard_demo_fixtures.dart';
import '../models/dashboard_model.dart';

class DashboardRepository {
  const DashboardRepository({required this.demoMode});

  final bool demoMode;

  Future<DashboardModel?> load(UserRole role) async {
    if (!demoMode) return null;
    return DashboardDemoFixtures.forRole(role);
  }
}

final dashboardRepositoryProvider = Provider<DashboardRepository>(
  (ref) => const DashboardRepository(demoMode: AppEnv.demoMode),
);
