import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:limousineexecutive/services/rating_service.dart';

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
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        setState(() => _submitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao enviar avaliação: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
      child: Padding(
        padding: EdgeInsets.all(20.sp),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'AVALIA O MOTORISTA!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.w400,
                fontSize: 20.sp,
                fontFamily: 'Gagalin',
                letterSpacing: 1.sp,
              ),
            ),
            SizedBox(height: 16.sp),
            RatingBar.builder(
              glowColor: Colors.black,
              initialRating: 0,
              minRating: 1,
              direction: Axis.horizontal,
              allowHalfRating: true,
              itemCount: 5,
              itemSize: 44.sp,
              itemBuilder: (context, index) => Icon(
                index < _rating ? Icons.star : Icons.star_border_sharp,
                color: Colors.amber,
              ),
              onRatingUpdate: (value) => setState(() => _rating = value),
            ),
            SizedBox(height: 16.sp),
            TextField(
              controller: _commentController,
              maxLines: 2,
              decoration: InputDecoration(
                hintText: 'Comentário (opcional)',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
              ),
            ),
            SizedBox(height: 16.sp),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: _submitting
                        ? null
                        : () => Navigator.of(context).pop(),
                    child: const Text('Agora não'),
                  ),
                ),
                SizedBox(width: 8.sp),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xffe5a400),
                      foregroundColor: Colors.white,
                    ),
                    onPressed: _rating < 1 || _submitting ? null : _submit,
                    child: _submitting
                        ? SizedBox(
                            width: 18.sp,
                            height: 18.sp,
                            child: const CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text('Enviar'),
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
