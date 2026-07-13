import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../app/theme_mode_provider.dart';
import '../../core/auth/auth_provider.dart';
import '../../core/auth/auth_user.dart';
import '../../data/providers.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../shared/widgets/shell/dashboard_shell.dart';
import '../../shared/widgets/shell/sidebar.dart';
import '../../shared/widgets/shell/topbar.dart';
import '../data/mock_partner_data.dart';

class PartnerShell extends ConsumerWidget {
  const PartnerShell({
    required this.currentRoute,
    required this.child,
    super.key,
  });

  final String currentRoute;
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool collapsedSidebar = MediaQuery.sizeOf(context).width < 1180;
    final AuthUser? user = ref.watch(authStateProvider);
    final String userName = user?.name ?? MockPartner.name;
    final String userEmail = user?.email ?? MockPartner.email;
    final S s = S.of(context);

    final List<MockAlert> criticalAlerts =
        ref.watch(criticalAlertsProvider).asData?.value ?? <MockAlert>[];
    final List<MockMessageThread> threads =
        ref.watch(messageThreadsProvider).asData?.value ??
            <MockMessageThread>[];
    final int alertCount = criticalAlerts.length;
    final int unreadMessages = threads.fold<int>(
      0,
      (int sum, MockMessageThread t) => sum + t.unreadCount,
    );

    return DashboardShell(
      sidebar: Sidebar(
        role: 'partner',
        currentRoute: currentRoute,
        collapsed: collapsedSidebar,
        userName: userName,
        userEmail: userEmail,
        onItemTap: (String route) => context.go(route),
        onThemeToggle: () => ref.read(themeModeProvider.notifier).toggle(),
        groups: <SidebarNavGroup>[
          SidebarNavGroup(
            label: s.commonGeneral,
            items: <SidebarNavItem>[
              SidebarNavItem(
                icon: LucideIcons.layoutDashboard,
                label: s.partnerNavDashboard,
                route: '/partner/dashboard',
              ),
            ],
          ),
          SidebarNavGroup(
            label: s.partnerNavOperation,
            items: <SidebarNavItem>[
              SidebarNavItem(
                icon: LucideIcons.users,
                label: s.partnerNavFleet,
                route: '/partner/fleet',
              ),
              SidebarNavItem(
                icon: LucideIcons.user,
                label: s.partnerNavDrivers,
                route: '/partner/drivers',
              ),
              SidebarNavItem(
                icon: LucideIcons.car,
                label: s.partnerNavVehicles,
                route: '/partner/cars',
              ),
              SidebarNavItem(
                icon: LucideIcons.route,
                label: s.partnerNavTrips,
                route: '/partner/trips',
              ),
            ],
          ),
          SidebarNavGroup(
            label: s.partnerNavFinance,
            items: <SidebarNavItem>[
              SidebarNavItem(
                icon: LucideIcons.trendingUp,
                label: s.partnerNavEarnings,
                route: '/partner/earnings',
              ),
              SidebarNavItem(
                icon: LucideIcons.gauge,
                label: s.partnerNavPerformance,
                route: '/partner/performance',
              ),
              SidebarNavItem(
                icon: LucideIcons.gift,
                label: s.partnerNavIncentives,
                route: '/partner/incentives',
              ),
            ],
          ),
          SidebarNavGroup(
            label: s.partnerNavCommunication,
            items: <SidebarNavItem>[
              SidebarNavItem(
                icon: LucideIcons.circleAlert,
                label: s.partnerNavAlerts,
                route: '/partner/alerts',
                badge: alertCount > 0 ? alertCount : null,
              ),
              SidebarNavItem(
                icon: LucideIcons.messageSquare,
                label: s.partnerNavMessages,
                route: '/partner/messages',
                badge: unreadMessages > 0 ? unreadMessages : null,
              ),
              SidebarNavItem(
                icon: LucideIcons.fileText,
                label: s.partnerNavDocuments,
                route: '/partner/documents',
              ),
              SidebarNavItem(
                icon: LucideIcons.settings,
                label: s.partnerNavSettings,
                route: '/partner/settings',
              ),
            ],
          ),
        ],
      ),
      topbar: Topbar(
        userName: userName,
        userEmail: userEmail,
        notificationsCount: alertCount + unreadMessages,
        onLogout: () {
          ref.read(authStateProvider.notifier).signOut();
          context.go('/login');
        },
      ),
      child: child,
    );
  }
}
