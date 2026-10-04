import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../views/ai_chat/ai_chat_view.dart';
import '../views/auth/auth_screen.dart';
import '../views/auth/forgot_password_screen.dart';
import '../views/budgets/budgets_view.dart';
import '../views/dashboard/dashboard_view.dart';
import '../views/goals/goals_view.dart';
import '../views/insights/insights_view.dart';
import '../views/reports/reports_view.dart';
import '../views/settings/settings_view.dart';
import '../views/transactions/transactions_view.dart';
import '../widgets/responsive_scaffold.dart';

class RouterNotifier extends ChangeNotifier {
  final Ref _ref;

  RouterNotifier(this._ref) {
    _ref.listen<AuthState>(
      authProvider,
      (_, _) => notifyListeners(),
    );
  }

  String? redirect(BuildContext context, GoRouterState state) {
    final authState = _ref.read(authProvider);

    // If still resolving credentials, don't redirect yet
    if (authState.isLoading) return null;

    final isAuthed = authState.isAuthenticated;
    final location = state.uri.path;

    final isAuthRoute = location == '/login' ||
        location == '/signup' ||
        location == '/forgot-password';

    // If unauthenticated and on a protected route -> redirect to /login
    if (!isAuthed && !isAuthRoute) {
      return '/login';
    }

    // If authenticated and on an auth screen -> redirect to /dashboard
    if (isAuthed && (location == '/login' || location == '/signup')) {
      return '/dashboard';
    }

    return null;
  }
}

final routerNotifierProvider = Provider<RouterNotifier>((ref) {
  return RouterNotifier(ref);
});

final routerProvider = Provider<GoRouter>((ref) {
  final notifier = ref.watch(routerNotifierProvider);

  return GoRouter(
    initialLocation: '/login',
    refreshListenable: notifier,
    redirect: notifier.redirect,
    routes: [
      // Auth Routes
      GoRoute(
        path: '/login',
        builder: (context, state) => const AuthScreen(initialIsSignUp: false),
      ),
      GoRoute(
        path: '/signup',
        builder: (context, state) => const AuthScreen(initialIsSignUp: true),
      ),
      GoRoute(
        path: '/forgot-password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),

      // App Shell Routes (wrapped by ResponsiveScaffold)
      ShellRoute(
        builder: (context, state, child) {
          return ResponsiveScaffold(
            currentPath: state.uri.path,
            child: child,
          );
        },
        routes: [
          GoRoute(
            path: '/dashboard',
            builder: (context, state) => const DashboardView(),
          ),
          GoRoute(
            path: '/transactions',
            builder: (context, state) => const TransactionsView(),
          ),
          GoRoute(
            path: '/budgets',
            builder: (context, state) => const BudgetsView(),
          ),
          GoRoute(
            path: '/goals',
            builder: (context, state) => const GoalsView(),
          ),
          GoRoute(
            path: '/ai-chat',
            builder: (context, state) => const AiChatView(),
          ),
          GoRoute(
            path: '/insights',
            builder: (context, state) => const InsightsView(),
          ),
          GoRoute(
            path: '/reports',
            builder: (context, state) => const ReportsView(),
          ),
          GoRoute(
            path: '/settings',
            builder: (context, state) => const SettingsView(),
          ),
        ],
      ),
    ],
  );
});
