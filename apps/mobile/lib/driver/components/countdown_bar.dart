import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:limousineexecutive/driver/models/driver_state.dart';
import 'package:provider/provider.dart';

class CountdownBar extends StatefulWidget {
  final int duration; // in seconds
  const CountdownBar({super.key, this.duration = 10});

  @override
  State<CountdownBar> createState() => _CountdownBarState();
}

class _CountdownBarState extends State<CountdownBar> {
  late int _remaining;
  Timer? _timer;

  double get progress => _remaining / widget.duration;

  @override
  void initState() {
    super.initState();
    _remaining = widget.duration;
    final appState = Provider.of<DriverState>(context, listen: false);

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (appState.isOnTrip || !appState.isRinging) {
        _timer?.cancel();
        return;
      }

      if (_remaining > 0) {
        setState(() {
          _remaining--;
        });
      } else {
        _timer?.cancel();
        appState.setIsRinging(false);
        appState.showUnacceptDialog(context);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appSate = Provider.of<DriverState>(context, listen: false);

    return Column(
      children: [
        LinearProgressIndicator(
          value: progress,
          minHeight: 8.h,
          backgroundColor: Colors.grey[300],
          borderRadius: BorderRadius.circular(20),
          valueColor: AlwaysStoppedAnimation<Color>(appSate.mainColor),
        ),
      ],
    );
  }
}
