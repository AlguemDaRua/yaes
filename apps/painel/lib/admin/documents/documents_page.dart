import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/constants/status_mapping.dart';
import '../../data/providers.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../shared/utils/csv_export.dart';
import '../../shared/widgets/feedback/async_view.dart';
import '../../shared/widgets/feedback/snack.dart';
import '../../shared/widgets/feedback/status_badge.dart';
import '../../shared/widgets/filters/filter_bar.dart';
import '../../shared/widgets/forms/ya_button.dart';
import '../../shared/widgets/shell/page_header.dart';
import '../../shared/widgets/table/cells.dart';
import '../../shared/widgets/table/data_table.dart';
import '../../shared/widgets/table/row_context_menu.dart';
import '../../theme/tokens/dimensions.dart';
import '../data/types.dart';

class DocumentsPage extends ConsumerStatefulWidget {
  const DocumentsPage({super.key});

  @override
  ConsumerState<DocumentsPage> createState() => _DocumentsPageState();
}

class _DocumentsPageState extends ConsumerState<DocumentsPage> {
  String _activeChip = 'all';

  List<_AdminDocument> _rowsFrom(List<AdminDocument> documents) {
    return documents.map(_AdminDocument.fromAdmin).toList();
  }

  Future<void> _review(
    _AdminDocument doc,
    String status,
    String okMessage,
  ) async {
    try {
      await ref.read(cloudFunctionsServiceProvider).reviewDocument(
            ownerType: doc.rawOwnerType,
            ownerId: doc.rawOwnerId,
            docId: doc.docId,
            status: status,
          );
      if (!mounted) return;
      ref.invalidate(adminDocumentsProvider);
      yaSnack(context, okMessage);
    } catch (e) {
      if (!mounted) return;
      yaSnack(context, 'Erro: $e', variant: StatusVariant.danger);
    }
  }

  List<FilterChipSpec> _chipsFor(List<_AdminDocument> rows) {
    int count(String status) =>
        rows.where((row) => row.status == status).length;
    return [
      FilterChipSpec(id: 'all', label: 'Todos', count: rows.length),
      FilterChipSpec(
        id: 'ok',
        label: 'OK',
        count: count('ok'),
        variant: StatusVariant.success,
      ),
      FilterChipSpec(
        id: 'expiring_soon',
        label: 'A expirar',
        count: count('expiring_soon'),
        variant: StatusVariant.warning,
      ),
      FilterChipSpec(
        id: 'expired',
        label: 'Expirados',
        count: count('expired'),
        variant: StatusVariant.danger,
      ),
      FilterChipSpec(
        id: 'missing',
        label: 'Em falta',
        count: count('missing'),
        variant: StatusVariant.neutral,
      ),
    ];
  }

  List<_AdminDocument> _filteredRows(List<_AdminDocument> rows) {
    if (_activeChip == 'all') return rows;
    return rows.where((row) => row.status == _activeChip).toList();
  }

  void _export(List<_AdminDocument> rows) {
    if (rows.isEmpty) {
      yaSnack(context, 'Nada para exportar', variant: StatusVariant.warning);
      return;
    }
    final df = DateFormat('yyyy-MM-dd');
    final stamp = DateFormat('yyyyMMdd-HHmm').format(DateTime.now());
    downloadCsv('documentos-$stamp.csv', <List<Object?>>[
      <Object?>['dono', 'tipo_dono', 'documento', 'estado', 'expira_em'],
      for (final d in rows)
        <Object?>[
          d.owner,
          d.rawOwnerType,
          d.document,
          d.status,
          d.expiresAt == null ? '' : df.format(d.expiresAt!),
        ],
    ]);
    yaSnack(context, 'CSV exportado');
  }

  @override
  Widget build(BuildContext context) {
    final documentsAsync = ref.watch(adminDocumentsProvider);

    return AsyncView<List<AdminDocument>>(
      value: documentsAsync,
      onRetry: () => ref.invalidate(adminDocumentsProvider),
      data: (documents) {
        final rows = _rowsFrom(documents);
        final filtered = _filteredRows(rows);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PageHeader(
              title: S.of(context).adminNavDocuments,
              description:
                  'Validade e pendências documentais de partners, drivers e veículos',
              actions: [
                YaButton.secondary(
                  label: 'Exportar CSV',
                  icon: LucideIcons.download,
                  onPressed: () => _export(filtered),
                ),
              ],
            ),
            const SizedBox(height: YaSpacing.xxl),
            FilterBar(
              chips: _chipsFor(rows),
              activeChipId: _activeChip,
              onChipSelected: (id) => setState(() => _activeChip = id),
              searchPlaceholder: 'Pesquisar por dono, documento ou partner...',
            ),
            const SizedBox(height: YaSpacing.lg),
            YaDataTable<_AdminDocument>(
              columns: [
                YaColumn(
                  key: 'owner',
                  label: 'Owner',
                  width: 240,
                  cellBuilder: (row) => PersonCell(
                    name: row.owner,
                    subtitle: row.ownerMeta,
                  ),
                ),
                YaColumn(
                  key: 'type',
                  label: 'Tipo',
                  width: 110,
                  cellBuilder: (row) => TextCell(row.type),
                ),
                YaColumn(
                  key: 'document',
                  label: 'Documento',
                  width: 220,
                  cellBuilder: (row) => TextCell(row.document),
                ),
                YaColumn(
                  key: 'status',
                  label: 'Status',
                  width: 130,
                  cellBuilder: (row) => StatusBadge.fromMapping(
                    YaStatus.fromDocStatus(row.status),
                  ),
                ),
                YaColumn(
                  key: 'expires',
                  label: 'Expira em',
                  width: 170,
                  cellBuilder: (row) => DateCell(row.expiresAt),
                ),
                YaColumn(
                  key: 'partner',
                  label: 'Partner',
                  width: 190,
                  cellBuilder: (row) => TextCell(row.partner),
                ),
                YaColumn(
                  key: 'actions',
                  label: 'Acções',
                  width: 90,
                  cellBuilder: (row) => RowContextMenu(
                    items: [
                      YaMenuItem(
                        label: 'Aprovar',
                        icon: LucideIcons.check,
                        onTap: () =>
                            _review(row, 'approved', 'Documento aprovado'),
                      ),
                      YaMenuItem(
                        label: 'Rejeitar',
                        icon: LucideIcons.x,
                        destructive: true,
                        onTap: () =>
                            _review(row, 'rejected', 'Documento rejeitado'),
                      ),
                    ],
                  ),
                ),
              ],
              rows: filtered,
              keyExtractor: (row) => '${row.owner}-${row.document}',
              emptyIcon: LucideIcons.fileText,
              emptyTitle: 'Sem documentos',
              emptyDescription:
                  'Ajusta os filtros para veres outros documentos.',
              footer: YaTablePagination(
                currentPage: 1,
                totalPages: 1,
                onPageChange: (_) {},
                summary: 'A mostrar ${filtered.length} de ${rows.length}',
              ),
            ),
          ],
        );
      },
    );
  }
}

class _AdminDocument {
  const _AdminDocument({
    required this.docId,
    required this.rawOwnerType,
    required this.rawOwnerId,
    required this.owner,
    required this.ownerMeta,
    required this.type,
    required this.document,
    required this.status,
    required this.expiresAt,
    required this.partner,
  });

  final String docId;
  final String rawOwnerType;
  final String rawOwnerId;
  final String owner;
  final String ownerMeta;
  final String type;
  final String document;
  final String status;
  final DateTime? expiresAt;
  final String partner;

  factory _AdminDocument.fromAdmin(AdminDocument document) {
    return _AdminDocument(
      docId: document.id,
      rawOwnerType: document.ownerType,
      rawOwnerId: document.ownerId,
      owner: document.ownerId,
      ownerMeta: '${document.ownerType} · ${document.ownerId}',
      type: document.ownerType,
      document: document.type,
      status: document.status,
      expiresAt: document.expiresAt,
      partner: document.ownerType == 'partner' ? document.ownerId : '-',
    );
  }
}
