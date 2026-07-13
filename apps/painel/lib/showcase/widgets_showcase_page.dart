import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:reactive_forms/reactive_forms.dart';

import '../core/constants/status_mapping.dart';
import '../shared/widgets/charts/bar_chart.dart';
import '../shared/widgets/charts/chart_card.dart';
import '../shared/widgets/charts/donut_chart.dart';
import '../shared/widgets/charts/line_chart.dart';
import '../shared/widgets/charts/radial_gauge.dart';
import '../shared/widgets/charts/sparkline.dart';
import '../shared/widgets/dialogs/confirm_dialog.dart';
import '../shared/widgets/dialogs/form_dialog.dart';
import '../shared/widgets/feedback/empty_state.dart';
import '../shared/widgets/feedback/skeleton.dart';
import '../shared/widgets/feedback/status_badge.dart';
import '../shared/widgets/feedback/toast.dart';
import '../shared/widgets/feedback/tooltip.dart';
import '../shared/widgets/filters/filter_bar.dart';
import '../shared/widgets/forms/file_dropzone.dart';
import '../shared/widgets/forms/reactive_ya_input.dart';
import '../shared/widgets/forms/ya_avatar.dart';
import '../shared/widgets/forms/ya_button.dart';
import '../shared/widgets/forms/ya_field.dart';
import '../shared/widgets/forms/ya_input.dart';
import '../shared/widgets/forms/ya_select.dart';
import '../shared/widgets/forms/ya_tabs.dart';
import '../shared/widgets/forms/ya_textarea.dart';
import '../shared/widgets/kpi/kpi_card.dart';
import '../shared/widgets/shell/page_header.dart';
import '../shared/widgets/table/cells.dart';
import '../shared/widgets/table/data_table.dart';
import '../theme/tokens/colors.dart';
import '../theme/tokens/dimensions.dart';
import '../theme/tokens/typography.dart';

class WidgetsShowcasePage extends StatefulWidget {
  const WidgetsShowcasePage({super.key});

  @override
  State<WidgetsShowcasePage> createState() => _WidgetsShowcasePageState();
}

class _WidgetsShowcasePageState extends State<WidgetsShowcasePage> {
  final _searchController = TextEditingController();
  final _form = FormGroup({
    'name': FormControl<String>(
      value: 'Amina Mussa',
      validators: [Validators.required],
    ),
    'notes': FormControl<String>(value: 'Conta validada para showcase.'),
  });

  int _tab = 0;
  String _activeChip = 'active';
  String _role = 'admin';

  final _rows = const [
    _DriverRow(
      id: 'DRV-1042',
      name: 'Amina Mussa',
      email: 'amina@ya.co.mz',
      plate: 'AFQ-12-34',
      status: YaStatus.driverActiveOnline,
      revenue: '42 800',
      routeFrom: 'Baixa',
      routeTo: 'Matola',
      distance: '18,4 km',
      when: 'ha 12 min',
    ),
    _DriverRow(
      id: 'DRV-1043',
      name: 'Celso Nhantumbo',
      email: 'celso@ya.co.mz',
      plate: 'AGH-87-20',
      status: YaStatus.driverPending,
      revenue: '18 200',
      routeFrom: 'Museu',
      routeTo: 'Costa do Sol',
      distance: '11,2 km',
      when: 'ha 1 h',
    ),
  ];

  @override
  void dispose() {
    _searchController.dispose();
    _form.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = YaColors.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PageHeader(
          title: 'Showcase dos widgets YA',
          description: 'Smoke test visual para light e dark mode.',
          breadcrumb: const [
            BreadcrumbItem(label: 'Design system'),
            BreadcrumbItem(label: 'Widgets'),
          ],
          actions: [
            YaButton.secondary(
              label: 'Confirm dialog',
              icon: LucideIcons.triangleAlert,
              onPressed: _showConfirmDialog,
            ),
            YaButton.primary(
              label: 'Form dialog',
              icon: LucideIcons.plus,
              onPressed: _showFormDialog,
            ),
          ],
          tabs: YaTabs(
            activeIndex: _tab,
            onChanged: (index) => setState(() => _tab = index),
            items: const [
              YaTabItem(label: 'Overview', count: 27),
              YaTabItem(label: 'Forms', count: 9),
              YaTabItem(label: 'Charts', count: 6),
            ],
          ),
        ),
        const SizedBox(height: YaSpacing.xxl),
        _Section(
          title: 'Feedback',
          child: Wrap(
            spacing: YaSpacing.md,
            runSpacing: YaSpacing.md,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              StatusBadge.fromMapping(YaStatus.partnerActive),
              StatusBadge.fromMapping(YaStatus.driverPending),
              StatusBadge.fromMapping(YaStatus.tripCancelled),
              const Skeleton(width: 96, height: 22),
              Skeleton.circle(size: 32),
              YaTooltip(
                message: 'Tooltip com tema YA',
                child: YaButton.ghost(label: 'Tooltip', onPressed: () {}),
              ),
            ],
          ),
        ),
        const SizedBox(height: YaSpacing.xxl),
        _Section(
          title: 'Forms',
          child: Wrap(
            spacing: YaSpacing.lg,
            runSpacing: YaSpacing.lg,
            children: [
              SizedBox(
                width: 260,
                child: YaInput(
                  label: 'Nome',
                  placeholder: 'Pesquisar motorista',
                  icon: LucideIcons.search,
                  controller: _searchController,
                ),
              ),
              const SizedBox(
                width: 260,
                child: YaInput(
                  label: 'Email',
                  placeholder: 'email@ya.co.mz',
                  hint: 'Usado para notificacoes.',
                ),
              ),
              const SizedBox(
                width: 320,
                child: YaField(
                  label: 'Motivo',
                  hint: 'Este campo demonstra o wrapper YaField.',
                  child: YaTextarea(
                    placeholder: 'Escreve uma nota operacional...',
                    minLines: 3,
                    maxLines: 5,
                  ),
                ),
              ),
              SizedBox(
                width: 260,
                child: YaSelect<String>(
                  value: _role,
                  onChanged: (value) => setState(() => _role = value),
                  items: const [
                    YaSelectItem(value: 'admin', label: 'Admin'),
                    YaSelectItem(value: 'partner', label: 'Partner'),
                    YaSelectItem(value: 'support', label: 'Support'),
                  ],
                ),
              ),
              const SizedBox(
                width: 320,
                child: FileDropzone(
                  label: 'Carregar documento',
                  subtitle: 'PDF, JPG ou PNG ate 10 MB',
                  state: FileDropzoneState.uploading,
                  fileName: 'licenca-conducao.pdf',
                  progress: 0.68,
                ),
              ),
              Wrap(
                spacing: YaSpacing.sm,
                runSpacing: YaSpacing.sm,
                children: [
                  YaButton.primary(label: 'Primary', onPressed: () {}),
                  YaButton.secondary(label: 'Secondary', onPressed: () {}),
                  YaButton.ghost(label: 'Ghost', onPressed: () {}),
                  YaButton.destructive(label: 'Destructive', onPressed: () {}),
                  YaButton.link(label: 'Link', onPressed: () {}),
                  const YaButton.primary(label: 'Loading', loading: true),
                  const YaAvatar(initial: 'YA', size: 40),
                  YaAvatar.fromName('Amina Mussa', size: 40, border: true),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: YaSpacing.xxl),
        _Section(
          title: 'Reactive forms',
          child: ReactiveForm(
            formGroup: _form,
            child: Wrap(
              spacing: YaSpacing.lg,
              runSpacing: YaSpacing.lg,
              children: [
                SizedBox(
                  width: 280,
                  child: ReactiveYaInput<String>(
                    formControlName: 'name',
                    label: 'Nome reactive',
                    placeholder: 'Nome completo',
                    icon: LucideIcons.user,
                    validationMessages: {
                      ValidationMessage.required: (_) =>
                          'O nome e obrigatorio.',
                    },
                  ),
                ),
                SizedBox(
                  width: 360,
                  child: ReactiveYaTextarea<String>(
                    formControlName: 'notes',
                    placeholder: 'Notas internas',
                    minLines: 3,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: YaSpacing.xxl),
        _Section(
          title: 'Filtros e tabela',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              FilterBar(
                chips: const [
                  FilterChipSpec(
                    id: 'active',
                    label: 'Activos online',
                    count: 128,
                    variant: StatusVariant.success,
                  ),
                  FilterChipSpec(
                    id: 'pending',
                    label: 'Pendentes',
                    count: 12,
                    variant: StatusVariant.warning,
                  ),
                  FilterChipSpec(
                    id: 'risk',
                    label: 'Em risco',
                    count: 4,
                    variant: StatusVariant.danger,
                  ),
                ],
                activeChipId: _activeChip,
                onChipSelected: (id) => setState(() => _activeChip = id),
                searchController: _searchController,
              ),
              const SizedBox(height: YaSpacing.lg),
              YaDataTable<_DriverRow>(
                rows: _rows,
                keyExtractor: (row) => row.id,
                selectable: true,
                selectedKeys: const {'DRV-1042'},
                columns: [
                  YaColumn(
                    key: 'driver',
                    label: 'Motorista',
                    width: 220,
                    cellBuilder: (row) =>
                        PersonCell(name: row.name, subtitle: row.email),
                  ),
                  YaColumn(
                    key: 'id',
                    label: 'ID',
                    width: 100,
                    cellBuilder: (row) => IdCell(row.id),
                  ),
                  YaColumn(
                    key: 'plate',
                    label: 'Matricula',
                    width: 110,
                    cellBuilder: (row) => PlateCell(row.plate),
                  ),
                  YaColumn(
                    key: 'status',
                    label: 'Estado',
                    width: 220,
                    cellBuilder: (row) => StatusBadge.fromMapping(row.status),
                  ),
                  YaColumn(
                    key: 'route',
                    label: 'Rota',
                    cellBuilder: (row) =>
                        RouteCell(from: row.routeFrom, to: row.routeTo),
                  ),
                  YaColumn(
                    key: 'distance',
                    label: 'Distancia',
                    width: 110,
                    align: Alignment.centerRight,
                    cellBuilder: (row) => NumericCell(row.distance),
                  ),
                  YaColumn(
                    key: 'revenue',
                    label: 'Receita',
                    width: 130,
                    align: Alignment.centerRight,
                    cellBuilder: (row) => MoneyCell(amount: row.revenue),
                  ),
                  YaColumn(
                    key: 'when',
                    label: 'Quando',
                    width: 100,
                    cellBuilder: (row) => WhenCell(row.when),
                  ),
                ],
                footer: YaTablePagination(
                  currentPage: 1,
                  totalPages: 3,
                  summary: 'A mostrar 1-2 de 247',
                  onPageChange: (_) {},
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: YaSpacing.xxl),
        const _Section(
          title: 'KPI',
          child: KpiRow(
            children: [
              KpiCard(
                label: 'Corridas hoje',
                value: '2 847',
                icon: LucideIcons.car,
                trend: KpiTrend(
                  value: '+18,4%',
                  direction: TrendDirection.up,
                  semantic: TrendSemantic.positive,
                  label: 'vs ontem',
                ),
              ),
              KpiCard(
                label: 'Receita',
                value: '1 240 900',
                valueSuffix: 'MTn',
                variant: KpiCardVariant.highlighted,
                trend: KpiTrend(
                  value: '+9,1%',
                  direction: TrendDirection.up,
                  semantic: TrendSemantic.positive,
                  label: 'este mes',
                ),
              ),
              KpiCard(
                label: 'Cancelamentos',
                value: '3,2',
                valueSuffix: '%',
                trend: KpiTrend(
                  value: '-1,2%',
                  direction: TrendDirection.down,
                  semantic: TrendSemantic.positive,
                  label: 'melhorou',
                ),
              ),
              KpiCard(label: 'Sem dados', value: '0', empty: true),
              KpiCard(label: 'Loading', value: '0', loading: true),
            ],
          ),
        ),
        const SizedBox(height: YaSpacing.xxl),
        _Section(
          title: 'Charts',
          child: LayoutBuilder(
            builder: (context, constraints) {
              final narrow = constraints.maxWidth < 720;
              return Wrap(
                spacing: YaSpacing.lg,
                runSpacing: YaSpacing.lg,
                children: [
                  _ChartBox(
                    narrow: narrow,
                    child: ChartCard(
                      title: 'Line chart',
                      subtitle: 'Corridas por dia',
                      child: YaLineChart(
                        labels: const ['Seg', 'Ter', 'Qua', 'Qui', 'Sex'],
                        area: true,
                        series: [
                          YaLineSeries(
                            values: const [12, 18, 14, 24, 28],
                            color: colors.chartSeries[0],
                          ),
                          YaLineSeries(
                            values: const [9, 14, 13, 18, 20],
                            color: colors.chartSeries[1],
                            dashed: true,
                          ),
                        ],
                      ),
                    ),
                  ),
                  _ChartBox(
                    narrow: narrow,
                    child: const ChartCard(
                      title: 'Bar chart',
                      child: YaBarChart(
                        labels: ['Mpt', 'Mat', 'Bei', 'Nam'],
                        values: [42, 28, 18, 12],
                        secondary: [12, 8, 4, 3],
                      ),
                    ),
                  ),
                  _ChartBox(
                    narrow: narrow,
                    child: ChartCard(
                      title: 'Donut chart',
                      child: YaDonutChart(
                        centerValue: '68%',
                        centerLabel: 'online',
                        slices: [
                          YaDonutSlice(
                            label: 'Online',
                            value: 68,
                            color: colors.chartSeries[2],
                          ),
                          YaDonutSlice(
                            label: 'Offline',
                            value: 22,
                            color: colors.chartSeries[1],
                          ),
                          YaDonutSlice(
                            label: 'Pendente',
                            value: 10,
                            color: colors.chartSeries[4],
                          ),
                        ],
                      ),
                    ),
                  ),
                  _ChartBox(
                    narrow: narrow,
                    child: ChartCard(
                      title: 'Gauge e sparkline',
                      child: Row(
                        children: [
                          RadialGauge(
                            value: 74,
                            label: 'SLA',
                            color: colors.success,
                            size: 180,
                          ),
                          const SizedBox(width: YaSpacing.xl),
                          Expanded(
                            child: Sparkline(
                              data: const [4, 8, 6, 12, 10, 16, 18],
                              color: colors.brand,
                              fill: true,
                              width: 160,
                              height: 64,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        const SizedBox(height: YaSpacing.xxl),
        const _Section(
          title: 'Empty e toast',
          child: Wrap(
            spacing: YaSpacing.lg,
            runSpacing: YaSpacing.lg,
            children: [
              SizedBox(
                width: 420,
                child: EmptyState(
                  icon: LucideIcons.inbox,
                  title: 'Sem resultados',
                  description:
                      'Tenta um filtro diferente ou alarga o intervalo.',
                  ctaLabel: 'Limpar filtros',
                ),
              ),
              YaToast(
                title: 'Documento validado',
                description: 'A alteracao ja esta visivel no perfil.',
                variant: StatusVariant.success,
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showConfirmDialog() {
    showDialog<void>(
      context: context,
      builder: (context) => ConfirmDialog(
        title: 'Suspender motorista?',
        description: 'Esta acao bloqueia novas corridas ate revisao manual.',
        body: const YaTextarea(
          placeholder: 'Motivo da suspensao',
          minLines: 3,
          maxLines: 4,
        ),
        onConfirm: () => Navigator.of(context).pop(),
      ),
    );
  }

  void _showFormDialog() {
    showDialog<void>(
      context: context,
      builder: (context) => FormDialog(
        title: 'Novo parceiro',
        description: 'Formulario compacto com banner e footer YA.',
        errorBanner: 'Exemplo de mensagem de erro do servidor.',
        confirmLabel: 'Guardar',
        onConfirm: () => Navigator.of(context).pop(),
        children: const [
          YaInput(label: 'Nome', placeholder: 'Nome do parceiro'),
          YaInput(label: 'NUIT', placeholder: '400000000'),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = YaColors.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(title, style: YaText.lg.copyWith(color: colors.textPrimary)),
        const SizedBox(height: YaSpacing.md),
        child,
      ],
    );
  }
}

class _ChartBox extends StatelessWidget {
  const _ChartBox({required this.narrow, required this.child});

  final bool narrow;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SizedBox(width: narrow ? double.infinity : 520, child: child);
  }
}

class _DriverRow {
  const _DriverRow({
    required this.id,
    required this.name,
    required this.email,
    required this.plate,
    required this.status,
    required this.revenue,
    required this.routeFrom,
    required this.routeTo,
    required this.distance,
    required this.when,
  });

  final String id;
  final String name;
  final String email;
  final String plate;
  final StatusMapping status;
  final String revenue;
  final String routeFrom;
  final String routeTo;
  final String distance;
  final String when;
}
