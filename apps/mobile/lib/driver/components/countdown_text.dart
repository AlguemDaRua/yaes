import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:limousineexecutive/utils/asset_paths.dart';
import 'package:limousineexecutive/driver/models/driver_state.dart';
import 'package:provider/provider.dart';
import 'package:vibration/vibration.dart';

class CountdownText extends StatefulWidget {
  final int duration; // in seconds
  const CountdownText({super.key, this.duration = 10});

  @override
  State<CountdownText> createState() => _CountdownTextState();
}

class _CountdownTextState extends State<CountdownText> {
  late int _remaining;
  Timer? _timer;

  final AudioPlayer _audioPlayer = AudioPlayer();

  Future<void> tocar() async {
    vibrar();

    await _audioPlayer.setReleaseMode(ReleaseMode.loop);

    await _audioPlayer.play(AssetSource(AssetPaths.ringtone));
  }

  void vibrar() async {
    if ((await Vibration.hasVibrator()) == true) {
      Vibration.vibrate(duration: widget.duration * 1000); // vibrate for 500ms
    }
  }

  @override
  void initState() {
    super.initState();
    _remaining = widget.duration;

    tocar(); // start playing on init

    final appState = Provider.of<DriverState>(context, listen: false);

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (appState.isOnTrip || !appState.isRinging) {
        _timer?.cancel();
        _audioPlayer.stop();
        Vibration.cancel();
        return;
      }

      if (_remaining > 0) {
        setState(() {
          _remaining--;
        });
      } else {
        _timer?.cancel();
        _audioPlayer.stop(); // stop sound when time runs out
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _audioPlayer.stop(); // ensures the sound stops when leaving the widget
    Vibration.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.sp, vertical: 6.sp),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        '${_remaining}s',
        style: TextStyle(
          fontSize: 17.sp,
          color: Colors.white,
          fontWeight: FontWeight.normal,
        ),
      ),
    );
  }
}
