import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/constants/status_mapping.dart';
import '../../data/providers.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../shared/widgets/dialogs/form_dialog.dart';
import '../../shared/widgets/feedback/async_view.dart';
import '../../shared/widgets/feedback/snack.dart';
import '../../shared/widgets/feedback/status_badge.dart';
import '../../shared/widgets/filters/filter_bar.dart';
import '../../shared/widgets/forms/ya_button.dart';
import '../../shared/widgets/forms/ya_field.dart';
import '../../shared/widgets/forms/ya_input.dart';
import '../../shared/widgets/forms/ya_select.dart';
import '../../shared/widgets/shell/page_header.dart';
import '../../shared/widgets/table/cells.dart';
import '../../shared/widgets/table/data_table.dart';
import '../../shared/widgets/table/row_context_menu.dart';
import '../../theme/tokens/dimensions.dart';
import '../data/types.dart';

/// Categorias (fallback) — espelham tarifário/app.
const Map<String, String> kCategoryLabels = {
  'moto': 'Moto',
  'txopela': 'Txopela',
  'economico': 'Económico',
  'confort': 'Confort',
  'sedan': 'Sedan',
  'caravan': 'Caravan',
  'suv': 'SUV',
  'bus': 'Bus',
  'classico': 'Clássico',
  'limousine': 'Limousine',
  'helicoptero': 'Helicóptero',
};

const Map<String, String> _serviceCategoryLabels = {
  'economico': 'Económico',
  'confort': 'Confort',
  'txopela': 'Txopela',
  'moto': 'Moto',
};

class VehiclesPage extends ConsumerStatefulWidget {
  const VehiclesPage({super.key});

  @override
  ConsumerState<VehiclesPage> createState() => _VehiclesPageState();
}

class _VehiclesPageState extends ConsumerState<VehiclesPage> {
  String _activeChip = 'all';

  List<_Vehicle> _rowsFrom(List<AdminVehicle> vehicles) {
    return vehicles.map(_Vehicle.fromAdmin).toList();
  }

  void _copyPlate(String plate) {
    Clipboard.setData(ClipboardData(text: plate));
    yaSnack(context, 'Matrícula copiada');
  }

  void _openCreate() {
    showDialog<void>(
      context: context,
      builder: (BuildContext _) => const _AddVehicleDialog(),
    );
  }

  Future<void> _setStatus(_Vehicle row, String status) async {
    try {
      await ref.read(adminDataRepositoryProvider).updateVehicle(
        row.partnerId,
        row.id,
        <String, Object?>{'status': status},
      );
      if (!mounted) return;
      ref.invalidate(adminVehiclesProvider);
      yaSnack(
        context,
        status == 'maintenance'
            ? 'Veículo em manutenção'
            : 'Veículo disponível',
      );
    } catch (e) {
      if (!mounted) return;
      yaSnack(context, 'Erro: $e', variant: StatusVariant.danger);
    }
  }

  List<FilterChipSpec> _chipsFor(List<_Vehicle> rows) {
    int count(String status) =>
        rows.where((row) => row.status == status).length;
    return [
      FilterChipSpec(id: 'all', label: 'Todos', count: rows.length),
      FilterChipSpec(
        id: 'available',
        label: 'Disponíveis',
        count: count('available'),
        variant: StatusVariant.success,
      ),
      FilterChipSpec(
        id: 'busy',
        label: 'Em corrida',
        count: count('busy'),
        variant: StatusVariant.warning,
      ),
      FilterChipSpec(
        id: 'maintenance',
        label: 'Em manutenção',
        count: count('maintenance'),
        variant: StatusVariant.neutral,
      ),
    ];
  }

  List<_Vehicle> _filteredRows(List<_Vehicle> rows) {
    if (_activeChip == 'all') return rows;
    return rows.where((row) => row.status == _activeChip).toList();
  }

  @override
  Widget build(BuildContext context) {
    final vehiclesAsync = ref.watch(adminVehiclesProvider);

    return AsyncView<List<AdminVehicle>>(
      value: vehiclesAsync,
      onRetry: () => ref.invalidate(adminVehiclesProvider),
      data: (vehicles) {
        final rows = _rowsFrom(vehicles);
        final filtered = _filteredRows(rows);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PageHeader(
              title: S.of(context).adminVehiclesTitle,
              description: 'Frota registada por categoria e estado operacional',
              actions: [
                YaButton.primary(
                  label: 'Adicionar veículo',
                  icon: LucideIcons.plus,
                  onPressed: _openCreate,
                ),
              ],
            ),
            const SizedBox(height: YaSpacing.xxl),
            FilterBar(
              chips: _chipsFor(rows),
              activeChipId: _activeChip,
              onChipSelected: (id) => setState(() => _activeChip = id),
              searchPlaceholder:
                  'Pesquisar por matrícula, modelo ou partner...',
            ),
            const SizedBox(height: YaSpacing.lg),
            YaDataTable<_Vehicle>(
              columns: [
                YaColumn(
                  key: 'plate',
                  label: 'Matrícula',
                  width: 130,
                  cellBuilder: (row) => PlateCell(row.plate),
                ),
                YaColumn(
                  key: 'model',
                  label: 'Modelo',
                  width: 200,
                  cellBuilder: (row) => PersonCell(
                    name: row.model,
                    subtitle: row.year.toString(),
                  ),
                ),
                YaColumn(
                  key: 'category',
                  label: 'Categoria',
                  width: 190,
                  cellBuilder: (row) => TextCell(row.categoryLabels),
                ),
                YaColumn(
                  key: 'partner',
                  label: 'Partner',
                  width: 160,
                  cellBuilder: (row) => TextCell(row.partner, muted: true),
                ),
                YaColumn(
                  key: 'driver',
                  label: 'Driver actual',
                  width: 160,
                  cellBuilder: (row) => TextCell(
                    row.currentDriver ?? '-',
                    muted: row.currentDriver == null,
                  ),
                ),
                YaColumn(
                  key: 'status',
                  label: 'Estado',
                  width: 230,
                  cellBuilder: (row) => StatusBadge.fromMapping(
                    YaStatus.fromVehicleStatus(row.status),
                  ),
                ),
                YaColumn(
                  key: 'more',
                  label: '',
                  width: 48,
                  cellBuilder: (row) => RowContextMenu(
                    items: [
                      YaMenuItem(
                        label: 'Ver detalhe',
                        icon: LucideIcons.eye,
                        onTap: () => context.go('/admin/cars/${row.plate}'),
                      ),
                      const YaMenuDivider(),
                      YaMenuItem(
                        label: 'Editar categorias',
                        icon: LucideIcons.pencil,
                        onTap: () => showDialog<void>(
                          context: context,
                          builder: (_) => _EditVehicleCategoriesDialog(
                            vehicle: row,
                          ),
                        ),
                      ),
                      const YaMenuDivider(),
                      YaMenuItem(
                        label: 'Copiar matrícula',
                        icon: LucideIcons.copy,
                        onTap: () => _copyPlate(row.plate),
                      ),
                      const YaMenuDivider(),
                      if (row.status != 'maintenance')
                        YaMenuItem(
                          label: 'Marcar manutenção',
                          icon: LucideIcons.wrench,
                          destructive: true,
                          onTap: () => _setStatus(row, 'maintenance'),
                        )
                      else
                        YaMenuItem(
                          label: 'Concluir manutenção',
                          icon: LucideIcons.check,
                          onTap: () => _setStatus(row, 'available'),
                        ),
                    ],
                  ),
                ),
              ],
              rows: filtered,
              keyExtractor: (row) => row.plate,
              onRowTap: (row) => context.go('/admin/cars/${row.plate}'),
              emptyIcon: LucideIcons.car,
              emptyTitle: 'Sem veículos',
              emptyDescription: 'Ajusta os filtros ou adiciona um veículo.',
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

class _EditVehicleCategoriesDialog extends ConsumerStatefulWidget {
  const _EditVehicleCategoriesDialog({required this.vehicle});

  final _Vehicle vehicle;

  @override
  ConsumerState<_EditVehicleCategoriesDialog> createState() =>
      _EditVehicleCategoriesDialogState();
}

class _EditVehicleCategoriesDialogState
    extends ConsumerState<_EditVehicleCategoriesDialog> {
  late final Set<String> _categories = widget.vehicle.categories.isNotEmpty
      ? widget.vehicle.categories.toSet()
      : <String>{widget.vehicle.category ?? 'economico'};
  bool _busy = false;

  Future<void> _save() async {
    if (_busy) return;
    if (_categories.isEmpty) {
      yaSnack(
        context,
        'Selecciona pelo menos uma categoria.',
        variant: StatusVariant.danger,
      );
      return;
    }
    setState(() => _busy = true);
    try {
      final category = _categories.first;
      await ref.read(adminDataRepositoryProvider).updateVehicle(
        widget.vehicle.partnerId,
        widget.vehicle.id,
        <String, Object?>{
          'category': category,
          'type': kCategoryLabels[category] ?? category,
          'categories': <String, bool>{
            for (final value in _categories) value: true,
          },
        },
      );
      if (!mounted) return;
      ref.invalidate(adminVehiclesProvider);
      Navigator.of(context).pop();
      yaSnack(context, 'Categorias do veículo atualizadas');
    } catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      yaSnack(context, 'Erro: $e', variant: StatusVariant.danger);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FormDialog(
      title: 'Categorias do veículo',
      description:
          'O motorista poderá receber pedidos de qualquer categoria seleccionada.',
      confirmLabel: 'Guardar',
      submitting: _busy,
      onCancel: () => Navigator.of(context).pop(),
      onConfirm: _save,
      children: [
        YaField(
          label: 'Categorias disponíveis',
          child: Column(
            children: [
              for (final category in _serviceCategoryLabels.entries)
                CheckboxListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: Text(category.value),
                  value: _categories.contains(category.key),
                  onChanged: (selected) => setState(() {
                    if (selected == true) {
                      _categories.add(category.key);
                    } else {
                      _categories.remove(category.key);
                    }
                  }),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Vehicle {
  const _Vehicle(
    this.id,
    this.partnerId,
    this.plate,
    this.model,
    this.year,
    this.type,
    this.category,
    this.categories,
    this.partner,
    this.currentDriver,
    this.status,
  );

  final String id;
  final String partnerId;
  final String plate;
  final String model;
  final int year;
  final String type;
  final String? category;
  final List<String> categories;
  final String partner;
  final String? currentDriver;
  final String status;

  String get categoryLabels {
    final values = categories.isEmpty && category != null
        ? <String>[category!]
        : categories;
    if (values.isEmpty) return '—';
    return values
        .map((category) => kCategoryLabels[category] ?? category)
        .join(', ');
  }

  factory _Vehicle.fromAdmin(AdminVehicle vehicle) {
    return _Vehicle(
      vehicle.id,
      vehicle.partnerId,
      vehicle.plate.isEmpty ? vehicle.id : vehicle.plate,
      vehicle.model,
      vehicle.year ?? 0,
      vehicle.type,
      vehicle.category,
      vehicle.categories,
      vehicle.partnerId,
      vehicle.driverId,
      vehicle.status,
    );
  }
}

class _AddVehicleDialog extends ConsumerStatefulWidget {
  const _AddVehicleDialog();

  @override
  ConsumerState<_AddVehicleDialog> createState() => _AddVehicleDialogState();
}

class _AddVehicleDialogState extends ConsumerState<_AddVehicleDialog> {
  final TextEditingController _model = TextEditingController();
  final TextEditingController _plate = TextEditingController();
  final TextEditingController _seats = TextEditingController(text: '4');
  final TextEditingController _color = TextEditingController();
  final TextEditingController _photoUrl = TextEditingController();
  String? _partnerId;
  final Set<String> _categories = <String>{'economico'};
  bool _busy = false;
  Uint8List? _photoBytes;
  String? _photoFileName;

  @override
  void dispose() {
    _model.dispose();
    _plate.dispose();
    _seats.dispose();
    _color.dispose();
    _photoUrl.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    final FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: <String>['jpg', 'jpeg', 'png'],
      withData: true,
    );
    final PlatformFile? file = result?.files.firstOrNull;
    if (file == null || file.bytes == null) return;
    if (file.size > 5 * 1024 * 1024) {
      if (mounted) {
        yaSnack(
          context,
          'Imagem demasiado grande (máx. 5MB).',
          variant: StatusVariant.danger,
        );
      }
      return;
    }
    setState(() {
      _photoBytes = file.bytes;
      _photoFileName = file.name;
    });
  }

  Future<void> _submit() async {
    if (_busy) return;
    final String model = _model.text.trim();
    final String plate = _plate.text.trim();
    final String? partnerId = _partnerId;
    if (partnerId == null ||
        model.isEmpty ||
        plate.isEmpty ||
        _categories.isEmpty) {
      yaSnack(
        context,
        'Partner, modelo, matrícula e pelo menos uma categoria são obrigatórios.',
        variant: StatusVariant.danger,
      );
      return;
    }
    setState(() => _busy = true);
    try {
      // Foto carregada tem prioridade sobre um URL colado manualmente.
      String? photoUrl =
          _photoUrl.text.trim().isNotEmpty ? _photoUrl.text.trim() : null;
      final Uint8List? bytes = _photoBytes;
      final String? fileName = _photoFileName;
      if (bytes != null && fileName != null) {
        photoUrl = await ref.read(storageServiceProvider).uploadImage(
              bytes: bytes,
              pathPrefix: 'documents/vehicle/$partnerId',
              filename: fileName,
            );
      }
      await ref.read(adminDataRepositoryProvider).createVehicle(
        partnerId,
        <String, Object?>{
          'model': model,
          'plate': plate,
          'type': kCategoryLabels[_categories.first] ?? _categories.first,
          // Keep `category` for older app builds and use a map for multi-match.
          'category': _categories.first,
          'categories': <String, bool>{
            for (final category in _categories) category: true,
          },
          'seats': int.tryParse(_seats.text.trim()) ?? 4,
          'status': 'available',
          if (_color.text.trim().isNotEmpty) 'color': _color.text.trim(),
          if (photoUrl != null) 'photoUrl': photoUrl,
        },
      );
      if (!mounted) return;
      ref.invalidate(adminVehiclesProvider);
      Navigator.of(context).pop();
      yaSnack(context, 'Veículo adicionado');
    } catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      yaSnack(context, 'Erro: $e', variant: StatusVariant.danger);
    }
  }

  @override
  Widget build(BuildContext context) {
    final partners = ref.watch(adminPartnersProvider).asData?.value ??
        const <AdminPartner>[];
    final config = ref.watch(adminConfigProvider('pricing')).asData?.value ??
        const <String, dynamic>{};
    final rawCats = config['categories'];
    final categories = <MapEntry<String, String>>[
      for (final entry in _serviceCategoryLabels.entries)
        MapEntry(
          entry.key,
          (rawCats is Map && rawCats[entry.key] is Map
                      ? (rawCats[entry.key] as Map)['label']
                      : null)
                  ?.toString() ??
              entry.value,
        ),
    ];

    return FormDialog(
      title: 'Adicionar veículo',
      description: 'Escolhe todas as categorias em que este veículo pode '
          'receber pedidos. O passageiro escolhe uma categoria e o sistema '
          'procura o motorista compatível mais próximo.',
      confirmLabel: 'Adicionar',
      submitting: _busy,
      onCancel: () => Navigator.of(context).pop(),
      onConfirm: _submit,
      children: [
        YaField(
          label: 'Partner',
          child: YaSelect<String>(
            width: 360,
            placeholder: 'Escolher partner',
            value: _partnerId,
            items: [
              for (final p in partners)
                YaSelectItem<String>(value: p.id, label: p.name),
            ],
            onChanged: (v) => setState(() => _partnerId = v),
          ),
        ),
        YaField(
          label: 'Categorias disponíveis',
          child: Column(
            children: [
              for (final category in categories)
                CheckboxListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: Text(category.value),
                  value: _categories.contains(category.key),
                  onChanged: (selected) => setState(() {
                    if (selected == true) {
                      _categories.add(category.key);
                    } else {
                      _categories.remove(category.key);
                    }
                  }),
                ),
            ],
          ),
        ),
        YaField(
          label: 'Modelo',
          child: YaInput(controller: _model, placeholder: 'Toyota Corolla'),
        ),
        YaField(
          label: 'Matrícula',
          child: YaInput(controller: _plate, placeholder: 'ABG-12-34'),
        ),
        YaField(
          label: 'Lugares',
          child: YaInput(
            controller: _seats,
            keyboardType: TextInputType.number,
          ),
        ),
        YaField(
          label: 'Cor (opcional)',
          child: YaInput(controller: _color, placeholder: 'Cinzento'),
        ),
        YaField(
          label: 'Foto do veículo (opcional)',
          child: Row(
            children: [
              Expanded(
                child: YaButton.secondary(
                  label: _photoFileName ?? 'Escolher foto',
                  icon: LucideIcons.upload,
                  onPressed: _pickPhoto,
                ),
              ),
              if (_photoFileName != null)
                IconButton(
                  tooltip: 'Remover',
                  icon: const Icon(LucideIcons.x, size: 16),
                  onPressed: () => setState(() {
                    _photoBytes = null;
                    _photoFileName = null;
                  }),
                ),
            ],
          ),
        ),
        YaField(
          label: 'Ou foto URL (opcional)',
          child: YaInput(
            controller: _photoUrl,
            placeholder: 'https://.../carro.png',
          ),
        ),
      ],
    );
  }
}
