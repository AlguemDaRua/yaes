// Category cards are config-driven (/config/pricing/categories):
// o passageiro só vê as categorias que a operação activou. Categorias sem
// oferta real (0 motoristas online livres) aparecem indisponíveis e não são
// tocáveis.
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:limousineexecutive/passenger/models/cardata.dart';
import 'package:limousineexecutive/passenger/models/passenger_state.dart';
import 'package:limousineexecutive/services/pricing_service.dart';
import 'package:provider/provider.dart';

class CartTypeOptionsGrid extends StatefulWidget {
  const CartTypeOptionsGrid({super.key});

  @override
  State<CartTypeOptionsGrid> createState() => _CartTypeOptionsGridState();
}

class _CartTypeOptionsGridState extends State<CartTypeOptionsGrid> {
  final Future<List<CarCategory>> _categories =
      PricingService.fetchCategories();
  Future<Map<String, int>>? _availability;
  String? _lastAvailabilitySignature;

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<PassengerState>(context);
    // Actualiza também quando busy ou as categorias mudam, mesmo que o número
    // total de motoristas online continue igual.
    final availabilityEntries = appState.onlineDrivers.map((driver) {
      final uid = driver['uid'];
      final isBusy = driver['busy'];
      final categories = driver['categories'];
      return '$uid:$isBusy:$categories';
    }).toList()..sort();
    final availabilitySignature = availabilityEntries.join('|');
    if (_lastAvailabilitySignature != availabilitySignature) {
      _lastAvailabilitySignature = availabilitySignature;
      _availability = appState.availableVehicleCountsByCategory();
    }
    return FutureBuilder<List<CarCategory>>(
      future: _categories,
      builder: (context, categoriesSnapshot) {
        final categories = categoriesSnapshot.data ?? kDefaultCategories;
        return FutureBuilder<Map<String, int>>(
          future: _availability,
          builder: (context, availabilitySnapshot) {
            // Enquanto a contagem carrega, não risca nenhuma categoria —
            // evita um "sem oferta" a piscar antes da resposta chegar.
            final Map<String, int>? counts = availabilitySnapshot.data;
            return SizedBox(
              height: 148.sp,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 8.sp, vertical: 4.sp),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: List.generate(categories.length, (index) {
                    final category = categories[index];
                    final bool available =
                        counts == null || (counts[category.id] ?? 0) > 0;
                    final bool selected =
                        available && appState.selectedCarTypeindex == index;
                    final double? price = (available && appState.distanceKm > 0)
                        ? PricingService.computeLocal(
                            tripType: TripType.regular,
                            distanceKm: appState.distanceKm,
                            durationMinutes: appState.durationMin.toDouble(),
                            category: category.id,
                          ).totalAmount
                        : null;
                    final eta = available
                        ? appState.estimatedPickupMinutes(category.id)
                        : null;
                    return Expanded(
                      flex: selected ? 4 : 3,
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 3.sp),
                        child: _CategoryTile(
                          category: category,
                          selected: selected,
                          available: available,
                          priceMtn: price,
                          etaMinutes: eta,
                          hasOrigin: appState.originLocation != null,
                          onTap: !available
                              ? null
                              : () => appState.selectCategory(
                                  category.id,
                                  category.label,
                                  index,
                                ),
                        ),
                      ),
                    );
                  }),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({
    required this.category,
    required this.selected,
    required this.available,
    required this.priceMtn,
    required this.etaMinutes,
    required this.hasOrigin,
    required this.onTap,
  });

  final CarCategory category;
  final bool selected;
  final bool available;
  final double? priceMtn;
  final int? etaMinutes;
  final bool hasOrigin;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final img = CarData.categoryImages[category.id];
    return Semantics(
      button: true,
      selected: selected,
      enabled: onTap != null,
      label: '${category.label}${selected ? ', selecionada' : ''}',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18.r),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            padding: EdgeInsets.fromLTRB(8.sp, 8.sp, 8.sp, 9.sp),
            decoration: BoxDecoration(
              color: selected ? const Color(0xfff1e4d8) : Colors.transparent,
              borderRadius: BorderRadius.circular(18.r),
              border: selected
                  ? Border.all(color: const Color(0xffe5a400), width: 1.5)
                  : Border.all(color: Colors.transparent),
            ),
            child: selected ? _buildSelectedCard(img) : _buildCompactCard(img),
          ),
        ),
      ),
    );
  }

  Widget _buildSelectedCard(String? img) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Center(
            child: img != null
                ? Image.asset(img, fit: BoxFit.contain)
                : Icon(
                    CarData.categoryIcon(category.id),
                    size: 48.sp,
                    color: Colors.black87,
                  ),
          ),
        ),
        Text(
          _etaLabel,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: const Color(0xff5c554d),
            fontSize: 10.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
        Text(
          category.label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: Colors.black87,
            fontSize: 13.sp,
            fontWeight: FontWeight.w700,
          ),
        ),
        SizedBox(height: 2.sp),
        Text(
          _priceLabel,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: Colors.black,
            fontSize: 18.sp,
            fontWeight: FontWeight.w900,
            height: 1,
          ),
        ),
      ],
    );
  }

  Widget _buildCompactCard(String? img) {
    final unavailable = !available;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Expanded(
          child: Opacity(
            opacity: unavailable ? 0.42 : 1,
            child: Center(
              child: img != null
                  ? Image.asset(img, fit: BoxFit.contain)
                  : Icon(
                      CarData.categoryIcon(category.id),
                      size: 38.sp,
                      color: const Color(0xff73776f),
                    ),
            ),
          ),
        ),
        if (!unavailable)
          Text(
            _etaLabel,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: const Color(0xff68645f),
              fontSize: 9.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
        Text(
          category.label,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: unavailable
                ? const Color(0xff92938d)
                : const Color(0xff41473f),
            fontSize: 10.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
        if (!unavailable)
          Text(
            _priceLabel,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: const Color(0xff34302a),
              fontSize: 10.sp,
              fontWeight: FontWeight.w700,
            ),
          ),
        if (unavailable) ...[
          SizedBox(height: 3.sp),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 5.sp, vertical: 3.sp),
            decoration: BoxDecoration(
              color: const Color(0xffeeeae4),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.person_off_outlined,
                  size: 10.sp,
                  color: const Color(0xff76766f),
                ),
                SizedBox(width: 3.sp),
                Flexible(
                  child: Text(
                    'Indisponível',
                    maxLines: 1,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: const Color(0xff686a64),
                      fontSize: 8.5.sp,
                      height: 1.1,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  String get _etaLabel {
    if (!available) return 'Indisponível';
    if (!hasOrigin) return 'Defina origem';
    final minutes = etaMinutes;
    return minutes == null ? 'ETA —' : '$minutes min';
  }

  String get _priceLabel =>
      priceMtn == null ? '— MT' : '${priceMtn!.ceil()} MT';
}
