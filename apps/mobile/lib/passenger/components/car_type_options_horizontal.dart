import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:limousineexecutive/passenger/models/cardata.dart';
import 'package:limousineexecutive/passenger/models/passenger_state.dart';
import 'package:limousineexecutive/services/pricing_service.dart';
import 'package:provider/provider.dart';
import 'package:limousineexecutive/shared/widgets/skeletons.dart';

/// Seletor horizontal de categorias — lê /config/pricing/categories, por isso
/// o que o passageiro vê é exactamente o que a operação activou (ex.: em
/// Nampula só moto + económico; sem release para mudar).
class CarTypeOptionsHorizontal extends StatefulWidget {
  const CarTypeOptionsHorizontal({super.key});

  @override
  State<CarTypeOptionsHorizontal> createState() =>
      _CarTypeOptionsHorizontalState();
}

class _CarTypeOptionsHorizontalState extends State<CarTypeOptionsHorizontal> {
  final Future<List<CarCategory>> _categories =
      PricingService.fetchCategories();

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<PassengerState>(context);

    if (appState.isLoadingVehicles) {
      return const VehicleTypeSkeleton();
    }

    return FutureBuilder<List<CarCategory>>(
      future: _categories,
      builder: (context, snapshot) {
        final categories = snapshot.data ?? kDefaultCategories;
        return SizedBox(
          height: 75.sp,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: categories.length,
            padding: EdgeInsets.symmetric(horizontal: 16.sp),
            itemBuilder: (context, index) {
              final category = categories[index];
              final img = CarData.categoryImages[category.id];
              return InkWell(
                onTap: () => appState.selectCategory(
                  category.id,
                  category.label,
                  index,
                ),
                child: Container(
                  width: 75.sp,
                  margin: EdgeInsets.only(right: 12.sp),
                  child: Stack(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: appState.selectedCarTypeindex == index
                              ? Colors.amberAccent.withValues(alpha: 0.2)
                              : Colors.amber.withValues(alpha: 0.59),
                        ),
                      ),

                      // "Popular" na categoria económica
                      if (category.id == 'economico')
                        Positioned(
                          top: 1.sp,
                          left: 0.sp,
                          right: 0.sp,
                          child: Center(
                            child: Text(
                              'Popular',
                              style: TextStyle(
                                color: Colors.brown,
                                fontWeight: FontWeight.bold,
                                fontSize: 12.sp,
                                fontFamily: 'Gagalin',
                                letterSpacing: 1,
                              ),
                            ),
                          ),
                        ),

                      // Imagem da categoria (ou ícone quando não há asset)
                      Positioned.fill(
                        child: img != null
                            ? Image.asset(img)
                            : Center(
                                child: Icon(
                                  CarData.categoryIcon(category.id),
                                  size: 34.sp,
                                  color: Colors.black87,
                                ),
                              ),
                      ),

                      Positioned(
                        bottom: 0.sp,
                        left: 0.sp,
                        right: 0.sp,
                        child: Align(
                          alignment: Alignment.bottomCenter,
                          child: Padding(
                            padding: EdgeInsets.all(2.sp),
                            child: Text(
                              category.label,
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12.sp,
                                letterSpacing: 1,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
