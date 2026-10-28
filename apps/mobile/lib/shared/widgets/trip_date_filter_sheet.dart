import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../models/trip_date_filter.dart';

const Color _driverAccent = Color(0xFFE5A400);

Future<TripDateFilterResult?> showTripDateFilterSheet(
  BuildContext context, {
  TripDateFilter? currentFilter,
}) {
  return showModalBottomSheet<TripDateFilterResult>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (context) => TripDateFilterSheet(
      currentFilter: currentFilter,
    ),
  );
}

class TripDateFilterSheet extends StatefulWidget {
  const TripDateFilterSheet({
    super.key,
    this.currentFilter,
  });

  final TripDateFilter? currentFilter;

  @override
  State<TripDateFilterSheet> createState() => _TripDateFilterSheetState();
}

class _TripDateFilterSheetState extends State<TripDateFilterSheet> {
  TripDateFilterType? _selectedType;
  DateTimeRange? _customRange;

  @override
  void initState() {
    super.initState();
    _selectedType = widget.currentFilter?.type;
    if (widget.currentFilter?.type == TripDateFilterType.custom) {
      _customRange = DateTimeRange(
        start: widget.currentFilter!.startDate,
        end: widget.currentFilter!.endDate,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTextStyle(
      style: GoogleFonts.poppins(color: const Color(0xFF28251F)),
      child: Container(
        decoration: const BoxDecoration(
          color: Color(0xFFF7F8FA),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 38,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                const Text(
                  'Filtrar por período',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF28251F),
                  ),
                ),
                const SizedBox(height: 5),
                const Text(
                  'Escolhe a data de criação das viagens.',
                  style: TextStyle(
                    fontSize: 13,
                    color: Color(0xFF77736B),
                  ),
                ),
                const SizedBox(height: 17),
                _choiceTile(
                  type: TripDateFilterType.today,
                  title: 'Hoje',
                  subtitle: 'Viagens criadas hoje',
                  icon: Icons.today_rounded,
                ),
                const SizedBox(height: 9),
                _choiceTile(
                  type: TripDateFilterType.lastSevenDays,
                  title: 'Últimos 7 dias',
                  subtitle: 'Inclui hoje e os seis dias anteriores',
                  icon: Icons.date_range_rounded,
                ),
                const SizedBox(height: 9),
                _choiceTile(
                  type: TripDateFilterType.custom,
                  title: 'Período personalizado',
                  subtitle: _customRangeLabel,
                  icon: Icons.calendar_month_rounded,
                  onTap: _chooseCustomRange,
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _clear,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF514D46),
                          side: const BorderSide(color: Color(0xFFE0DED9)),
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Text('Limpar filtros'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _canApply ? _apply : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _driverAccent,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: const Color(0xFFE0DED9),
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Text('Aplicar filtros'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String get _customRangeLabel {
    final range = _customRange;
    if (range == null) return 'Seleciona as datas inicial e final';
    final format = DateFormat('dd/MM/yyyy');
    return '${format.format(range.start)} – ${format.format(range.end)}';
  }

  bool get _canApply =>
      _selectedType != null &&
      (_selectedType != TripDateFilterType.custom || _customRange != null);

  Widget _choiceTile({
    required TripDateFilterType type,
    required String title,
    required String subtitle,
    required IconData icon,
    VoidCallback? onTap,
  }) {
    final selected = _selectedType == type;
    return Material(
      color: selected ? _driverAccent.withValues(alpha: 0.09) : Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap ?? () => setState(() => _selectedType = type),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? _driverAccent : const Color(0xFFECEAE6),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: _driverAccent.withValues(alpha: 0.11),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: _driverAccent, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF28251F),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF77736B),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                selected
                    ? Icons.radio_button_checked_rounded
                    : Icons.radio_button_off_rounded,
                color: selected ? _driverAccent : const Color(0xFFB7B4AE),
                size: 21,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _chooseCustomRange() async {
    final now = DateTime.now();
    final pickedRange = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(now.year, now.month, now.day),
      initialDateRange: _customRange,
      helpText: 'Seleciona o período',
      saveText: 'Confirmar',
      cancelText: 'Cancelar',
      locale: const Locale('pt', 'BR'),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: Theme.of(context).colorScheme.copyWith(
            primary: _driverAccent,
            onPrimary: Colors.white,
          ),
          textTheme: GoogleFonts.poppinsTextTheme(Theme.of(context).textTheme),
        ),
        child: child!,
      ),
    );
    if (!mounted || pickedRange == null) return;
    setState(() {
      _selectedType = TripDateFilterType.custom;
      _customRange = pickedRange;
    });
  }

  void _clear() {
    Navigator.of(context).pop(const TripDateFilterResult(null));
  }

  void _apply() {
    final filter = switch (_selectedType!) {
      TripDateFilterType.today => TripDateFilter.today(),
      TripDateFilterType.lastSevenDays => TripDateFilter.lastSevenDays(),
      TripDateFilterType.custom => TripDateFilter.custom(
        startDate: _customRange!.start,
        endDate: _customRange!.end,
      ),
    };
    Navigator.of(context).pop(TripDateFilterResult(filter));
  }
}
