// Tradução fiel de _design/showcases/data-table.jsx (componente FilterBar).
// Spec: _design/components.md §7.

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/constants/status_mapping.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../theme/tokens/dimensions.dart';
import '../forms/ya_button.dart';
import '../forms/ya_input.dart';
import 'filter_chip.dart';

/// Spec de um chip de filtro.
@immutable
class FilterChipSpec {
  const FilterChipSpec({
    required this.id,
    required this.label,
    this.count,
    this.variant = StatusVariant.brand,
  });
  final String id;
  final String label;
  final int? count;

  /// Cor semântica quando active.
  final StatusVariant variant;
}

/// Barra de filtros: search + botão "Filtros" + chips horizontais.
///
/// Search tem ícone à esquerda e ocupa até 320px (resto fica vazio para
/// alinhar com layout das tabelas em desktop).
class FilterBar extends StatelessWidget {
  const FilterBar({
    required this.chips,
    required this.activeChipId,
    required this.onChipSelected,
    this.searchController,
    this.searchPlaceholder,
    this.onSearchChanged,
    this.onAdvancedFiltersTap,
    super.key,
  });

  final List<FilterChipSpec> chips;
  final String? activeChipId;
  final ValueChanged<String> onChipSelected;
  final TextEditingController? searchController;
  final String? searchPlaceholder;
  final ValueChanged<String>? onSearchChanged;
  final VoidCallback? onAdvancedFiltersTap;

  @override
  Widget build(BuildContext context) {
    final strings = S.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final compact =
                constraints.maxWidth.isFinite && constraints.maxWidth < 520;
            final search = YaInput(
              controller: searchController,
              placeholder: searchPlaceholder ?? '${strings.commonSearch}...',
              icon: LucideIcons.search,
              onChanged: onSearchChanged,
            );
            final filterButton = YaButton.secondary(
              label: strings.commonFilter,
              size: YaButtonSize.sm,
              onPressed: onAdvancedFiltersTap,
            );

            if (compact) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(width: double.infinity, child: search),
                  const SizedBox(height: YaSpacing.sm),
                  filterButton,
                ],
              );
            }

            return Row(
              children: [
                SizedBox(width: 320, child: search),
                const SizedBox(width: YaSpacing.md),
                filterButton,
              ],
            );
          },
        ),
        const SizedBox(height: YaSpacing.md),
        Wrap(
          spacing: YaSpacing.sm,
          runSpacing: YaSpacing.sm,
          children: [
            for (final chip in chips)
              YaFilterChip(
                label: chip.label,
                count: chip.count,
                variant: chip.variant,
                active: chip.id == activeChipId,
                onTap: () => onChipSelected(chip.id),
              ),
          ],
        ),
      ],
    );
  }
}
