import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
import 'global_search.dart';

class AdminShell extends ConsumerWidget {
  const AdminShell({
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
    final String userName = user?.name ?? 'Amina Mussa';
    final String userEmail = user?.email ?? 'amina@ya.co.mz';
    final S s = S.of(context);

    final int unresolvedAlerts = ref
            .watch(adminAlertsProvider)
            .asData
            ?.value
            .where((a) => !a.resolved)
            .length ??
        0;

    void focusSearch() => ref.read(searchFocusProvider).requestFocus();

    return CallbackShortcuts(
      bindings: <ShortcutActivator, VoidCallback>{
        const SingleActivator(LogicalKeyboardKey.keyK, control: true):
            focusSearch,
        const SingleActivator(LogicalKeyboardKey.keyK, meta: true): focusSearch,
      },
      child: Focus(
        autofocus: true,
        child: DashboardShell(
          sidebar: Sidebar(
            role: 'admin',
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
                    label: s.adminNavDashboard,
                    route: '/admin/dashboard',
                  ),
                ],
              ),
              SidebarNavGroup(
                label: s.adminNavManagement,
                items: <SidebarNavItem>[
                  SidebarNavItem(
                    icon: LucideIcons.building2,
                    label: s.adminNavPartners,
                    route: '/admin/partners',
                  ),
                  SidebarNavItem(
                    icon: LucideIcons.user,
                    label: s.adminNavDrivers,
                    route: '/admin/drivers',
                  ),
                  SidebarNavItem(
                    icon: LucideIcons.car,
                    label: s.adminNavVehicles,
                    route: '/admin/vehicles',
                  ),
                  SidebarNavItem(
                    icon: LucideIcons.fileText,
                    label: s.adminNavDocuments,
                    route: '/admin/documents',
                  ),
                  SidebarNavItem(
                    icon: LucideIcons.badgeCheck,
                    label: s.adminNavFleets,
                    route: '/admin/fleets',
                  ),
                ],
              ),
              SidebarNavGroup(
                label: s.adminNavOperations,
                items: <SidebarNavItem>[
                  SidebarNavItem(
                    icon: LucideIcons.route,
                    label: s.adminNavTrips,
                    route: '/admin/trips',
                  ),
                  SidebarNavItem(
                    icon: LucideIcons.map,
                    label: s.adminNavMap,
                    route: '/admin/trips/live',
                  ),
                ],
              ),
              SidebarNavGroup(
                label: s.adminNavBusiness,
                items: <SidebarNavItem>[
                  SidebarNavItem(
                    icon: LucideIcons.trendingUp,
                    label: s.adminNavFinance,
                    route: '/admin/finance',
                  ),
                  SidebarNavItem(
                    icon: LucideIcons.percent,
                    label: s.adminNavCommissions,
                    route: '/admin/commissions',
                  ),
                  SidebarNavItem(
                    icon: LucideIcons.tag,
                    label: s.adminNavPricing,
                    route: '/admin/pricing',
                  ),
                  SidebarNavItem(
                    icon: LucideIcons.fileText,
                    label: s.adminNavReports,
                    route: '/admin/reports',
                  ),
                ],
              ),
              SidebarNavGroup(
                label: s.adminNavSystem,
                items: <SidebarNavItem>[
                  SidebarNavItem(
                    icon: LucideIcons.users,
                    label: s.adminNavUsers,
                    route: '/admin/users',
                  ),
                  SidebarNavItem(
                    icon: LucideIcons.bell,
                    label: s.adminNavNotifications,
                    route: '/admin/notifications',
                  ),
                  SidebarNavItem(
                    icon: LucideIcons.circleAlert,
                    label: s.adminNavAlerts,
                    route: '/admin/alerts',
                  ),
                  SidebarNavItem(
                    icon: LucideIcons.history,
                    label: s.adminNavAudit,
                    route: '/admin/audit',
                  ),
                  SidebarNavItem(
                    icon: LucideIcons.settings,
                    label: s.adminNavSettings,
                    route: '/admin/settings',
                  ),
                ],
              ),
            ],
          ),
          topbar: Topbar(
            userName: userName,
            userEmail: userEmail,
            notificationsCount: unresolvedAlerts,
            searchField: const AdminSearchField(),
            onNotifications: () => context.go('/admin/alerts'),
            onLogout: () {
              ref.read(authStateProvider.notifier).signOut();
              context.go('/login');
            },
          ),
          child: child,
        ),
      ),
    );
  }
}
