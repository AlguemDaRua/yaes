import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/auth/auth_provider.dart';
import '../../core/auth/auth_user.dart';
import '../../core/constants/status_mapping.dart';
import '../../data/providers.dart';
import '../../shared/widgets/dialogs/confirm_dialog.dart';
import '../../shared/widgets/dialogs/form_dialog.dart';
import '../../shared/widgets/feedback/status_badge.dart';
import '../../shared/widgets/forms/ya_avatar.dart';
import '../../shared/widgets/forms/ya_button.dart';
import '../../shared/widgets/forms/ya_field.dart';
import '../../shared/widgets/forms/ya_input.dart';
import '../../shared/widgets/forms/ya_select.dart';
import '../../shared/widgets/forms/ya_textarea.dart';
import '../../shared/widgets/table/cells.dart';
import '../../theme/tokens/colors.dart';
import '../../theme/tokens/dimensions.dart';
import '../../theme/tokens/typography.dart';
import '../data/mock_types.dart';

String supportRelativeWhen(DateTime date) {
  final Duration diff = DateTime.now().difference(date);
  if (diff.inMinutes < 60) return 'ha ${diff.inMinutes} min';
  if (diff.inHours < 24) return 'ha ${diff.inHours} h';
  return 'ha ${diff.inDays} d';
}

String supportShortTime(DateTime date) {
  return DateFormat('HH:mm', 'pt_PT').format(date);
}

String supportShortDate(DateTime date) {
  return DateFormat('dd/MM/y', 'pt_PT').format(date);
}

String supportMoney(num value) {
  return '${NumberFormat.decimalPattern('pt_PT').format(value).replaceAll(String.fromCharCode(160), ' ')} MTn';
}

void supportToast(
  BuildContext context,
  String message, {
  StatusVariant variant = StatusVariant.success,
}) {
  final YaColors colors = YaColors.of(context);
  final ({Color bg, Color fg}) palette = switch (variant) {
    StatusVariant.danger => (bg: colors.dangerSubtle, fg: colors.danger),
    StatusVariant.warning => (bg: colors.warningSubtle, fg: colors.warning),
    StatusVariant.info => (bg: colors.infoSubtle, fg: colors.info),
    StatusVariant.success => (bg: colors.successSubtle, fg: colors.success),
    _ => (bg: colors.bgElevated, fg: colors.textPrimary),
  };
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content:
            Text(message, style: YaText.smMedium.copyWith(color: palette.fg)),
        backgroundColor: palette.bg,
        behavior: SnackBarBehavior.floating,
        elevation: 0,
        duration: const Duration(seconds: 3),
      ),
    );
}

StatusMapping supportPriorityMapping(SupportTicketPriority priority) {
  return YaStatus.fromTicketPriority(priority.name);
}

StatusMapping supportTicketStatusMapping(SupportTicketStatus status) {
  return YaStatus.fromTicketStatus(
    switch (status) {
      SupportTicketStatus.open => 'open',
      SupportTicketStatus.inProgress => 'in_progress',
      SupportTicketStatus.resolved => 'resolved',
      SupportTicketStatus.closed => 'closed',
    },
  );
}

StatusMapping supportDisputeStatusMapping(SupportDisputeStatus status) {
  return switch (status) {
    SupportDisputeStatus.open =>
      const StatusMapping(StatusVariant.warning, 'Aberta'),
    SupportDisputeStatus.investigating =>
      const StatusMapping(StatusVariant.info, 'Investigando'),
    SupportDisputeStatus.resolved =>
      const StatusMapping(StatusVariant.success, 'Resolvida'),
  };
}

String supportRoleLabel(SupportActorRole role) {
  return switch (role) {
    SupportActorRole.passenger => 'Passageiro',
    SupportActorRole.driver => 'Driver',
    SupportActorRole.partner => 'Partner',
    SupportActorRole.agent => 'Agente',
  };
}

IconData supportRoleIcon(SupportActorRole role) {
  return switch (role) {
    SupportActorRole.passenger => LucideIcons.user,
    SupportActorRole.driver => LucideIcons.car,
    SupportActorRole.partner => LucideIcons.building2,
    SupportActorRole.agent => LucideIcons.headphones,
  };
}

IconData supportQuickTypeIcon(SupportQuickResultType type) {
  return switch (type) {
    SupportQuickResultType.passenger => LucideIcons.user,
    SupportQuickResultType.driver => LucideIcons.car,
    SupportQuickResultType.partner => LucideIcons.building2,
    SupportQuickResultType.trip => LucideIcons.route,
  };
}

String supportQuickTypeLabel(SupportQuickResultType type) {
  return switch (type) {
    SupportQuickResultType.passenger => 'Passageiro',
    SupportQuickResultType.driver => 'Driver',
    SupportQuickResultType.partner => 'Partner',
    SupportQuickResultType.trip => 'Trip',
  };
}

class SupportCard extends StatelessWidget {
  const SupportCard({
    required this.child,
    this.padding = YaSpacing.cardMd,
    this.borderColor,
    this.backgroundColor,
    super.key,
  });

  final Widget child;
  final EdgeInsets padding;
  final Color? borderColor;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    final YaColors colors = YaColors.of(context);
    final bool isLight = Theme.of(context).brightness == Brightness.light;

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: backgroundColor ?? colors.bgSurface,
        borderRadius: YaRadius.brLg,
        border: Border.all(color: borderColor ?? colors.borderSubtle),
        boxShadow: isLight ? YaShadows.sm : YaShadows.none,
      ),
      child: child,
    );
  }
}

class SupportSectionTitle extends StatelessWidget {
  const SupportSectionTitle({
    required this.title,
    this.action,
    super.key,
  });

  final String title;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final YaColors colors = YaColors.of(context);
    return Row(
      children: <Widget>[
        Expanded(
          child: Text(
            title,
            style: YaText.lg.copyWith(color: colors.textPrimary),
          ),
        ),
        if (action != null) action!,
      ],
    );
  }
}

class SupportServicePill extends StatefulWidget {
  const SupportServicePill({super.key});

  @override
  State<SupportServicePill> createState() => _SupportServicePillState();
}

class _SupportServicePillState extends State<SupportServicePill> {
  bool _serving = true;

  @override
  Widget build(BuildContext context) {
    final YaColors colors = YaColors.of(context);
    final Color accent = _serving ? colors.success : colors.warning;
    final Color bg = _serving ? colors.successSubtle : colors.warningSubtle;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => setState(() => _serving = !_serving),
        child: Container(
          height: 28,
          padding: const EdgeInsets.symmetric(horizontal: YaSpacing.md),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: YaRadius.brFull,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              _PulseDot(color: accent),
              const SizedBox(width: YaSpacing.sm),
              Text(
                _serving ? 'Em servico' : 'Em pausa',
                style: YaText.sans(
                  size: 12,
                  height: 16,
                  weight: FontWeight.w500,
                ).copyWith(color: accent),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PulseDot extends StatefulWidget {
  const _PulseDot({required this.color});

  final Color color;

  @override
  State<_PulseDot> createState() => _PulseDotState();
}

class _PulseDotState extends State<_PulseDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1500),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween<double>(begin: 0.6, end: 1).animate(_controller),
      child: Container(
        width: 6,
        height: 6,
        decoration: BoxDecoration(color: widget.color, shape: BoxShape.circle),
      ),
    );
  }
}

class UrgentSupportBanner extends StatelessWidget {
  const UrgentSupportBanner({
    required this.tickets,
    super.key,
  });

  final List<SupportTicket> tickets;

  @override
  Widget build(BuildContext context) {
    if (tickets.isEmpty) return const SizedBox.shrink();

    final YaColors colors = YaColors.of(context);
    final int visibleCount = tickets.length > 50 ? 50 : tickets.length;
    final String ids = tickets
        .take(3)
        .map((SupportTicket ticket) => '${ticket.id} ${ticket.subject}')
        .join(' / ');

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: YaSpacing.lg,
        vertical: 14,
      ),
      decoration: BoxDecoration(
        color: colors.dangerSubtle,
        borderRadius: YaRadius.brLg,
        border: Border(left: BorderSide(color: colors.danger, width: 3)),
      ),
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final bool compact = constraints.maxWidth < 620;
          final Widget content = Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Icon(LucideIcons.triangleAlert, size: 20, color: colors.danger),
              const SizedBox(width: YaSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      '${visibleCount == 50 ? '50+' : visibleCount} tickets urgentes aguardam atenção',
                      style: YaText.baseMedium.copyWith(color: colors.danger),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      ids,
                      style: YaText.sm.copyWith(color: colors.textSecondary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          );

          final Widget link = YaButton.link(
            label: 'Ir para a fila',
            icon: LucideIcons.arrowRight,
            onPressed: () => context.go('/support/queue'),
          );

          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                content,
                const SizedBox(height: YaSpacing.sm),
                link,
              ],
            );
          }

          return Row(
            children: <Widget>[
              Expanded(child: content),
              const SizedBox(width: YaSpacing.lg),
              link,
            ],
          );
        },
      ),
    );
  }
}

class PriorityBadge extends StatelessWidget {
  const PriorityBadge(
    this.priority, {
    this.size = StatusBadgeSize.sm,
    super.key,
  });

  final SupportTicketPriority priority;
  final StatusBadgeSize size;

  @override
  Widget build(BuildContext context) {
    return StatusBadge.fromMapping(
      supportPriorityMapping(priority),
      size: size,
    );
  }
}

class SupportRoleMeta extends StatelessWidget {
  const SupportRoleMeta({
    required this.role,
    this.id,
    super.key,
  });

  final SupportActorRole role;
  final String? id;

  @override
  Widget build(BuildContext context) {
    final YaColors colors = YaColors.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Icon(supportRoleIcon(role), size: 13, color: colors.textMuted),
        const SizedBox(width: 5),
        Flexible(
          child: Text(
            id == null
                ? supportRoleLabel(role)
                : '${supportRoleLabel(role)} / $id',
            style: YaText.sans(size: 12, height: 16)
                .copyWith(color: colors.textSecondary),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class SupportTicketListItem extends StatefulWidget {
  const SupportTicketListItem({
    required this.ticket,
    required this.onTap,
    this.selected = false,
    this.compact = false,
    super.key,
  });

  final SupportTicket ticket;
  final VoidCallback onTap;
  final bool selected;
  final bool compact;

  @override
  State<SupportTicketListItem> createState() => _SupportTicketListItemState();
}

class _SupportTicketListItemState extends State<SupportTicketListItem> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final YaColors colors = YaColors.of(context);
    final SupportTicket ticket = widget.ticket;
    final StatusVariant variant =
        supportPriorityMapping(ticket.priority).variant;
    final Color priorityColor = variant.resolve(colors).text;
    final Color bg = widget.selected
        ? colors.brandSubtle
        : (_hovering ? colors.bgSubtle : Colors.transparent);

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: YaDurations.micro,
          padding: EdgeInsets.fromLTRB(
            widget.compact ? 12 : 16,
            widget.compact ? 12 : 14,
            widget.compact ? 12 : 16,
            widget.compact ? 12 : 14,
          ),
          decoration: BoxDecoration(
            color: bg,
            border: Border(
              left: BorderSide(
                color: widget.selected ? colors.brand : Colors.transparent,
                width: 3,
              ),
              bottom: BorderSide(color: colors.borderSubtle),
            ),
          ),
          child: widget.compact
              ? _compactLayout(colors, ticket, priorityColor)
              : _regularLayout(colors, ticket),
        ),
      ),
    );
  }

  Widget _compactLayout(
    YaColors colors,
    SupportTicket ticket,
    Color priorityColor,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Container(
              width: 6,
              height: 6,
              decoration:
                  BoxDecoration(color: priorityColor, shape: BoxShape.circle),
            ),
            const SizedBox(width: YaSpacing.sm),
            Expanded(
              child: Text(
                ticket.subject,
                style: YaText.smMedium.copyWith(color: colors.textPrimary),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: YaSpacing.sm),
            Text(
              supportRelativeWhen(ticket.lastMessageAt),
              style: YaText.xs.copyWith(color: colors.textMuted),
            ),
          ],
        ),
        const SizedBox(height: 6),
        SupportRoleMeta(role: ticket.role, id: ticket.id),
        const SizedBox(height: 4),
        Text(
          ticket.preview,
          style: YaText.sans(size: 12, height: 16)
              .copyWith(color: colors.textMuted),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _regularLayout(YaColors colors, SupportTicket ticket) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            PriorityBadge(ticket.priority),
            const SizedBox(width: YaSpacing.sm),
            Icon(
              supportRoleIcon(ticket.role),
              size: 14,
              color: colors.textMuted,
            ),
            const SizedBox(width: YaSpacing.sm),
            Expanded(
              child: Text(
                ticket.subject,
                style: YaText.smMedium.copyWith(color: colors.textPrimary),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: YaSpacing.sm),
            Text(
              supportRelativeWhen(ticket.lastMessageAt),
              style: YaText.xs.copyWith(color: colors.textMuted),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          ticket.preview,
          style: YaText.sm.copyWith(color: colors.textSecondary),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: YaSpacing.sm),
        Wrap(
          spacing: YaSpacing.md,
          runSpacing: YaSpacing.xs,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: <Widget>[
            IdCell(ticket.id),
            if (ticket.tripId != null) IdCell(ticket.tripId!),
            StatusBadge.fromMapping(
              supportTicketStatusMapping(ticket.status),
              size: StatusBadgeSize.sm,
            ),
          ],
        ),
      ],
    );
  }
}

class SupportTicketThreadCard extends ConsumerStatefulWidget {
  const SupportTicketThreadCard({
    required this.ticket,
    this.showCompactHeader = false,
    this.height,
    super.key,
  });

  final SupportTicket ticket;
  final bool showCompactHeader;
  final double? height;

  @override
  ConsumerState<SupportTicketThreadCard> createState() =>
      _SupportTicketThreadCardState();
}

class _SupportTicketThreadCardState
    extends ConsumerState<SupportTicketThreadCard> {
  late List<SupportMessage> _messages;
  final TextEditingController _replyController = TextEditingController();
  String? _macro;
  bool _sending = false;

  static const List<YaSelectItem<String>> _macros = <YaSelectItem<String>>[
    YaSelectItem(value: 'refund', label: 'Reembolso emitido'),
    YaSelectItem(value: 'partner', label: 'Investigar com partner'),
    YaSelectItem(value: 'more', label: 'Solicitar mais informação'),
    YaSelectItem(value: 'admin', label: 'Encaminhar para admin'),
    YaSelectItem(value: 'driver', label: 'Aguardar driver responder'),
    YaSelectItem(value: 'closed', label: 'Caso encerrado sem ação'),
  ];

  @override
  void initState() {
    super.initState();
    _messages = widget.ticket.messages;
  }

  @override
  void didUpdateWidget(covariant SupportTicketThreadCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.ticket.id != widget.ticket.id) {
      _messages = widget.ticket.messages;
      _replyController.clear();
      _macro = null;
    }
  }

  @override
  void dispose() {
    _replyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Widget card = SupportCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _ThreadHeader(
            ticket: widget.ticket,
            onResolve: _openResolveDialog,
            onAssign: _assignToSelf,
            agentName: ref.watch(authStateProvider)?.name ?? '',
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(YaSpacing.xl),
              child: _messages.isEmpty
                  ? const _ThreadEmpty()
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        for (final SupportMessage message in _messages)
                          _MessageBubble(message: message),
                      ],
                    ),
            ),
          ),
          _ThreadComposer(
            controller: _replyController,
            macro: _macro,
            macros: _macros,
            sending: _sending,
            onMacroChanged: (String value) {
              setState(() {
                _macro = value;
                _replyController.text =
                    _macros.firstWhere((item) => item.value == value).label;
              });
            },
            onInternalNotes: () => supportToast(
              context,
              'Notas internas guardadas',
              variant: StatusVariant.info,
            ),
            onSend: _sendReply,
          ),
        ],
      ),
    );

    if (widget.height != null) {
      return SizedBox(height: widget.height, child: card);
    }
    return SizedBox(height: 680, child: card);
  }

  Future<void> _sendReply() async {
    final String value = _replyController.text.trim();
    if (value.isEmpty || _sending) return;
    final AuthUser? user = ref.read(authStateProvider);
    setState(() => _sending = true);
    try {
      await ref.read(cloudFunctionsServiceProvider).replyTicket(
            ticketId: widget.ticket.id,
            text: value,
            authorName: user?.name,
          );
      if (!mounted) return;
      ref.invalidate(supportTicketByIdProvider(widget.ticket.id));
      setState(() {
        _messages = <SupportMessage>[
          ..._messages,
          SupportMessage(
            author: user?.name ?? 'Suporte',
            role: SupportActorRole.agent,
            agent: true,
            createdAt: DateTime.now(),
            text: value,
          ),
        ];
        _replyController.clear();
        _macro = null;
        _sending = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _sending = false);
      supportToast(context, 'Erro: $e', variant: StatusVariant.danger);
    }
  }

  Future<void> _assignToSelf() async {
    final AuthUser? user = ref.read(authStateProvider);
    if (user == null) return;
    try {
      await ref.read(cloudFunctionsServiceProvider).assignTicket(
            ticketId: widget.ticket.id,
            agentUid: user.uid,
          );
      if (!mounted) return;
      ref.invalidate(supportTicketByIdProvider(widget.ticket.id));
      ref.invalidate(supportActiveTicketsProvider);
      supportToast(context, 'Ticket atribuído a si');
    } catch (e) {
      if (!mounted) return;
      supportToast(context, 'Erro: $e', variant: StatusVariant.danger);
    }
  }

  void _openResolveDialog() {
    showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) => ConfirmDialog(
        title: 'Resolver ticket?',
        description:
            'O ticket sera marcado como resolvido. Pode adicionar resumo no historico depois.',
        icon: LucideIcons.check,
        variant: StatusVariant.success,
        confirmLabel: 'Resolver',
        onConfirm: () {
          Navigator.of(dialogContext).pop();
          _resolveTicket();
        },
      ),
    );
  }

  Future<void> _resolveTicket() async {
    try {
      await ref
          .read(cloudFunctionsServiceProvider)
          .closeTicket(widget.ticket.id);
      if (!mounted) return;
      ref.invalidate(supportTicketByIdProvider(widget.ticket.id));
      ref.invalidate(supportActiveTicketsProvider);
      ref.invalidate(supportTicketsProvider);
      supportToast(context, 'Ticket resolvido');
    } catch (e) {
      if (!mounted) return;
      supportToast(context, 'Erro: $e', variant: StatusVariant.danger);
    }
  }
}

class _ThreadHeader extends StatelessWidget {
  const _ThreadHeader({
    required this.ticket,
    required this.onResolve,
    required this.onAssign,
    required this.agentName,
  });

  final SupportTicket ticket;
  final VoidCallback onResolve;
  final VoidCallback onAssign;
  final String agentName;

  @override
  Widget build(BuildContext context) {
    final YaColors colors = YaColors.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(
        YaSpacing.xl,
        YaSpacing.lg,
        YaSpacing.xl,
        YaSpacing.lg,
      ),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: colors.borderSubtle)),
      ),
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final bool compact = constraints.maxWidth < 680;
          final Widget title = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                ticket.subject,
                style: YaText.lg.copyWith(color: colors.textPrimary),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 7),
              Wrap(
                spacing: YaSpacing.sm,
                runSpacing: YaSpacing.xs,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: <Widget>[
                  PriorityBadge(ticket.priority),
                  StatusBadge.fromMapping(
                    supportTicketStatusMapping(ticket.status),
                    size: StatusBadgeSize.sm,
                  ),
                  IdCell(ticket.id),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Aberto por ${ticket.authorName} (${supportRoleLabel(ticket.role).toLowerCase()}) / ${supportRelativeWhen(ticket.createdAt)}${ticket.tripId == null ? '' : ' / ${ticket.tripId}'}',
                style: YaText.sm.copyWith(color: colors.textSecondary),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          );

          final Widget actions = Wrap(
            spacing: YaSpacing.sm,
            runSpacing: YaSpacing.sm,
            children: <Widget>[
              if (ticket.assignee != agentName)
                YaButton.secondary(
                  label: 'Atribuir a mim',
                  icon: LucideIcons.userPlus,
                  onPressed: onAssign,
                )
              else
                YaButton.secondary(
                  label: 'Reatribuir',
                  icon: LucideIcons.userCog,
                  onPressed: onAssign,
                ),
              if (ticket.status != SupportTicketStatus.resolved)
                YaButton.primary(
                  label: 'Resolver',
                  icon: LucideIcons.check,
                  onPressed: onResolve,
                ),
            ],
          );

          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                title,
                const SizedBox(height: YaSpacing.md),
                actions,
              ],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(child: title),
              const SizedBox(width: YaSpacing.lg),
              actions,
            ],
          );
        },
      ),
    );
  }
}

class _ThreadEmpty extends StatelessWidget {
  const _ThreadEmpty();

  @override
  Widget build(BuildContext context) {
    final YaColors colors = YaColors.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 80),
      child: Text(
        'Aguarda primeira mensagem',
        textAlign: TextAlign.center,
        style: YaText.sm.copyWith(color: colors.textMuted),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message});

  final SupportMessage message;

  @override
  Widget build(BuildContext context) {
    final YaColors colors = YaColors.of(context);
    final bool agent = message.agent;
    final Color bg = agent ? colors.brandSubtle : colors.bgSubtle;

    final Widget bubble = Column(
      crossAxisAlignment:
          agent ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            if (!agent) YaAvatar.fromName(message.author, size: 24),
            if (!agent) const SizedBox(width: YaSpacing.sm),
            Flexible(
              child: Text(
                '${message.author} / ${supportShortTime(message.createdAt)}',
                style: YaText.xs.copyWith(color: colors.textMuted),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (agent) const SizedBox(width: YaSpacing.sm),
            if (agent) YaAvatar.fromName(message.author, size: 24),
          ],
        ),
        const SizedBox(height: 6),
        Container(
          constraints: const BoxConstraints(maxWidth: 560),
          padding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 10,
          ),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: YaRadius.brLg,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                message.text,
                style: YaText.sans(size: 13, height: 19.5)
                    .copyWith(color: colors.textPrimary),
              ),
              if (message.attachmentLabel != null) ...<Widget>[
                const SizedBox(height: YaSpacing.sm),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: YaSpacing.sm,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: colors.bgSurface,
                    borderRadius: YaRadius.brMd,
                    border: Border.all(color: colors.borderSubtle),
                  ),
                  child: Row(
                    children: <Widget>[
                      Icon(
                        LucideIcons.paperclip,
                        size: 13,
                        color: colors.textMuted,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          message.attachmentLabel!,
                          style: YaText.mono(size: 11, height: 14)
                              .copyWith(color: colors.textSecondary),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: YaSpacing.md),
      ],
    );

    return Align(
      alignment: agent ? Alignment.centerRight : Alignment.centerLeft,
      child: FractionallySizedBox(
        widthFactor: 0.78,
        alignment: agent ? Alignment.centerRight : Alignment.centerLeft,
        child: bubble,
      ),
    );
  }
}

class _ThreadComposer extends StatelessWidget {
  const _ThreadComposer({
    required this.controller,
    required this.macro,
    required this.macros,
    required this.onMacroChanged,
    required this.onInternalNotes,
    required this.onSend,
    required this.sending,
  });

  final TextEditingController controller;
  final String? macro;
  final List<YaSelectItem<String>> macros;
  final ValueChanged<String> onMacroChanged;
  final VoidCallback onInternalNotes;
  final VoidCallback onSend;
  final bool sending;

  @override
  Widget build(BuildContext context) {
    final YaColors colors = YaColors.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(
        YaSpacing.xl,
        YaSpacing.lg,
        YaSpacing.xl,
        YaSpacing.lg,
      ),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: colors.borderSubtle)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              final double width =
                  constraints.maxWidth < 260 ? constraints.maxWidth : 260;
              return Align(
                alignment: Alignment.centerLeft,
                child: YaSelect<String>(
                  width: width,
                  items: macros,
                  value: macro,
                  placeholder: 'Macros',
                  onChanged: onMacroChanged,
                ),
              );
            },
          ),
          const SizedBox(height: YaSpacing.md),
          YaTextarea(
            controller: controller,
            placeholder: 'Escreve uma resposta...',
            minLines: 3,
            maxLines: 6,
          ),
          const SizedBox(height: YaSpacing.md),
          LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              final bool compact = constraints.maxWidth < 560;
              final Widget meta = Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Icon(
                    LucideIcons.paperclip,
                    size: 16,
                    color: colors.textMuted,
                  ),
                  const SizedBox(width: YaSpacing.sm),
                  Text(
                    '${controller.text.length}/1200',
                    style: YaText.xs.copyWith(color: colors.textMuted),
                  ),
                ],
              );

              final Widget actions = Wrap(
                spacing: YaSpacing.sm,
                runSpacing: YaSpacing.sm,
                children: <Widget>[
                  YaButton.secondary(
                    label: 'Notas internas',
                    icon: LucideIcons.lock,
                    onPressed: onInternalNotes,
                  ),
                  YaButton.primary(
                    label: 'Enviar',
                    icon: LucideIcons.send,
                    loading: sending,
                    onPressed: onSend,
                  ),
                ],
              );

              if (compact) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    meta,
                    const SizedBox(height: YaSpacing.sm),
                    actions,
                  ],
                );
              }

              return Row(
                children: <Widget>[
                  Expanded(child: meta),
                  actions,
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class DisputeMiniCard extends StatelessWidget {
  const DisputeMiniCard({
    required this.dispute,
    super.key,
  });

  final SupportDispute dispute;

  @override
  Widget build(BuildContext context) {
    final YaColors colors = YaColors.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: YaSpacing.lg,
        vertical: YaSpacing.md,
      ),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: colors.borderSubtle)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Text(
                List<String>.filled(dispute.rating, '*').join(),
                style: YaText.smMedium.copyWith(color: colors.danger),
              ),
              const Spacer(),
              IdCell(dispute.tripId),
            ],
          ),
          const SizedBox(height: YaSpacing.sm),
          Text(
            dispute.comment,
            style: YaText.sm.copyWith(color: colors.textSecondary),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: YaSpacing.md),
          LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              final bool compact = constraints.maxWidth < 320;
              final Widget driver = PersonCell(
                name: dispute.driverName,
                subtitle: dispute.tripId,
                avatarSize: 24,
              );
              final Widget action = YaButton.ghost(
                label: 'Investigar',
                icon: LucideIcons.arrowRight,
                size: YaButtonSize.sm,
                onPressed: () => context.go('/support/disputes'),
              );

              if (compact) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    driver,
                    const SizedBox(height: YaSpacing.sm),
                    action,
                  ],
                );
              }

              return Row(
                children: <Widget>[
                  Expanded(child: driver),
                  action,
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

Future<void> openNewSupportTicketDialog(BuildContext context) {
  return showDialog<void>(
    context: context,
    builder: (BuildContext _) => const _NewTicketDialog(),
  );
}

class _NewTicketDialog extends ConsumerStatefulWidget {
  const _NewTicketDialog();

  @override
  ConsumerState<_NewTicketDialog> createState() => _NewTicketDialogState();
}

class _NewTicketDialogState extends ConsumerState<_NewTicketDialog> {
  final TextEditingController _subject = TextEditingController();
  final TextEditingController _message = TextEditingController();
  String _priority = 'medium';
  bool _busy = false;

  @override
  void dispose() {
    _subject.dispose();
    _message.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_busy) return;
    final String subject = _subject.text.trim();
    if (subject.isEmpty) {
      supportToast(
        context,
        'Indica um assunto.',
        variant: StatusVariant.danger,
      );
      return;
    }
    setState(() => _busy = true);
    try {
      final String message = _message.text.trim();
      await ref.read(cloudFunctionsServiceProvider).createTicket(
            subject: subject,
            priority: _priority,
            text: message.isEmpty ? null : message,
          );
      if (!mounted) return;
      ref.invalidate(supportTicketsProvider);
      ref.invalidate(supportActiveTicketsProvider);
      Navigator.of(context).pop();
      supportToast(context, 'Ticket criado');
    } catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      supportToast(context, 'Erro: $e', variant: StatusVariant.danger);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FormDialog(
      title: 'Novo ticket',
      description: 'Abre um caso manual para passageiro, driver ou partner.',
      confirmLabel: 'Criar ticket',
      submitting: _busy,
      onCancel: () => Navigator.of(context).pop(),
      onConfirm: _submit,
      children: <Widget>[
        YaField(
          label: 'Prioridade',
          child: YaSelect<String>(
            width: 280,
            items: const <YaSelectItem<String>>[
              YaSelectItem(value: 'urgent', label: 'Urgente'),
              YaSelectItem(value: 'high', label: 'Alta'),
              YaSelectItem(value: 'medium', label: 'Media'),
              YaSelectItem(value: 'low', label: 'Baixa'),
            ],
            value: _priority,
            onChanged: (String value) => setState(() => _priority = value),
          ),
        ),
        YaField(
          label: 'Assunto',
          child: YaInput(
            controller: _subject,
            placeholder: 'Resumo curto do caso',
          ),
        ),
        YaField(
          label: 'Mensagem inicial',
          child: YaTextarea(
            controller: _message,
            placeholder: 'Descreve o problema...',
          ),
        ),
      ],
    );
  }
}

Future<void> openQuickActionsDialog(
  BuildContext context,
  SupportQuickResult result,
) {
  final List<_QuickAction> actions = <_QuickAction>[
    _QuickAction(
      icon: LucideIcons.externalLink,
      title: 'Ver perfil completo',
      description: 'Abre a ficha operacional associada.',
      onTap: () {
        Navigator.of(context).pop();
        if (result.route != null) context.go(result.route!);
      },
    ),
    if (result.type == SupportQuickResultType.passenger ||
        result.type == SupportQuickResultType.driver)
      _QuickAction(
        icon: LucideIcons.keyRound,
        title: 'Resetar password',
        description: 'Envia um link seguro de reposicao.',
        onTap: () => supportToast(context, 'Reset enviado'),
      ),
    if (result.type == SupportQuickResultType.passenger ||
        result.type == SupportQuickResultType.driver)
      _QuickAction(
        icon: LucideIcons.logOut,
        title: 'Forçar logout',
        description: 'Termina sessões ativas nos dispositivos.',
        onTap: () => supportToast(context, 'Logout forçado'),
      ),
    if (result.type == SupportQuickResultType.driver ||
        result.type == SupportQuickResultType.partner)
      _QuickAction(
        icon: LucideIcons.ban,
        title: 'Suspender',
        description: 'Bloqueia temporariamente a conta.',
        destructive: true,
        onTap: () => supportToast(
          context,
          'Perfil suspenso',
          variant: StatusVariant.warning,
        ),
      ),
    _QuickAction(
      icon: LucideIcons.ticketPlus,
      title: 'Abrir ticket em nome de',
      description: 'Cria um caso já ligado a este registo.',
      onTap: () {
        Navigator.of(context).pop();
        openNewSupportTicketDialog(context);
      },
    ),
  ];

  return showDialog<void>(
    context: context,
    builder: (BuildContext context) => FormDialog(
      title: result.title,
      description: '${supportQuickTypeLabel(result.type)} / ${result.id}',
      confirmLabel: 'Fechar',
      onConfirm: () => Navigator.of(context).pop(),
      children: <Widget>[
        for (final _QuickAction action in actions)
          _QuickActionButton(action: action),
      ],
    ),
  );
}

class _QuickAction {
  const _QuickAction({
    required this.icon,
    required this.title,
    required this.description,
    required this.onTap,
    this.destructive = false,
  });

  final IconData icon;
  final String title;
  final String description;
  final VoidCallback onTap;
  final bool destructive;
}

class _QuickActionButton extends StatelessWidget {
  const _QuickActionButton({required this.action});

  final _QuickAction action;

  @override
  Widget build(BuildContext context) {
    final YaColors colors = YaColors.of(context);
    final Color color = action.destructive ? colors.danger : colors.textPrimary;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: action.onTap,
        child: Container(
          padding: const EdgeInsets.all(YaSpacing.md),
          decoration: BoxDecoration(
            color: colors.bgSubtle,
            borderRadius: YaRadius.brMd,
            border: Border.all(color: colors.borderSubtle),
          ),
          child: Row(
            children: <Widget>[
              Icon(action.icon, size: 18, color: color),
              const SizedBox(width: YaSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      action.title,
                      style: YaText.smMedium.copyWith(color: color),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      action.description,
                      style: YaText.sans(size: 12, height: 16)
                          .copyWith(color: colors.textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
