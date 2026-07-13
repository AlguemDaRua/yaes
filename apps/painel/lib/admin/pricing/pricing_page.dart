import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/constants/status_mapping.dart';
import '../../data/providers.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../shared/widgets/feedback/async_view.dart';
import '../../shared/widgets/feedback/snack.dart';
import '../../shared/widgets/forms/ya_button.dart';
import '../../shared/widgets/forms/ya_input.dart';
import '../../shared/widgets/forms/ya_tabs.dart';
import '../../shared/widgets/shell/page_header.dart';
import '../../theme/tokens/colors.dart';
import '../../theme/tokens/dimensions.dart';
import '../../theme/tokens/typography.dart';

/// Tarifário editável, persistido em `/config/pricing`. As Cloud Functions
/// (`calculatePrice`) lêem este nó com fallback às constantes hardcoded, por
/// isso valores em falta nunca partem a cobrança.
class PricingPage extends ConsumerWidget {
  const PricingPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final configAsync = ref.watch(adminConfigProvider('pricing'));

    return AsyncView<Map<String, dynamic>>(
      value: configAsync,
      onRetry: () => ref.invalidate(adminConfigProvider('pricing')),
      data: (config) => _PricingForm(config: config),
    );
  }
}

const List<String> _tripTypes = ['regular', 'scheduled', 'airport', 'event'];

const Map<String, String> _tripTypeLabels = {
  'regular': 'Regular',
  'scheduled': 'Agendada',
  'airport': 'Aeroporto',
  'event': 'Evento (por hora)',
};

// Espelha functions/src/pricing.ts FARES — usado quando /config/pricing
// ainda não tem o valor.
const Map<String, Map<String, num>> _fareDefaults = {
  'regular': {
    'baseFare': 150,
    'perKm': 35,
    'perMinute': 5,
    'minimumFare': 250,
    'commission': 0.12,
  },
  'scheduled': {
    'baseFare': 165,
    'perKm': 35,
    'perMinute': 5,
    'minimumFare': 275,
    'commission': 0.10,
  },
  'airport': {
    'baseFare': 500,
    'perKm': 30,
    'perMinute': 0,
    'minimumFare': 500,
    'commission': 0.15,
  },
  'event': {
    'baseFare': 500,
    'perKm': 20,
    'perMinute': 0,
    'minimumFare': 2100,
    'commission': 0.10,
  },
};

const List<({String field, String label})> _fareFields = [
  (field: 'baseFare', label: 'Base (MTn)'),
  (field: 'perKm', label: 'Por km'),
  (field: 'perMinute', label: 'Por min'),
  (field: 'minimumFare', label: 'Mínimo'),
  (field: 'commission', label: 'Comissão (0-1)'),
];

// Categorias — espelham kDefaultCategories na app. A moto (txopela) é a
// categoria de entrada para mercados como Nampula; o que fica gravado em
// /config/pricing/categories é exactamente o que o passageiro vê na app.
const Map<String, Map<String, Object>> _categoryDefaults = {
  // multiplier deriva do preço real da gasolina (93,86 MT/L, jun/2026): ~15 MT
  // bandeirada + ~7,5 MT/km sobre a tarifa regular (150 base + 35/km) = 0,214x
  // — ver Downloads/YA-Plano-Fecho.md B2.3.
  'moto': {
    'label': 'Moto',
    'multiplier': 0.214,
    'seats': 1,
    'order': 0,
  },
  'txopela': {
    'label': 'Txopela',
    'multiplier': 0.7,
    'seats': 3,
    'order': 1,
  },
  'economico': {
    'label': 'Económico',
    'multiplier': 1.0,
    'seats': 5,
    'order': 2,
  },
  'sedan': {'label': 'Sedan', 'multiplier': 1.6, 'seats': 5, 'order': 2},
  'caravan': {'label': 'Caravan', 'multiplier': 1.5, 'seats': 9, 'order': 3},
  'suv': {'label': 'SUV', 'multiplier': 2.0, 'seats': 7, 'order': 4},
  'bus': {'label': 'Bus', 'multiplier': 2.3, 'seats': 25, 'order': 5},
  'classico': {'label': 'Clássico', 'multiplier': 2.3, 'seats': 5, 'order': 6},
  'limousine': {
    'label': 'Limousine',
    'multiplier': 3.8,
    'seats': 8,
    'order': 7,
  },
  'helicoptero': {
    'label': 'Helicóptero',
    'multiplier': 25.0,
    'seats': 5,
    'order': 8,
  },
};

class _PricingForm extends ConsumerStatefulWidget {
  const _PricingForm({required this.config});

  final Map<String, dynamic> config;

  @override
  ConsumerState<_PricingForm> createState() => _PricingFormState();
}

class _PricingFormState extends ConsumerState<_PricingForm> {
  int _tab = 0;
  bool _busy = false;

  // Controllers por tripType/campo e por categoria/campo.
  final Map<String, Map<String, TextEditingController>> _fareCtrl = {};
  final Map<String, Map<String, TextEditingController>> _catCtrl = {};

  static const _tabs = [
    YaTabItem(label: 'Tarifas por tipo'),
    YaTabItem(label: 'Categorias de carro'),
  ];

  @override
  void initState() {
    super.initState();
    final fares = _asMap(widget.config['fares']);
    for (final type in _tripTypes) {
      final stored = _asMap(fares[type]);
      _fareCtrl[type] = {
        for (final f in _fareFields)
          f.field: TextEditingController(
            text: _numText(stored[f.field] ?? _fareDefaults[type]![f.field]),
          ),
      };
    }
    final categories = _asMap(widget.config['categories']);
    final source = categories.isEmpty ? _categoryDefaults : categories;
    for (final entry in source.entries) {
      final stored = _asMap(entry.value);
      _catCtrl[entry.key] = {
        'label': TextEditingController(
          text: (stored['label'] ?? entry.key).toString(),
        ),
        'multiplier': TextEditingController(
          text: _numText(stored['multiplier'] ?? 1.0),
        ),
        'seats': TextEditingController(
          text: _numText(stored['seats'] ?? 4),
        ),
      };
    }
  }

  @override
  void dispose() {
    for (final group in _fareCtrl.values) {
      for (final c in group.values) {
        c.dispose();
      }
    }
    for (final group in _catCtrl.values) {
      for (final c in group.values) {
        c.dispose();
      }
    }
    super.dispose();
  }

  Map<String, dynamic> _asMap(Object? value) {
    if (value is! Map) return <String, dynamic>{};
    return Map<String, dynamic>.from(value);
  }

  String _numText(Object? value) {
    if (value is! num) return '';
    if (value == value.roundToDouble()) return value.toInt().toString();
    return value.toString();
  }

  double? _parse(String text) =>
      double.tryParse(text.trim().replaceAll(',', '.'));

  Future<void> _save() async {
    if (_busy) return;
    final fares = <String, Object?>{};
    for (final type in _tripTypes) {
      final fields = <String, Object?>{};
      for (final f in _fareFields) {
        final value = _parse(_fareCtrl[type]![f.field]!.text);
        if (value == null || value < 0) {
          yaSnack(
            context,
            'Valor inválido em ${_tripTypeLabels[type]} · ${f.label}.',
            variant: StatusVariant.danger,
          );
          return;
        }
        fields[f.field] = value;
      }
      final commission = fields['commission']! as double;
      if (commission > 1) {
        yaSnack(
          context,
          'A comissão é uma fração (ex.: 0.12 = 12%).',
          variant: StatusVariant.danger,
        );
        return;
      }
      fares[type] = fields;
    }

    final categories = <String, Object?>{};
    var order = 1;
    for (final entry in _catCtrl.entries) {
      final label = entry.value['label']!.text.trim();
      final multiplier = _parse(entry.value['multiplier']!.text);
      final seats = _parse(entry.value['seats']!.text);
      if (label.isEmpty || multiplier == null || multiplier <= 0) {
        yaSnack(
          context,
          'Categoria ${entry.key}: indica label e multiplicador > 0.',
          variant: StatusVariant.danger,
        );
        return;
      }
      categories[entry.key] = <String, Object?>{
        'label': label,
        'multiplier': multiplier,
        'seats': seats?.toInt() ?? 4,
        'order': order++,
      };
    }

    setState(() => _busy = true);
    try {
      await ref.read(adminDataRepositoryProvider).setConfig(
        'pricing',
        <String, Object?>{'fares': fares, 'categories': categories},
      );
      if (!mounted) return;
      ref.invalidate(adminConfigProvider('pricing'));
      yaSnack(context, 'Tarifário guardado');
    } catch (e) {
      if (!mounted) return;
      yaSnack(context, 'Erro: $e', variant: StatusVariant.danger);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PageHeader(
          title: S.of(context).adminNavPricing,
          description:
              'Tarifas por tipo de viagem e multiplicadores por categoria '
              'de carro — aplicados pelo servidor em todas as cobranças',
          actions: [
            YaButton.primary(
              label: _busy ? 'A guardar...' : 'Guardar alterações',
              icon: LucideIcons.save,
              onPressed: _busy ? null : _save,
            ),
          ],
          tabs: YaTabs(
            items: _tabs,
            activeIndex: _tab,
            onChanged: (index) => setState(() => _tab = index),
          ),
        ),
        const SizedBox(height: YaSpacing.xxl),
        switch (_tab) {
          0 => _buildFares(context),
          1 => _buildCategories(context),
          _ => const SizedBox.shrink(),
        },
      ],
    );
  }

  Widget _buildFares(BuildContext context) {
    final colors = YaColors.of(context);
    final isLight = Theme.of(context).brightness == Brightness.light;

    return Column(
      children: [
        for (final type in _tripTypes)
          Container(
            margin: const EdgeInsets.only(bottom: YaSpacing.md),
            padding: YaSpacing.cardMd,
            decoration: BoxDecoration(
              color: colors.bgSurface,
              borderRadius: YaRadius.brLg,
              border: Border.all(color: colors.borderSubtle),
              boxShadow: isLight ? YaShadows.sm : YaShadows.none,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _tripTypeLabels[type]!,
                  style: YaText.mdMedium.copyWith(color: colors.textPrimary),
                ),
                const SizedBox(height: YaSpacing.lg),
                Wrap(
                  spacing: YaSpacing.lg,
                  runSpacing: YaSpacing.md,
                  children: [
                    for (final f in _fareFields)
                      SizedBox(
                        width: 150,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              f.label,
                              style: YaText.sans(size: 11, height: 16)
                                  .copyWith(color: colors.textMuted),
                            ),
                            const SizedBox(height: 4),
                            YaInput(
                              controller: _fareCtrl[type]![f.field],
                              keyboardType: TextInputType.number,
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildCategories(BuildContext context) {
    final colors = YaColors.of(context);
    final isLight = Theme.of(context).brightness == Brightness.light;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'O preço final = tarifa do tipo de viagem × multiplicador da '
          'categoria escolhida na app.',
          style: YaText.sm.copyWith(color: colors.textSecondary),
        ),
        const SizedBox(height: YaSpacing.lg),
        for (final entry in _catCtrl.entries)
          Container(
            margin: const EdgeInsets.only(bottom: YaSpacing.md),
            padding: YaSpacing.cardMd,
            decoration: BoxDecoration(
              color: colors.bgSurface,
              borderRadius: YaRadius.brLg,
              border: Border.all(color: colors.borderSubtle),
              boxShadow: isLight ? YaShadows.sm : YaShadows.none,
            ),
            child: Wrap(
              spacing: YaSpacing.lg,
              runSpacing: YaSpacing.md,
              crossAxisAlignment: WrapCrossAlignment.end,
              children: [
                SizedBox(
                  width: 130,
                  child: Text(
                    entry.key,
                    style: YaText.monoSm.copyWith(color: colors.textMuted),
                  ),
                ),
                SizedBox(
                  width: 180,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Label',
                        style: YaText.sans(size: 11, height: 16)
                            .copyWith(color: colors.textMuted),
                      ),
                      const SizedBox(height: 4),
                      YaInput(controller: entry.value['label']),
                    ],
                  ),
                ),
                SizedBox(
                  width: 130,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Multiplicador',
                        style: YaText.sans(size: 11, height: 16)
                            .copyWith(color: colors.textMuted),
                      ),
                      const SizedBox(height: 4),
                      YaInput(
                        controller: entry.value['multiplier'],
                        keyboardType: TextInputType.number,
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  width: 100,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Lugares',
                        style: YaText.sans(size: 11, height: 16)
                            .copyWith(color: colors.textMuted),
                      ),
                      const SizedBox(height: 4),
                      YaInput(
                        controller: entry.value['seats'],
                        keyboardType: TextInputType.number,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
