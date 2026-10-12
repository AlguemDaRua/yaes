import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:limousineexecutive/passenger/models/saved_place.dart';

/// Pergunta o nome de uma nova morada guardada. O nome é livre (por exemplo
/// "Escola", "Igreja" ou "Casa da avó"). Devolve-o sem espaços nas pontas, ou
/// `null` se o utilizador cancelar.
Future<String?> showPlaceNameDialog(BuildContext context) {
  return showDialog<String>(
    context: context,
    barrierDismissible: true,
    builder: (context) => const _PlaceNameDialog(),
  );
}

class _PlaceNameDialog extends StatefulWidget {
  const _PlaceNameDialog({super.key});

  @override
  State<_PlaceNameDialog> createState() => _PlaceNameDialogState();
}

class _PlaceNameDialogState extends State<_PlaceNameDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _confirm() {
    final name = _controller.text.trim();
    if (name.isNotEmpty) Navigator.pop(context, name);
  }

  @override
  Widget build(BuildContext context) {
    const gold = Color(0xffe5a400);
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24.r)),
      child: Padding(
        padding: EdgeInsets.all(20.sp),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Nome da morada',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w700,
                fontSize: 18.sp,
                color: Colors.black87,
              ),
            ),
            SizedBox(height: 12.sp),
            Text(
              'Escolhe o nome que queres ver na lista.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 14.sp,
                color: Colors.grey.shade600,
                height: 1.5,
              ),
            ),
            SizedBox(height: 16.sp),

            // ── Name field (mesmo estilo do campo de pesquisa) ──
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12.sp),
              decoration: BoxDecoration(
                color: Colors.grey.withAlpha(12),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: gold.withAlpha(40), width: 1.5),
              ),
              child: TextField(
                controller: _controller,
                autofocus: true,
                maxLength: SavedPlace.maxLabelLength,
                textCapitalization: TextCapitalization.sentences,
                textInputAction: TextInputAction.done,
                style: GoogleFonts.poppins(
                  fontSize: 14.sp,
                  color: Colors.black87,
                ),
                decoration: InputDecoration(
                  hintText: 'Ex.: Escola, Igreja, Ginásio',
                  hintStyle: GoogleFonts.poppins(
                    fontSize: 13.sp,
                    color: Colors.grey.shade400,
                  ),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 15.sp),
                ),
                onSubmitted: (_) => _confirm(),
              ),
            ),
            SizedBox(height: 20.sp),

            // ── Buttons ──
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: EdgeInsets.symmetric(vertical: 14.sp),
                      decoration: BoxDecoration(
                        color: Colors.grey.withAlpha(25),
                        borderRadius: BorderRadius.circular(30.r),
                      ),
                      child: Center(
                        child: Text(
                          'Cancelar',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                            fontSize: 15.sp,
                            color: Colors.black54,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 12.sp),
                Expanded(
                  // O botão só fica ativo com um nome escrito.
                  child: ValueListenableBuilder<TextEditingValue>(
                    valueListenable: _controller,
                    builder: (context, value, _) {
                      final enabled = value.text.trim().isNotEmpty;
                      return GestureDetector(
                        onTap: enabled ? _confirm : null,
                        child: Container(
                          padding: EdgeInsets.symmetric(vertical: 14.sp),
                          decoration: BoxDecoration(
                            color: gold.withAlpha(enabled ? 255 : 90),
                            borderRadius: BorderRadius.circular(30.r),
                            boxShadow: enabled
                                ? [
                                    BoxShadow(
                                      color: gold.withAlpha(60),
                                      blurRadius: 8,
                                      offset: const Offset(0, 3),
                                    ),
                                  ]
                                : null,
                          ),
                          child: Center(
                            child: Text(
                              'Continuar',
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w600,
                                fontSize: 15.sp,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
