import 'package:flutter/material.dart';
import 'package:limousineexecutive/shared/widgets/trip_cancellation_dialog.dart';

Future<bool?> showCancelTripDialog(
  BuildContext context,
  Future<void> Function(String reason) onConfirm,
) {
  return showTripCancellationDialog(
    context,
    onConfirm: onConfirm,
    driverTheme: true,
    interrupting: false,
  );
}
