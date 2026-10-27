import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:limousineexecutive/passenger/models/passenger_state.dart';
import 'package:limousineexecutive/services/rating_service.dart';
import 'package:provider/provider.dart';

/// Shows the post-trip rating dialog and submits it via [RatingService].
/// Best-effort: dismiss/skip never blocks the passenger — rating is optional.
Future<void> showRateDriverDialog(
  BuildContext context, {
  required String tripId,
}) {
  return showDialog<void>(
    context: context,
    barrierDismissible: true,
    builder: (_) => RateDriverDialog(tripId: tripId),
  );
}

class RateDriverDialog extends StatefulWidget {
  const RateDriverDialog({super.key, required this.tripId});

  final String tripId;

  @override
  State<RateDriverDialog> createState() => _RateDriverDialogState();
}

class _RateDriverDialogState extends State<RateDriverDialog> {
  double _rating = 0.0;
  final _commentController = TextEditingController();
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
    } catch (e) {
      if (mounted) {
        setState(() => _submitting = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erro ao enviar avaliação: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final passengerState = Provider.of<PassengerState>(context, listen: false);
    final driverName = passengerState.driverName.trim();
    final photoUrl = passengerState.driverPhotoUrl;
    final ratingLabel = switch (_rating.round()) {
      1 => 'Muito mau',
      2 => 'Mau',
      3 => 'Razoável',
      4 => 'Bom',
      5 => 'Excelente',
      _ => 'Toque numa estrela para avaliar',
    };

    return Dialog(
      insetPadding: EdgeInsets.symmetric(horizontal: 22.w, vertical: 24.h),
      backgroundColor: Colors.transparent,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Container(
          padding: EdgeInsets.fromLTRB(22.w, 24.h, 22.w, 18.h),
          decoration: BoxDecoration(
            color: const Color(0xFFFFFEFC),
            borderRadius: BorderRadius.circular(28.r),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF28251F).withValues(alpha: 0.18),
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
                    color: const Color(0xFFFFF3D4),
                    borderRadius: BorderRadius.circular(19.r),
                  ),
                  child: Icon(
                    _submitted
                        ? Icons.check_circle_rounded
                        : Icons.star_rounded,
                    color: const Color(0xFFE5A400),
                    size: 34.sp,
                  ),
                ),
                SizedBox(height: 14.h),
                Text(
                  _submitted ? 'Avaliação enviada' : 'Como foi a sua viagem?',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    color: const Color(0xFF24251F),
                    fontSize: 19.sp,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 6.h),
                Text(
                  _submitted
                      ? 'Obrigado por ajudar a manter a YAapp segura e fiável.'
                      : 'A sua avaliação ajuda a manter a Yaapp cada vez melhor.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    color: const Color(0xFF77786F),
                    fontSize: 12.5.sp,
                    height: 1.45,
                  ),
                ),
                SizedBox(height: 18.h),
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(12.w),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF7F6F2),
                    borderRadius: BorderRadius.circular(18.r),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 23.r,
                        backgroundColor: const Color(0xFFE9E4D8),
                        backgroundImage: photoUrl.isNotEmpty
                            ? NetworkImage(photoUrl)
                            : null,
                        child: photoUrl.isEmpty
                            ? const Icon(Icons.person, color: Color(0xFF77786F))
                            : null,
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Motorista',
                              style: GoogleFonts.poppins(
                                color: const Color(0xFF85867D),
                                fontSize: 11.sp,
                              ),
                            ),
                            Text(
                              driverName.isEmpty ? 'A sua viagem' : driverName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.poppins(
                                color: const Color(0xFF262720),
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.check_circle,
                        color: Color(0xFF3B8B62),
                        size: 20.sp,
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 16.h),
                if (!_submitted)
                  RatingBar.builder(
                    initialRating: _rating,
                    minRating: 1,
                    direction: Axis.horizontal,
                    allowHalfRating: true,
                    itemCount: 5,
                    itemPadding: EdgeInsets.symmetric(horizontal: 3.w),
                    itemSize: 38.sp,
                    itemBuilder: (context, index) => const Icon(
                      Icons.star_rounded,
                      color: Color(0xFFE5A400),
                    ),
                    onRatingUpdate: (value) => setState(() => _rating = value),
                  ),
                if (!_submitted) SizedBox(height: 4.h),
                if (!_submitted)
                  Text(
                    ratingLabel,
                    style: GoogleFonts.poppins(
                      color: const Color(0xFF6E695F),
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                if (!_submitted) SizedBox(height: 16.h),
                if (!_submitted)
                  TextField(
                    controller: _commentController,
                    maxLines: 3,
                    minLines: 2,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: InputDecoration(
                      hintText: 'Deixe um comentário (opcional)',
                      hintStyle: GoogleFonts.poppins(
                        color: const Color(0xFF999A92),
                        fontSize: 12.sp,
                      ),
                      filled: true,
                      fillColor: const Color(0xFFF7F6F2),
                      contentPadding: EdgeInsets.all(14.w),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16.r),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                SizedBox(height: 18.h),
                if (_submitted)
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFFE5A400),
                        foregroundColor: const Color(0xFF211C12),
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
                              color: const Color(0xFF77786F),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 10.w),
                      Expanded(
                        child: FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFFE5A400),
                            foregroundColor: const Color(0xFF211C12),
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
                                    color: Color(0xFF211C12),
                                    strokeWidth: 2,
                                  ),
                                )
                              : Text(
                                  'Enviar avaliação',
                                  maxLines: 1,
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12.sp,
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
