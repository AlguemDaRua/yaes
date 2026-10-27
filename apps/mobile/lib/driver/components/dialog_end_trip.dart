import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:limousineexecutive/services/rating_service.dart';

Future<void> showRatePassengerDialog(
  BuildContext context, {
  required String tripId,
}) {
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => _RatePassengerDialog(tripId: tripId),
  );
}

class _RatePassengerDialog extends StatefulWidget {
  const _RatePassengerDialog({required this.tripId});

  final String tripId;

  @override
  State<_RatePassengerDialog> createState() => _RatePassengerDialogState();
}

class _RatePassengerDialogState extends State<_RatePassengerDialog> {
  final _commentController = TextEditingController();
  double _rating = 0;
  bool _submitting = false;
  bool _submitted = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_rating < 1 || _submitting) return;
    setState(() => _submitting = true);
    try {
      await RatingService.submit(
        tripId: widget.tripId,
        value: _rating,
        comment: _commentController.text,
      );
      if (mounted) setState(() => _submitted = true);
    } catch (error) {
      if (!mounted) return;
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Não foi possível enviar a avaliação: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final label = switch (_rating.round()) {
      1 => 'Experiência difícil',
      2 => 'Pode melhorar',
      3 => 'Tudo certo',
      4 => 'Boa experiência',
      5 => 'Passageiro excelente',
      _ => 'Selecione uma avaliação',
    };

    return Dialog(
      insetPadding: EdgeInsets.symmetric(horizontal: 22.w, vertical: 24.h),
      backgroundColor: Colors.transparent,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Container(
          padding: EdgeInsets.fromLTRB(22.w, 24.h, 22.w, 18.h),
          decoration: BoxDecoration(
            color: const Color(0xFF171918),
            borderRadius: BorderRadius.circular(26.r),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.42),
                blurRadius: 28,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 56.w,
                  height: 56.w,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE5A400).withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(18.r),
                  ),
                  child: Icon(
                    _submitted
                        ? Icons.check_circle_rounded
                        : Icons.person_rounded,
                    color: Colors.amberAccent,
                    size: 31.sp,
                  ),
                ),
                SizedBox(height: 15.h),
                Text(
                  _submitted ? 'Avaliação enviada' : 'Viagem concluída',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 19.sp,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 5.h),
                Text(
                  _submitted
                      ? 'Obrigado por ajudar a manter a comunidade YAapp segura e respeitosa.'
                      : 'Como foi a experiência com o passageiro?',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    color: Colors.white.withValues(alpha: 0.65),
                    fontSize: 12.5.sp,
                    height: 1.45,
                  ),
                ),
                SizedBox(height: 20.h),
                if (!_submitted)
                  RatingBar.builder(
                    initialRating: _rating,
                    minRating: 1,
                    direction: Axis.horizontal,
                    allowHalfRating: true,
                    itemCount: 5,
                    itemPadding: EdgeInsets.symmetric(horizontal: 3.w),
                    itemSize: 39.sp,
                    itemBuilder: (context, index) => const Icon(
                      Icons.star_rounded,
                      color: Colors.amberAccent,
                    ),
                    onRatingUpdate: (value) => setState(() => _rating = value),
                  ),
                if (!_submitted) SizedBox(height: 6.h),
                if (!_submitted)
                  Text(
                    label,
                    style: GoogleFonts.poppins(
                      color: Colors.amberAccent,
                      fontWeight: FontWeight.w600,
                      fontSize: 12.sp,
                    ),
                  ),
                if (!_submitted) SizedBox(height: 17.h),
                if (!_submitted)
                  TextField(
                    controller: _commentController,
                    minLines: 2,
                    maxLines: 3,
                    textCapitalization: TextCapitalization.sentences,
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 13.sp,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Comentário opcional',
                      hintStyle: GoogleFonts.poppins(
                        color: Colors.white.withValues(alpha: 0.44),
                        fontSize: 12.sp,
                      ),
                      filled: true,
                      fillColor: Colors.white.withValues(alpha: 0.06),
                      contentPadding: EdgeInsets.all(14.w),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15.r),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                SizedBox(height: 19.h),
                if (_submitted)
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFFE5A400),
                        foregroundColor: const Color(0xFF201A0D),
                        minimumSize: Size.fromHeight(48.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15.r),
                        ),
                      ),
                      child: Text(
                        'Concluir',
                        style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                if (!_submitted)
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: _submitting
                              ? null
                              : () => Navigator.of(context).pop(),
                          child: Text(
                            'Agora não',
                            style: GoogleFonts.poppins(
                              color: Colors.white.withValues(alpha: 0.64),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFFE5A400),
                            foregroundColor: const Color(0xFF201A0D),
                            minimumSize: Size.fromHeight(48.h),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15.r),
                            ),
                          ),
                          onPressed: _rating < 1 || _submitting
                              ? null
                              : _submit,
                          child: _submitting
                              ? SizedBox(
                                  width: 18.w,
                                  height: 18.w,
                                  child: const CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : Text(
                                  'Enviar avaliação',
                                  maxLines: 1,
                                  style: GoogleFonts.poppins(
                                    fontSize: 12.sp,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
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
}
