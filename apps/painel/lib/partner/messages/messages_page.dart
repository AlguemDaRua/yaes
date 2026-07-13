import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/constants/status_mapping.dart';
import '../../data/providers.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../shared/widgets/feedback/status_badge.dart';
import '../../shared/widgets/forms/ya_avatar.dart';
import '../../shared/widgets/forms/ya_button.dart';
import '../../shared/widgets/forms/ya_textarea.dart';
import '../../shared/widgets/shell/page_header.dart';
import '../../theme/tokens/colors.dart';
import '../../theme/tokens/dimensions.dart';
import '../../theme/tokens/typography.dart';
import '../data/mock_partner_data.dart';
import '../widgets/partner_common.dart';

class PartnerMessagesPage extends ConsumerStatefulWidget {
  const PartnerMessagesPage({super.key});

  @override
  ConsumerState<PartnerMessagesPage> createState() =>
      _PartnerMessagesPageState();
}

class _PartnerMessagesPageState extends ConsumerState<PartnerMessagesPage> {
  final TextEditingController _controller = TextEditingController();
  String? _selectedId;
  String _draft = '';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final List<MockMessageThread> liveThreads =
        ref.watch(messageThreadsProvider).value ??
            const <MockMessageThread>[];
    final List<_Thread> threads = liveThreads.map((MockMessageThread t) {
      return _Thread(
        id: t.id,
        name: t.participant,
        badge: t.subject,
        preview: t.lastMessage,
        unread: t.unreadCount,
        readOnly: false,
        messages: const <_Message>[],
      );
    }).toList();

    final Widget body = threads.isEmpty
        ? const PartnerCard(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: YaSpacing.xxl),
              child: Center(
                child: Text('Ainda não há conversas com as equipas YA.'),
              ),
            ),
          )
        : _buildChat(context, threads);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        PageHeader(
          title: S.of(context).partnerNavMessages,
          description: 'Conversas com equipas YA',
        ),
        const SizedBox(height: YaSpacing.xxl),
        body,
      ],
    );
  }

  Widget _buildChat(BuildContext context, List<_Thread> threads) {
    final String selectedId = (_selectedId != null &&
            threads.any((_Thread t) => t.id == _selectedId))
        ? _selectedId!
        : threads.first.id;

    final List<MockChatMessage> liveMsgs =
        ref.watch(partnerThreadMessagesProvider(selectedId)).value ??
            const <MockChatMessage>[];
    final _Thread base =
        threads.firstWhere((_Thread t) => t.id == selectedId);
    final _Thread selected = _Thread(
      id: base.id,
      name: base.name,
      badge: base.badge,
      preview: base.preview,
      unread: base.unread,
      readOnly: base.readOnly,
      messages: liveMsgs.map((MockChatMessage m) {
        return _Message(
          text: m.text,
          fromMe: m.fromPartner,
          timestamp: m.timestamp,
        );
      }).toList(),
    );

    return PartnerCard(
      padding: EdgeInsets.zero,
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final bool compact =
              constraints.maxWidth.isFinite && constraints.maxWidth < 820;
          if (compact) {
            return SizedBox(
              height: 620,
              child: _MessageThreadView(
                thread: selected,
                controller: _controller,
                draft: _draft,
                onDraftChanged: (String value) =>
                    setState(() => _draft = value),
                onSend: () => _send(selectedId),
              ),
            );
          }

          return SizedBox(
            height: 620,
            child: Row(
              children: <Widget>[
                SizedBox(
                  width: 320,
                  child: _ConversationsList(
                    threads: threads,
                    selectedId: selectedId,
                    onSelected: (String id) =>
                        setState(() => _selectedId = id),
                  ),
                ),
                VerticalDivider(
                  width: 1,
                  color: YaColors.of(context).borderSubtle,
                ),
                Expanded(
                  child: _MessageThreadView(
                    thread: selected,
                    controller: _controller,
                    draft: _draft,
                    onDraftChanged: (String value) =>
                        setState(() => _draft = value),
                    onSend: () => _send(selectedId),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _send(String threadId) async {
    final String text = _draft.trim();
    if (text.isEmpty) return;
    setState(() {
      _draft = '';
      _controller.clear();
    });
    await ref
        .read(partnerDataRepositoryProvider)
        .sendThreadMessage(threadId, text);
  }
}

class _ConversationsList extends StatelessWidget {
  const _ConversationsList({
    required this.threads,
    required this.selectedId,
    required this.onSelected,
  });

  final List<_Thread> threads;
  final String selectedId;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(YaSpacing.sm),
      children: <Widget>[
        for (final _Thread thread in threads)
          _ConversationItem(
            thread: thread,
            selected: thread.id == selectedId,
            onTap: () => onSelected(thread.id),
          ),
      ],
    );
  }
}

class _ConversationItem extends StatelessWidget {
  const _ConversationItem({
    required this.thread,
    required this.selected,
    required this.onTap,
  });

  final _Thread thread;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final YaColors colors = YaColors.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: YaRadius.brMd,
      child: Container(
        padding: const EdgeInsets.all(YaSpacing.md),
        decoration: BoxDecoration(
          color: selected ? colors.brandSubtle : Colors.transparent,
          borderRadius: YaRadius.brMd,
        ),
        child: Row(
          children: <Widget>[
            YaAvatar.fromName(thread.name, border: true),
            const SizedBox(width: YaSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    thread.name,
                    style: YaText.smMedium.copyWith(color: colors.textPrimary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    thread.preview,
                    style: YaText.sm.copyWith(color: colors.textSecondary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    'ha pouco',
                    style: YaText.sans(size: 12, height: 16)
                        .copyWith(color: colors.textMuted),
                  ),
                ],
              ),
            ),
            if (thread.unread > 0)
              Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  color: colors.brand,
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _MessageThreadView extends StatelessWidget {
  const _MessageThreadView({
    required this.thread,
    required this.controller,
    required this.draft,
    required this.onDraftChanged,
    required this.onSend,
  });

  final _Thread thread;
  final TextEditingController controller;
  final String draft;
  final ValueChanged<String> onDraftChanged;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    final YaColors colors = YaColors.of(context);
    return Column(
      children: <Widget>[
        Container(
          padding: const EdgeInsets.all(YaSpacing.lg),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: colors.borderSubtle)),
          ),
          child: Row(
            children: <Widget>[
              YaAvatar.fromName(thread.name, size: 40, border: true),
              const SizedBox(width: YaSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      thread.name,
                      style:
                          YaText.baseMedium.copyWith(color: colors.textPrimary),
                    ),
                    StatusBadge(
                      variant: thread.readOnly
                          ? StatusVariant.neutral
                          : StatusVariant.info,
                      label: thread.badge,
                      size: StatusBadgeSize.sm,
                    ),
                  ],
                ),
              ),
              Icon(LucideIcons.ellipsis, size: 18, color: colors.textMuted),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(YaSpacing.lg),
            children: <Widget>[
              for (final _Message message in thread.messages)
                Align(
                  alignment: message.fromMe
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 520),
                    margin: const EdgeInsets.only(bottom: YaSpacing.sm),
                    padding: const EdgeInsets.symmetric(
                      horizontal: YaSpacing.md,
                      vertical: YaSpacing.sm,
                    ),
                    decoration: BoxDecoration(
                      color:
                          message.fromMe ? colors.brandSubtle : colors.bgSubtle,
                      borderRadius: YaRadius.brMd,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          message.text,
                          style: YaText.sm.copyWith(color: colors.textPrimary),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${message.timestamp.hour.toString().padLeft(2, '0')}:${message.timestamp.minute.toString().padLeft(2, '0')}',
                          style: YaText.sans(size: 11, height: 14)
                              .copyWith(color: colors.textMuted),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
        if (!thread.readOnly)
          Container(
            padding: const EdgeInsets.all(YaSpacing.lg),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: colors.borderSubtle)),
            ),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: YaTextarea(
                    controller: controller,
                    placeholder: 'Escreve uma mensagem...',
                    minLines: 1,
                    maxLines: 4,
                    onChanged: onDraftChanged,
                  ),
                ),
                const SizedBox(width: YaSpacing.sm),
                YaButton.primary(
                  label: 'Enviar',
                  icon: LucideIcons.send,
                  onPressed: draft.trim().isEmpty ? null : onSend,
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _Thread {
  _Thread({
    required this.id,
    required this.name,
    required this.badge,
    required this.preview,
    required this.unread,
    required this.readOnly,
    required this.messages,
  });

  final String id;
  final String name;
  final String badge;
  String preview;
  int unread;
  final bool readOnly;
  final List<_Message> messages;
}

class _Message {
  const _Message({
    required this.text,
    required this.fromMe,
    required this.timestamp,
  });

  final String text;
  final bool fromMe;
  final DateTime timestamp;
}
