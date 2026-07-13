import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../core/auth/auth_provider.dart';
import '../core/auth/auth_user.dart';
import '../admin/alerts/alerts_page.dart';
import '../admin/audit/audit_page.dart';
import '../admin/commissions/commissions_history_page.dart';
import '../admin/commissions/commissions_page.dart';
import '../admin/dashboard/dashboard_page.dart';
import '../admin/documents/documents_page.dart';
import '../admin/drivers/driver_detail_page.dart';
import '../admin/drivers/drivers_page.dart';
import '../admin/finance/finance_page.dart';
import '../admin/fleets/fleet_detail_page.dart';
import '../admin/fleets/fleets_page.dart';
import '../admin/map/map_page.dart';
import '../admin/notifications/notifications_page.dart';
import '../admin/partners/partner_detail_page.dart';
import '../admin/partners/partners_page.dart';
import '../admin/pricing/pricing_page.dart';
import '../admin/reports/reports_page.dart';
import '../admin/settings/settings_page.dart';
import '../admin/shell/admin_shell.dart';
import '../admin/trips/trip_detail_page.dart';
import '../admin/trips/trips_page.dart';
import '../admin/users/user_detail_page.dart';
import '../admin/users/users_page.dart';
import '../admin/vehicles/vehicle_detail_page.dart';
import '../admin/vehicles/vehicles_page.dart';
import '../partner/alerts/alerts_page.dart';
import '../partner/dashboard/dashboard_page.dart';
import '../partner/documents/documents_page.dart';
import '../partner/drivers/drivers_page.dart';
import '../partner/earnings/earnings_page.dart';
import '../partner/fleet/driver_detail_page.dart';
import '../partner/fleet/fleet_page.dart';
import '../partner/fleet/vehicle_detail_page.dart';
import '../partner/incentives/incentives_page.dart';
import '../partner/messages/messages_page.dart';
import '../partner/performance/performance_page.dart';
import '../partner/settings/settings_page.dart';
import '../partner/shell/partner_shell.dart';
import '../partner/trips/trips_page.dart';
import '../partner/vehicles/vehicles_page.dart';
import '../support/actions/support_actions_page.dart';
import '../support/auth/forgot_password_page.dart';
import '../support/auth/login_page.dart';
import '../support/chat/support_chat_page.dart';
import '../support/dashboard/support_dashboard_page.dart';
import '../support/disputes/support_disputes_page.dart';
import '../support/performance/support_performance_page.dart';
import '../support/queue/support_queue_page.dart';
import '../support/shell/support_shell.dart';
import '../support/tickets/support_ticket_detail_page.dart';
import '../support/tickets/support_tickets_page.dart';

final appRouter = GoRouter(
  initialLocation: '/admin/dashboard',
  refreshListenable: authNotifier,
  redirect: (context, state) {
    final AuthUser? user = authNotifier.user;
    final String loc = state.matchedLocation;
    final bool atAuthPage = loc == '/login' || loc == '/forgot-password';

    if (user == null) {
      return atAuthPage ? null : '/login';
    }

    if (atAuthPage) return user.role.landingRoute;

    if (loc == '/' || loc.isEmpty) return user.role.landingRoute;

    if (loc.startsWith('/admin') && user.role != UserRole.admin) {
      return user.role.landingRoute;
    }
    if (loc.startsWith('/partner') && user.role != UserRole.partner) {
      return user.role.landingRoute;
    }
    if (loc.startsWith('/support') && user.role != UserRole.support) {
      return user.role.landingRoute;
    }
    return null;
  },
  routes: [
    GoRoute(
      path: '/',
      redirect: (context, state) =>
          authNotifier.user?.role.landingRoute ?? '/login',
    ),
    _pageRoute(
      path: '/login',
      builder: (context, state) => LoginPage(
        redirectTo: state.uri.queryParameters['redirectTo'],
      ),
    ),
    _pageRoute(
      path: '/forgot-password',
      builder: (context, state) => const ForgotPasswordPage(),
    ),
    ShellRoute(
      builder: (context, state, child) => AdminShell(
        currentRoute: state.matchedLocation,
        child: child,
      ),
      routes: [
        GoRoute(
          path: '/admin',
          redirect: (context, state) => '/admin/dashboard',
        ),
        _pageRoute(
          path: '/admin/dashboard',
          builder: (context, state) => const DashboardPage(),
        ),
        _pageRoute(
          path: '/admin/partners',
          builder: (context, state) => const PartnersPage(),
        ),
        _pageRoute(
          path: '/admin/partners/:id',
          builder: (context, state) => PartnerDetailPage(
            id: state.pathParameters['id']!,
          ),
        ),
        _pageRoute(
          path: '/admin/drivers',
          builder: (context, state) => const DriversPage(),
        ),
        _pageRoute(
          path: '/admin/drivers/:id',
          builder: (context, state) => DriverDetailPage(
            id: state.pathParameters['id']!,
          ),
        ),
        _pageRoute(
          path: '/admin/vehicles',
          builder: (context, state) => const VehiclesPage(),
        ),
        _pageRoute(
          path: '/admin/cars/:id',
          builder: (context, state) => VehicleDetailPage(
            id: state.pathParameters['id']!,
          ),
        ),
        _pageRoute(
          path: '/admin/documents',
          builder: (context, state) => const DocumentsPage(),
        ),
        _pageRoute(
          path: '/admin/fleets',
          builder: (context, state) => const FleetsPage(),
        ),
        _pageRoute(
          path: '/admin/fleets/:id',
          builder: (context, state) => FleetDetailPage(
            id: state.pathParameters['id']!,
          ),
        ),
        _pageRoute(
          path: '/admin/trips',
          builder: (context, state) => const TripsPage(),
        ),
        _pageRoute(
          path: '/admin/trips/live',
          builder: (context, state) => const MapPage(),
        ),
        _pageRoute(
          path: '/admin/trips/:id',
          builder: (context, state) => TripDetailPage(
            id: state.pathParameters['id']!,
          ),
        ),
        _pageRoute(
          path: '/admin/users',
          builder: (context, state) => const UsersPage(),
        ),
        _pageRoute(
          path: '/admin/users/:id',
          builder: (context, state) => UserDetailPage(
            id: state.pathParameters['id']!,
          ),
        ),
        _pageRoute(
          path: '/admin/finance',
          builder: (context, state) => const FinancePage(),
        ),
        _pageRoute(
          path: '/admin/commissions',
          builder: (context, state) => const CommissionsPage(),
        ),
        _pageRoute(
          path: '/admin/commissions/list',
          builder: (context, state) => const CommissionsHistoryPage(),
        ),
        _pageRoute(
          path: '/admin/pricing',
          builder: (context, state) => const PricingPage(),
        ),
        _pageRoute(
          path: '/admin/notifications',
          builder: (context, state) => const NotificationsPage(),
        ),
        _pageRoute(
          path: '/admin/alerts',
          builder: (context, state) => const AlertsPage(),
        ),
        _pageRoute(
          path: '/admin/audit',
          builder: (context, state) => const AuditPage(),
        ),
        _pageRoute(
          path: '/admin/reports',
          builder: (context, state) => const ReportsPage(),
        ),
        _pageRoute(
          path: '/admin/settings',
          builder: (context, state) => const SettingsPage(),
        ),
      ],
    ),
    ShellRoute(
      builder: (context, state, child) => PartnerShell(
        currentRoute: state.matchedLocation,
        child: child,
      ),
      routes: [
        GoRoute(
          path: '/partner',
          redirect: (context, state) => '/partner/dashboard',
        ),
        _pageRoute(
          path: '/partner/dashboard',
          builder: (context, state) => const PartnerDashboardPage(),
        ),
        _pageRoute(
          path: '/partner/fleet',
          builder: (context, state) => PartnerFleetPage(
            tab: state.uri.queryParameters['tab'] ?? 'drivers',
          ),
        ),
        _pageRoute(
          path: '/partner/fleet/driver/:uid',
          builder: (context, state) => PartnerDriverDetailPage(
            id: state.pathParameters['uid']!,
          ),
        ),
        _pageRoute(
          path: '/partner/fleet/vehicle/:id',
          builder: (context, state) => PartnerVehicleDetailPage(
            id: state.pathParameters['id']!,
          ),
        ),
        _pageRoute(
          path: '/partner/drivers',
          builder: (context, state) => const PartnerDriversPage(),
        ),
        _pageRoute(
          path: '/partner/cars',
          builder: (context, state) => const PartnerCarsPage(),
        ),
        _pageRoute(
          path: '/partner/trips',
          builder: (context, state) => const PartnerTripsPage(),
        ),
        _pageRoute(
          path: '/partner/trips/:id',
          builder: (context, state) => TripDetailPage(
            id: state.pathParameters['id']!,
          ),
        ),
        _pageRoute(
          path: '/partner/earnings',
          builder: (context, state) => const PartnerEarningsPage(),
        ),
        _pageRoute(
          path: '/partner/performance',
          builder: (context, state) => const PartnerPerformancePage(),
        ),
        _pageRoute(
          path: '/partner/incentives',
          builder: (context, state) => const PartnerIncentivesPage(),
        ),
        _pageRoute(
          path: '/partner/alerts',
          builder: (context, state) => const PartnerAlertsPage(),
        ),
        _pageRoute(
          path: '/partner/messages',
          builder: (context, state) => const PartnerMessagesPage(),
        ),
        _pageRoute(
          path: '/partner/documents',
          builder: (context, state) => const PartnerDocumentsPage(),
        ),
        _pageRoute(
          path: '/partner/settings',
          builder: (context, state) => const PartnerSettingsPage(),
        ),
      ],
    ),
    ShellRoute(
      builder: (context, state, child) => SupportShell(
        currentRoute: state.matchedLocation,
        child: child,
      ),
      routes: [
        _pageRoute(
          path: '/support',
          builder: (context, state) => const SupportDashboardPage(),
        ),
        GoRoute(
          path: '/support/dashboard',
          redirect: (context, state) => '/support',
        ),
        _pageRoute(
          path: '/support/queue',
          builder: (context, state) => SupportQueuePage(
            initialTicketId: state.uri.queryParameters['ticket'],
          ),
        ),
        _pageRoute(
          path: '/support/tickets',
          builder: (context, state) => const SupportTicketsPage(),
        ),
        _pageRoute(
          path: '/support/tickets/:id',
          builder: (context, state) => SupportTicketDetailPage(
            id: state.pathParameters['id']!,
          ),
        ),
        _pageRoute(
          path: '/support/chat',
          builder: (context, state) => const SupportChatPage(),
        ),
        _pageRoute(
          path: '/support/actions',
          builder: (context, state) => const SupportActionsPage(),
        ),
        _pageRoute(
          path: '/support/disputes',
          builder: (context, state) => const SupportDisputesPage(),
        ),
        _pageRoute(
          path: '/support/performance',
          builder: (context, state) => const SupportPerformancePage(),
        ),
      ],
    ),
  ],
);

GoRoute _pageRoute({
  required String path,
  required Widget Function(BuildContext context, GoRouterState state) builder,
}) {
  return GoRoute(
    path: path,
    pageBuilder: (context, state) => NoTransitionPage<void>(
      child: builder(context, state),
    ),
  );
}
