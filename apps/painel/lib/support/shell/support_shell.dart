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
import '../data/mock_support_data.dart';
import '../data/mock_types.dart';

class SupportShell extends ConsumerWidget {
  const SupportShell({
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
    final String userName = user?.name ?? MockSupport.agentName;
    final String userEmail = user?.email ?? MockSupport.agentEmail;
    final S s = S.of(context);

    final List<SupportTicket> activeTickets =
        ref.watch(supportActiveTicketsProvider).asData?.value ??
            <SupportTicket>[];
    final List<SupportDispute> disputes =
        ref.watch(supportDisputesProvider).asData?.value ?? <SupportDispute>[];
    final int activeCount = activeTickets.length;
    final int urgentCount = activeTickets
        .where((SupportTicket t) => t.priority == SupportTicketPriority.urgent)
        .length;
    final int openDisputes = disputes
        .where((SupportDispute d) => d.status != SupportDisputeStatus.resolved)
        .length;

    return DashboardShell(
      sidebar: Sidebar(
        role: 'support',
        currentRoute: currentRoute,
        collapsed: collapsedSidebar,
        userName: userName,
        userEmail: userEmail,
        onItemTap: (String route) => context.go(route),
        onThemeToggle: () => ref.read(themeModeProvider.notifier).toggle(),
        groups: <SidebarNavGroup>[
          SidebarNavGroup(
            label: s.supportNavGeneral,
            items: <SidebarNavItem>[
              SidebarNavItem(
                icon: LucideIcons.layoutDashboard,
                label: s.supportNavDashboard,
                route: '/support',
                badge: urgentCount > 0 ? urgentCount : null,
              ),
            ],
          ),
          SidebarNavGroup(
            label: s.supportNavService,
            items: <SidebarNavItem>[
              SidebarNavItem(
                icon: LucideIcons.inbox,
                label: s.supportNavQueue,
                route: '/support/queue',
                badge: activeCount > 0 ? activeCount : null,
              ),
              SidebarNavItem(
                icon: LucideIcons.ticket,
                label: s.supportNavTickets,
                route: '/support/tickets',
              ),
              SidebarNavItem(
                icon: LucideIcons.messageCircle,
                label: s.supportNavChat,
                route: '/support/chat',
              ),
              SidebarNavItem(
                icon: LucideIcons.zap,
                label: s.supportNavActions,
                route: '/support/actions',
              ),
            ],
          ),
          SidebarNavGroup(
            label: s.supportNavAnalysis,
            items: <SidebarNavItem>[
              SidebarNavItem(
                icon: LucideIcons.scale,
                label: s.supportNavDisputes,
                route: '/support/disputes',
                badge: openDisputes > 0 ? openDisputes : null,
              ),
              SidebarNavItem(
                icon: LucideIcons.gauge,
                label: s.supportNavPerformance,
                route: '/support/performance',
              ),
            ],
          ),
        ],
      ),
      topbar: Topbar(
        userName: userName,
        userEmail: userEmail,
        notificationsCount: urgentCount + openDisputes,
        onLogout: () {
          ref.read(authStateProvider.notifier).signOut();
          context.go('/login');
        },
      ),
      child: child,
    );
  }
}
