import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/auth/auth_provider.dart';
import '../../core/auth/auth_user.dart';
import '../../core/constants/status_mapping.dart';
import '../../data/providers.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../shared/widgets/dialogs/confirm_dialog.dart';
import '../../shared/widgets/feedback/empty_state.dart';
import '../../shared/widgets/feedback/status_badge.dart';
import '../../shared/widgets/forms/ya_avatar.dart';
import '../../shared/widgets/forms/ya_button.dart';
import '../../shared/widgets/forms/ya_textarea.dart';
import '../../shared/widgets/shell/page_header.dart';
import '../../shared/widgets/table/cells.dart';
import '../../theme/tokens/colors.dart';
import '../../theme/tokens/dimensions.dart';
import '../../theme/tokens/typography.dart';
import '../data/mock_support_data.dart';
import '../data/mock_types.dart';
import '../widgets/support_common.dart';

class SupportChatPage extends ConsumerStatefulWidget {
  const SupportChatPage({super.key});

  @override
  ConsumerState<SupportChatPage> createState() => _SupportChatPageState();
}

class _SupportChatPageState extends ConsumerState<SupportChatPage> {
  String? _selectedId;
  // Optimistic echo of agent messages so the thread updates instantly while
  // the provider refresh is in flight.
  final Map<String, List<SupportMessage>> _localEcho =
      <String, List<SupportMessage>>{};

  void _selectThread(String id) {
    setState(() => _selectedId = id);
    ref.read(supportDataRepositoryProvider).updateChatThread(
      id,
      <String, dynamic>{'unread': 0},
    );
  }

  Future<void> _appendAgentMessage(
    SupportChatThread thread,
    String text,
  ) async {
    final AuthUser? user = ref.read(authStateProvider);
    final String author = user?.name ?? 'Suporte';
    setState(() {
      _localEcho.putIfAbsent(thread.id, () => <SupportMessage>[]).add(
            SupportMessage(
              author: author,
              role: SupportActorRole.agent,
              agent: true,
              createdAt: DateTime.now(),
              text: text,
            ),
          );
    });
    try {
      await ref
          .read(supportDataRepositoryProvider)
          .sendChatMessage(thread.id, text, author);
      ref.invalidate(supportChatThreadsProvider);
    } catch (e) {
      if (!mounted) return;
      supportToast(context, 'Erro: $e', variant: StatusVariant.danger);
    }
  }

  Future<void> _closeThread(SupportChatThread thread, String reason) async {
    try {
      await ref.read(supportDataRepositoryProvider).updateChatThread(
        thread.id,
        <String, dynamic>{
          'status': 'closed',
          if (reason.isNotEmpty) 'closeReason': reason,
        },
      );
      if (!mounted) return;
      ref.invalidate(supportChatThreadsProvider);
      setState(() => _selectedId = null);
      supportToast(
        context,
        'Conversa ${thread.id} encerrada',
        variant: StatusVariant.info,
      );
    } catch (e) {
      if (!mounted) return;
      supportToast(context, 'Erro: $e', variant: StatusVariant.danger);
    }
  }

  Future<void> _convertToTicket(SupportChatThread thread) async {
    try {
      final String ticketId =
          await ref.read(cloudFunctionsServiceProvider).createTicket(
                subject: 'Chat com ${thread.contactName}',
                authorName: thread.contactName,
                tripId: thread.tripId,
                text: thread.messages.isEmpty
                    ? null
                    : thread.messages.last.text,
              );
      if (!mounted) return;
      ref.invalidate(supportTicketsProvider);
      supportToast(context, 'Conversa convertida em ticket');
      context.go('/support/tickets/$ticketId');
    } catch (e) {
      if (!mounted) return;
      supportToast(context, 'Erro: $e', variant: StatusVariant.danger);
    }
  }

  Future<void> _reassign(SupportChatThread thread) async {
    final AuthUser? user = ref.read(authStateProvider);
    if (user == null) return;
    try {
      await ref.read(supportDataRepositoryProvider).updateChatThread(
        thread.id,
        <String, dynamic>{'assignedTo': user.uid},
      );
      if (!mounted) return;
      ref.invalidate(supportChatThreadsProvider);
      supportToast(
        context,
        'Conversa atribuída a si',
        variant: StatusVariant.info,
      );
    } catch (e) {
      if (!mounted) return;
      supportToast(context, 'Erro: $e', variant: StatusVariant.danger);
    }
  }

  SupportChatThread _withEcho(SupportChatThread thread) {
    final List<SupportMessage> echo =
        _localEcho[thread.id] ?? const <SupportMessage>[];
    if (echo.isEmpty) return thread;
    final Set<String> existing =
        thread.messages.map((SupportMessage m) => m.text).toSet();
    final List<SupportMessage> pending = echo
        .where((SupportMessage m) => !existing.contains(m.text))
        .toList();
    if (pending.isEmpty) return thread;
    thread.messages.addAll(pending);
    return thread;
  }

  @override
  Widget build(BuildContext context) {
    final List<SupportChatThread> allThreads =
        ref.watch(supportChatThreadsProvider).asData?.value ??
            <SupportChatThread>[];
    final List<SupportChatThread> threads = allThreads
        .where((SupportChatThread t) => t.status != SupportChatStatus.closed)
        .toList();
    final String? effectiveId =
        _selectedId ?? (threads.isEmpty ? null : threads.first.id);
    final SupportChatThread? selectedRaw = threads
        .where((SupportChatThread t) => t.id == effectiveId)
        .firstOrNull;
    final SupportChatThread? selected =
        selectedRaw == null ? null : _withEcho(selectedRaw);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        PageHeader(
          title: S.of(context).supportChatTitle,
          description:
              'Atendimento em tempo real · ${threads.length} conversas ativas',
          actions: <Widget>[
            const SupportServicePill(),
            YaButton.secondary(
              label: 'Fila de tickets',
              icon: LucideIcons.inbox,
              onPressed: () => context.go('/support/tickets'),
            ),
          ],
        ),
        const SizedBox(height: YaSpacing.xxl),
        SizedBox(
          height: 680,
          child: LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              final double w = constraints.maxWidth;
              final bool showContext = w >= 1280;
              final bool showList = w >= 820 || selected == null;
              final bool showThread = w >= 820 || selected != null;
              return SupportCard(
                padding: EdgeInsets.zero,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    if (showList && !showThread)
                      Expanded(
                        child: _ConversationList(
                          threads: threads,
                          selectedId: effectiveId,
                          onSelect: _selectThread,
                        ),
                      )
                    else if (showList)
                      SizedBox(
                        width: 300,
                        child: _ConversationList(
                          threads: threads,
                          selectedId: effectiveId,
                          onSelect: _selectThread,
                        ),
                      ),
                    if (showList && showThread)
                      VerticalDivider(
                        width: 1,
                        thickness: 1,
                        color: YaColors.of(context).borderSubtle,
                      ),
                    if (showThread)
                      Expanded(
                        child: selected == null
                            ? const _ChatEmpty()
                            : _ThreadPane(
                                key: ValueKey<String>(selected.id),
                                thread: selected,
                                onSend: (String text) =>
                                    _appendAgentMessage(selected, text),
                                onClose: _closeThread,
                                onConvert: _convertToTicket,
                                onReassign: _reassign,
                                onBack: w < 820
                                    ? () => setState(() => _selectedId = null)
                                    : null,
                              ),
                      ),
                    if (showContext && selected != null)
                      VerticalDivider(
                        width: 1,
                        thickness: 1,
                        color: YaColors.of(context).borderSubtle,
                      ),
                    if (showContext && selected != null)
                      SizedBox(
                        width: 320,
                        child: _ContextPanel(thread: selected),
                      ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _ConversationList extends StatelessWidget {
  const _ConversationList({
    required this.threads,
    required this.selectedId,
    required this.onSelect,
  });

  final List<SupportChatThread> threads;
  final String? selectedId;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    final colors = YaColors.of(context);
    if (threads.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(YaSpacing.xl),
        child: EmptyState(
          icon: LucideIcons.messageCircle,
          title: 'Sem conversas ativas',
          description: 'Aguarda novos pedidos de atendimento.',
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: YaSpacing.lg,
            vertical: YaSpacing.md,
          ),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: colors.borderSubtle)),
          ),
          child: Row(
            children: <Widget>[
              Text(
                'Conversas',
                style: YaText.smMedium.copyWith(color: colors.textPrimary),
              ),
              const Spacer(),
              StatusBadge(
                variant: StatusVariant.brand,
                label: '${threads.length}',
                size: StatusBadgeSize.sm,
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: threads.length,
            itemBuilder: (BuildContext context, int index) {
              final SupportChatThread thread = threads[index];
              return _ConversationItem(
                thread: thread,
                selected: thread.id == selectedId,
                onTap: () => onSelect(thread.id),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _ConversationItem extends StatefulWidget {
  const _ConversationItem({
    required this.thread,
    required this.selected,
    required this.onTap,
  });

  final SupportChatThread thread;
  final bool selected;
  final VoidCallback onTap;

  @override
  State<_ConversationItem> createState() => _ConversationItemState();
}

class _ConversationItemState extends State<_ConversationItem> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final colors = YaColors.of(context);
    final t = widget.thread;
    final Color bg = widget.selected
        ? colors.brandSubtle
        : (_hover ? colors.bgSubtle : Colors.transparent);
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: YaSpacing.lg,
            vertical: YaSpacing.md,
          ),
          decoration: BoxDecoration(
            color: bg,
            border: Border(
              bottom: BorderSide(color: colors.borderSubtle),
              left: BorderSide(
                color: widget.selected ? colors.brand : Colors.transparent,
                width: 2,
              ),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              YaAvatar.fromName(t.contactName, size: 36),
              const SizedBox(width: YaSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Icon(
                          supportRoleIcon(t.role),
                          size: 12,
                          color: colors.textMuted,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            t.contactName,
                            style: YaText.smMedium
                                .copyWith(color: colors.textPrimary),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: YaSpacing.xs),
                        Text(
                          supportShortTime(t.lastMessageAt),
                          style: YaText.xs.copyWith(color: colors.textMuted),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      t.lastMessage.text,
                      style: YaText.xs.copyWith(color: colors.textSecondary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: YaSpacing.sm),
                    Wrap(
                      spacing: YaSpacing.xs,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: <Widget>[
                        PriorityBadge(t.priority),
                        if (t.status == SupportChatStatus.typing)
                          const _TypingIndicator(),
                        if (t.status == SupportChatStatus.waiting)
                          const StatusBadge(
                            variant: StatusVariant.warning,
                            label: 'Aguarda',
                            size: StatusBadgeSize.sm,
                          ),
                        if (t.unread > 0)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: colors.brand,
                              borderRadius: YaRadius.brFull,
                            ),
                            child: Text(
                              '${t.unread}',
                              style: YaText.xs.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                      ],
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

class _TypingIndicator extends StatelessWidget {
  const _TypingIndicator();

  @override
  Widget build(BuildContext context) {
    final colors = YaColors.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: colors.infoSubtle,
        borderRadius: YaRadius.brFull,
      ),
      child: Text(
        'A escrever...',
        style: YaText.xs.copyWith(color: colors.info),
      ),
    );
  }
}

class _ThreadPane extends StatefulWidget {
  const _ThreadPane({
    required this.thread,
    required this.onSend,
    required this.onClose,
    required this.onConvert,
    required this.onReassign,
    this.onBack,
    super.key,
  });

  final SupportChatThread thread;
  final ValueChanged<String> onSend;
  final void Function(SupportChatThread thread, String reason) onClose;
  final ValueChanged<SupportChatThread> onConvert;
  final ValueChanged<SupportChatThread> onReassign;
  final VoidCallback? onBack;

  @override
  State<_ThreadPane> createState() => _ThreadPaneState();
}

class _ThreadPaneState extends State<_ThreadPane> {
  final TextEditingController _ctrl = TextEditingController();
  final ScrollController _scroll = ScrollController();

  @override
  void didUpdateWidget(covariant _ThreadPane old) {
    super.didUpdateWidget(old);
    if (old.thread.id != widget.thread.id) {
      _ctrl.clear();
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (!_scroll.hasClients) return;
    _scroll.animateTo(
      _scroll.position.maxScrollExtent,
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
    );
  }

  void _send() {
    final String text = _ctrl.text.trim();
    if (text.isEmpty) return;
    widget.onSend(text);
    _ctrl.clear();
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
  }

  void _useQuickReply(String text) {
    if (_ctrl.text.isEmpty) {
      _ctrl.text = text;
    } else {
      _ctrl.text = '${_ctrl.text} $text';
    }
  }

  void _openCloseDialog() {
    final TextEditingController reason = TextEditingController();
    showDialog<void>(
      context: context,
      builder: (BuildContext ctx) => ConfirmDialog(
        title: 'Encerrar conversa ${widget.thread.id}?',
        description:
            'A conversa sai da fila ativa. Adiciona um breve motivo para o registo.',
        icon: LucideIcons.x,
        confirmLabel: 'Encerrar',
        onConfirm: () {
          Navigator.of(ctx).pop();
          widget.onClose(widget.thread, reason.text.trim());
        },
        body: Padding(
          padding: const EdgeInsets.only(top: YaSpacing.md),
          child: YaTextarea(
            controller: reason,
            placeholder: 'Motivo (opcional)',
            minLines: 2,
            maxLines: 4,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = YaColors.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        _ThreadHeader(
          thread: widget.thread,
          onBack: widget.onBack,
          onClose: _openCloseDialog,
          onConvert: () => widget.onConvert(widget.thread),
          onReassign: () => widget.onReassign(widget.thread),
        ),
        Expanded(
          child: Container(
            color: colors.bgBase,
            child: ListView.builder(
              controller: _scroll,
              padding: const EdgeInsets.all(YaSpacing.xl),
              itemCount: widget.thread.messages.length,
              itemBuilder: (BuildContext context, int index) {
                final SupportMessage m = widget.thread.messages[index];
                return _ChatBubble(message: m);
              },
            ),
          ),
        ),
        _Composer(
          controller: _ctrl,
          onSend: _send,
          onQuickReply: _useQuickReply,
        ),
      ],
    );
  }
}

class _ThreadHeader extends StatelessWidget {
  const _ThreadHeader({
    required this.thread,
    required this.onClose,
    required this.onConvert,
    required this.onReassign,
    this.onBack,
  });

  final SupportChatThread thread;
  final VoidCallback onClose;
  final VoidCallback onConvert;
  final VoidCallback onReassign;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final colors = YaColors.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: YaSpacing.xl,
        vertical: YaSpacing.lg,
      ),
      decoration: BoxDecoration(
        color: colors.bgSurface,
        border: Border(bottom: BorderSide(color: colors.borderSubtle)),
      ),
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final bool compact = constraints.maxWidth < 720;
          final Widget actions = compact
              ? PopupMenuButton<String>(
                  tooltip: 'Acoes',
                  icon: Icon(
                    LucideIcons.ellipsis,
                    size: 18,
                    color: colors.textSecondary,
                  ),
                  onSelected: (String value) {
                    switch (value) {
                      case 'reassign':
                        onReassign();
                      case 'convert':
                        onConvert();
                      case 'close':
                        onClose();
                    }
                  },
                  itemBuilder: (BuildContext _) => <PopupMenuEntry<String>>[
                    const PopupMenuItem<String>(
                      value: 'reassign',
                      child: Text('Reatribuir'),
                    ),
                    const PopupMenuItem<String>(
                      value: 'convert',
                      child: Text('Converter em ticket'),
                    ),
                    const PopupMenuItem<String>(
                      value: 'close',
                      child: Text('Encerrar'),
                    ),
                  ],
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    YaButton.ghost(
                      label: 'Reatribuir',
                      icon: LucideIcons.userPlus,
                      onPressed: onReassign,
                    ),
                    const SizedBox(width: YaSpacing.sm),
                    YaButton.ghost(
                      label: 'Converter',
                      icon: LucideIcons.fileText,
                      onPressed: onConvert,
                    ),
                    const SizedBox(width: YaSpacing.sm),
                    YaButton.destructive(
                      label: 'Encerrar',
                      icon: LucideIcons.x,
                      onPressed: onClose,
                    ),
                  ],
                );

          return Row(
            children: <Widget>[
              if (onBack != null) ...<Widget>[
                IconButton(
                  icon: const Icon(LucideIcons.arrowLeft, size: 18),
                  tooltip: S.of(context).commonBack,
                  onPressed: onBack,
                  splashRadius: 20,
                  constraints:
                      const BoxConstraints(minWidth: 32, minHeight: 32),
                  padding: EdgeInsets.zero,
                ),
                const SizedBox(width: YaSpacing.xs),
              ],
              YaAvatar.fromName(thread.contactName, size: 36),
              const SizedBox(width: YaSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      thread.contactName,
                      style:
                          YaText.smMedium.copyWith(color: colors.textPrimary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (!compact) ...<Widget>[
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: YaSpacing.xs,
                        runSpacing: 2,
                        children: <Widget>[
                          StatusBadge(
                            variant: StatusVariant.brand,
                            label: supportRoleLabel(thread.role),
                            size: StatusBadgeSize.sm,
                          ),
                          PriorityBadge(thread.priority),
                        ],
                      ),
                    ],
                    const SizedBox(height: 2),
                    Text(
                      compact
                          ? thread.contactPhone
                          : '${thread.contactPhone} / iniciada ${supportRelativeWhen(thread.startedAt)}',
                      style: YaText.xs.copyWith(color: colors.textSecondary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: YaSpacing.sm),
              actions,
            ],
          );
        },
      ),
    );
  }
}

class _ChatBubble extends StatelessWidget {
  const _ChatBubble({required this.message});

  final SupportMessage message;

  @override
  Widget build(BuildContext context) {
    final colors = YaColors.of(context);
    final bool agent = message.agent;
    final Color bg = agent ? colors.brandSubtle : colors.bgSurface;
    return Align(
      alignment: agent ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Padding(
          padding: const EdgeInsets.only(bottom: YaSpacing.md),
          child: Column(
            crossAxisAlignment:
                agent ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: <Widget>[
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: bg,
                  borderRadius: YaRadius.brLg,
                  border: agent ? null : Border.all(color: colors.borderSubtle),
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
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            Icon(
                              LucideIcons.paperclip,
                              size: 13,
                              color: colors.textMuted,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              message.attachmentLabel!,
                              style: YaText.mono(size: 11, height: 14)
                                  .copyWith(color: colors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${message.author} / ${supportShortTime(message.createdAt)}',
                style: YaText.xs.copyWith(color: colors.textMuted),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Composer extends StatefulWidget {
  const _Composer({
    required this.controller,
    required this.onSend,
    required this.onQuickReply,
  });

  final TextEditingController controller;
  final VoidCallback onSend;
  final ValueChanged<String> onQuickReply;

  @override
  State<_Composer> createState() => _ComposerState();
}

class _ComposerState extends State<_Composer> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onChange);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onChange);
    super.dispose();
  }

  void _onChange() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final colors = YaColors.of(context);
    final bool canSend = widget.controller.text.trim().isNotEmpty;
    return Container(
      padding: const EdgeInsets.fromLTRB(
        YaSpacing.xl,
        YaSpacing.md,
        YaSpacing.xl,
        YaSpacing.lg,
      ),
      decoration: BoxDecoration(
        color: colors.bgSurface,
        border: Border(top: BorderSide(color: colors.borderSubtle)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: <Widget>[
                for (final String reply
                    in MockSupport.chatQuickReplies) ...<Widget>[
                  _QuickReplyChip(
                    label: reply,
                    onTap: () => widget.onQuickReply(reply),
                  ),
                  const SizedBox(width: YaSpacing.sm),
                ],
              ],
            ),
          ),
          const SizedBox(height: YaSpacing.md),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: <Widget>[
              Expanded(
                child: YaTextarea(
                  controller: widget.controller,
                  placeholder: 'Escreve uma mensagem...',
                  minLines: 1,
                  maxLines: 5,
                ),
              ),
              const SizedBox(width: YaSpacing.md),
              YaButton.primary(
                label: 'Enviar',
                icon: LucideIcons.send,
                onPressed: canSend ? widget.onSend : null,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuickReplyChip extends StatefulWidget {
  const _QuickReplyChip({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  State<_QuickReplyChip> createState() => _QuickReplyChipState();
}

class _QuickReplyChipState extends State<_QuickReplyChip> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final colors = YaColors.of(context);
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: YaDurations.micro,
          padding: const EdgeInsets.symmetric(
            horizontal: YaSpacing.md,
            vertical: 6,
          ),
          decoration: BoxDecoration(
            color: _hover ? colors.bgSubtle : colors.bgSurface,
            borderRadius: YaRadius.brFull,
            border: Border.all(color: colors.borderSubtle),
          ),
          child: Text(
            widget.label,
            style: YaText.xs.copyWith(color: colors.textSecondary),
          ),
        ),
      ),
    );
  }
}

class _ContextPanel extends StatelessWidget {
  const _ContextPanel({required this.thread});

  final SupportChatThread thread;

  @override
  Widget build(BuildContext context) {
    final colors = YaColors.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(YaSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(
            'Contacto',
            style: YaText.smMedium.copyWith(color: colors.textPrimary),
          ),
          const SizedBox(height: YaSpacing.md),
          PersonCell(
            name: thread.contactName,
            subtitle: thread.contactPhone,
            avatarSize: 40,
          ),
          const SizedBox(height: YaSpacing.sm),
          StatusBadge(
            variant: StatusVariant.brand,
            label: supportRoleLabel(thread.role),
            size: StatusBadgeSize.sm,
          ),
          const SizedBox(height: YaSpacing.lg),
          YaButton.secondary(
            label: 'Ver perfil completo',
            icon: LucideIcons.externalLink,
            onPressed: () => supportToast(
              context,
              'Perfil aberto',
              variant: StatusVariant.info,
            ),
          ),
          if (thread.tripId != null) ...<Widget>[
            const SizedBox(height: YaSpacing.xl),
            Divider(color: colors.borderSubtle, height: 1),
            const SizedBox(height: YaSpacing.lg),
            Text(
              'Corrida relacionada',
              style: YaText.smMedium.copyWith(color: colors.textPrimary),
            ),
            const SizedBox(height: YaSpacing.md),
            IdCell(thread.tripId!),
            const SizedBox(height: YaSpacing.xs),
            Text(
              '${thread.tripFrom} -> ${thread.tripTo}',
              style: YaText.sm.copyWith(color: colors.textPrimary),
            ),
            if (thread.tripAmount != null) ...<Widget>[
              const SizedBox(height: YaSpacing.xs),
              Text(
                supportMoney(thread.tripAmount!),
                style: YaText.monoBase.copyWith(color: colors.textSecondary),
              ),
            ],
            const SizedBox(height: YaSpacing.md),
            YaButton.secondary(
              label: 'Abrir corrida',
              icon: LucideIcons.route,
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const SizedBox.shrink(),
                ),
              ),
            ),
          ],
          if (thread.recentTickets.isNotEmpty) ...<Widget>[
            const SizedBox(height: YaSpacing.xl),
            Divider(color: colors.borderSubtle, height: 1),
            const SizedBox(height: YaSpacing.lg),
            Text(
              'Tickets recentes',
              style: YaText.smMedium.copyWith(color: colors.textPrimary),
            ),
            const SizedBox(height: YaSpacing.md),
            for (final String tid in thread.recentTickets) ...<Widget>[
              _RecentTicketRow(ticketId: tid),
              const SizedBox(height: YaSpacing.sm),
            ],
          ],
        ],
      ),
    );
  }
}

class _RecentTicketRow extends StatelessWidget {
  const _RecentTicketRow({required this.ticketId});

  final String ticketId;

  @override
  Widget build(BuildContext context) {
    final colors = YaColors.of(context);
    return InkWell(
      onTap: () => context.go('/support/tickets/$ticketId'),
      borderRadius: YaRadius.brMd,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: YaSpacing.md,
          vertical: YaSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: colors.bgSubtle,
          borderRadius: YaRadius.brMd,
        ),
        child: Row(
          children: <Widget>[
            Icon(LucideIcons.fileText, size: 14, color: colors.textMuted),
            const SizedBox(width: YaSpacing.sm),
            Expanded(
              child: Text(
                ticketId,
                style: YaText.mono(size: 12, height: 16)
                    .copyWith(color: colors.textPrimary),
              ),
            ),
            Icon(LucideIcons.chevronRight, size: 14, color: colors.textMuted),
          ],
        ),
      ),
    );
  }
}

class _ChatEmpty extends StatelessWidget {
  const _ChatEmpty();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: EmptyState(
        icon: LucideIcons.messageCircle,
        title: 'Nenhuma conversa selecionada',
        description: 'Seleciona uma conversa da fila para começar a atender.',
      ),
    );
  }
}
