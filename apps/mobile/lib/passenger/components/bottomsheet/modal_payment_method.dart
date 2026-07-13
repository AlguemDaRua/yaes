import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:limousineexecutive/passenger/components/dialogs/default_dialog.dart';
import '../../../utils/asset_paths.dart';

Future<String?> showPaymentMethodModal(BuildContext context) {
  String selectedMethod = "";

  return showModalBottomSheet(
    isDismissible: true,
    backgroundColor: Colors.white,
    enableDrag: true,
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (BuildContext context) {
      return PopScope(
        canPop: true,
        child: StatefulBuilder(
          builder: (context, setState) {
            // ── Option builder ──
            Widget buildOption({
              required String value,
              required String titleText,
              required String subtitleText,
              required String image,
              Color? iconColor,
            }) {
              final bool isSelected = selectedMethod == value;

              return GestureDetector(
                onTap: () {
                  setState(() {
                    selectedMethod = value;
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeInOut,
                  margin: EdgeInsets.symmetric(
                    horizontal: 18.sp,
                    vertical: 5.sp,
                  ),
                  padding: EdgeInsets.symmetric(
                    horizontal: 16.sp,
                    vertical: 14.sp,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xffe5a400).withAlpha(15)
                        : Colors.grey.withAlpha(12),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: isSelected
                          ? const Color(0xffe5a400)
                          : Colors.transparent,
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    children: [
                      // Icon container
                      Container(
                        width: 48.sp,
                        height: 48.sp,
                        padding: EdgeInsets.all(8.sp),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withAlpha(8),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Image.asset(
                          image,
                          color: iconColor,
                          fit: BoxFit.contain,
                        ),
                      ),
                      SizedBox(width: 14.sp),
                      // Text content
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              titleText,
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w600,
                                fontSize: 15.sp,
                                color: Colors.black87,
                              ),
                            ),
                            SizedBox(height: 2.sp),
                            Text(
                              subtitleText,
                              style: GoogleFonts.poppins(
                                fontSize: 11.sp,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Selection indicator
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        width: 24.sp,
                        height: 24.sp,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isSelected
                              ? const Color(0xffe5a400)
                              : Colors.transparent,
                          border: Border.all(
                            color: isSelected
                                ? const Color(0xffe5a400)
                                : Colors.grey.withAlpha(80),
                            width: isSelected ? 0 : 2,
                          ),
                        ),
                        child: isSelected
                            ? Icon(
                                Icons.check,
                                size: 16.sp,
                                color: Colors.white,
                              )
                            : null,
                      ),
                    ],
                  ),
                ),
              );
            }

            return Padding(
              padding: MediaQuery.of(context).viewInsets,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Handle bar
                  SizedBox(height: 12.sp),
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.black.withAlpha(40),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  SizedBox(height: 18.sp),
                  // Title
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20.sp),
                    child: Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(8.sp),
                          decoration: BoxDecoration(
                            color: const Color(0xffe5a400).withAlpha(25),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.payment_rounded,
                            color: const Color(0xffe5a400),
                            size: 20.sp,
                          ),
                        ),
                        SizedBox(width: 12.sp),
                        Text(
                          'Método de Pagamento',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w700,
                            fontSize: 18.sp,
                            color: Colors.black,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 6.sp),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20.sp),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Padding(
                        padding: EdgeInsets.only(left: 44.sp),
                        child: Text(
                          'Escolha como deseja pagar',
                          style: GoogleFonts.poppins(
                            fontSize: 12.sp,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 16.sp),
                  // Payment options
                  buildOption(
                    value: "mpesa",
                    titleText: "M-Pesa",
                    subtitleText: "Pagamento com dinheiro móvel",
                    image: AssetPaths.mpesa,
                  ),
                  buildOption(
                    value: "emola",
                    titleText: "E-Mola",
                    subtitleText: "Pagamento com dinheiro móvel",
                    image: AssetPaths.emola,
                    iconColor: Colors.orange,
                  ),
                  buildOption(
                    value: "cartao",
                    titleText: "Cartão",
                    subtitleText: "Pagamento com cartão bancário",
                    image: AssetPaths.creditCard,
                  ),
                  SizedBox(height: 20.sp),
                  // Confirm button
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20.sp),
                    child: GestureDetector(
                      onTap: () async {
                        if (selectedMethod.isEmpty) {
                          await showDefaultDialog(
                            context,
                            title: 'Aviso',
                            content:
                                'Por favor, selecione um método de pagamento!',
                          );
                          return;
                        }
                        Navigator.pop(context, selectedMethod);
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        height: 54.sp,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: selectedMethod.isNotEmpty
                              ? const Color(0xffe5a400)
                              : Colors.grey.withAlpha(60),
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: selectedMethod.isNotEmpty
                              ? [
                                  BoxShadow(
                                    color:
                                        const Color(0xffe5a400).withAlpha(80),
                                    spreadRadius: 0,
                                    blurRadius: 16,
                                    offset: const Offset(0, 6),
                                  ),
                                ]
                              : [],
                        ),
                        child: Center(
                          child: Text(
                            'Pagar',
                            style: GoogleFonts.poppins(
                              color: selectedMethod.isNotEmpty
                                  ? Colors.white
                                  : Colors.grey,
                              fontSize: 15.sp,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 24.sp),
                ],
              ),
            );
          },
        ),
      );
    },
  );
}
