// Grid list of car type options — config-driven (/config/pricing/categories):
// o passageiro só vê as categorias que a operação activou. Categorias sem
// oferta real (0 motoristas online livres) aparecem visualmente apagadas e
// não são tocáveis — à semelhança do Uber/Bolt, que mostra a oferta (e o
// preço estimado) antes de deixar escolher, em vez de um "sem veículos" só
// depois de escolher.
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
  int _lastOnlineDriversCount = -1;

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<PassengerState>(context);
    // Recalcula sempre que o número de motoristas online muda — o primeiro
    // build normalmente acontece antes de o stream de /drivers responder, por
    // isso não dá para computar isto uma única vez em initState.
    if (appState.onlineDrivers.length != _lastOnlineDriversCount) {
      _lastOnlineDriversCount = appState.onlineDrivers.length;
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
              child: GridView.count(
                crossAxisCount: 4,
                childAspectRatio: 0.85,
                padding: EdgeInsets.all(12.sp),
                crossAxisSpacing: 10.sp,
                mainAxisSpacing: 10.sp,
                shrinkWrap: true,
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
                  return _CategoryTile(
                    category: category,
                    selected: selected,
                    available: available,
                    priceMtn: price,
                    onTap: !available
                        ? null
                        : () => appState.selectCategory(
                              category.id,
                              category.label,
                              index,
                            ),
                  );
                }),
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
    required this.onTap,
  });

  final CarCategory category;
  final bool selected;
  final bool available;
  final double? priceMtn;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final img = CarData.categoryImages[category.id];
    return GestureDetector(
      onTap: onTap,
      child: AnimatedScale(
        scale: selected ? 1.05 : 1.0,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        child: Opacity(
          opacity: available ? 1 : 0.45,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              color: selected
                  ? const Color(0xffe5a400)
                  : const Color(0xffe5a400).withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(16),
              border: selected
                  ? Border.all(color: Colors.black87, width: 2)
                  : null,
              boxShadow: available
                  ? [
                      BoxShadow(
                        color: selected
                            ? const Color(0xffe5a400).withValues(alpha: 0.5)
                            : Colors.black.withValues(alpha: 0.08),
                        blurRadius: selected ? 12 : 6,
                        offset: const Offset(0, 3),
                      ),
                    ]
                  : null,
            ),
            child: Stack(
              children: [
                // "Popular" / "Sem oferta" — mesmo espaço, mutuamente exclusivos
                if (category.id == 'economico' && available)
                  Positioned(
                    top: 3.sp,
                    left: 0.sp,
                    right: 0.sp,
                    child: Center(
                      child: Text(
                        'Popular',
                        style: TextStyle(
                          color: Colors.brown,
                          fontWeight: FontWeight.bold,
                          fontSize: 11.sp,
                          fontFamily: 'Gagalin',
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  )
                else if (!available)
                  Positioned(
                    top: 3.sp,
                    left: 4.sp,
                    right: 4.sp,
                    child: Center(
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 6.sp,
                          vertical: 2.sp,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'Sem oferta',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.grey.shade800,
                            fontWeight: FontWeight.w600,
                            fontSize: 8.5.sp,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ),
                    ),
                  ),

                Padding(
                  padding: EdgeInsets.only(top: 16.sp, bottom: 4.sp),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Center(
                          child: img != null
                              ? Image.asset(img)
                              : Icon(
                                  CarData.categoryIcon(category.id),
                                  size: 32.sp,
                                  color: Colors.black87,
                                ),
                        ),
                      ),
                      Text(
                        category.label,
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 11.sp,
                          fontFamily: 'Gagalin',
                          letterSpacing: 0.5,
                        ),
                      ),
                      if (priceMtn != null) ...[
                        SizedBox(height: 1.sp),
                        Text(
                          '~${priceMtn!.ceil()} MT',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 9.sp,
                            color: Colors.black54,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
