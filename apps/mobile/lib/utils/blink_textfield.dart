import 'package:flutter/material.dart';

class BlinkingBorder extends StatefulWidget {
  final Widget child;
  final bool blink;

  const BlinkingBorder({super.key, required this.child, required this.blink});

  @override
  State<BlinkingBorder> createState() => _BlinkingBorderState();
}

class _BlinkingBorderState extends State<BlinkingBorder>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Color?> _color;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );

    _color = ColorTween(
      begin: Colors.transparent,
      end: const Color(0xffe5a400),
    ).animate(_controller);

    if (widget.blink) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(covariant BlinkingBorder oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.blink) {
      _controller.repeat(reverse: true);
    } else {
      _controller.stop();
      _controller.reset();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _color,
      builder: (_, __) {
        return Container(
          decoration: BoxDecoration(
            border: Border.all(
              color: _color.value ?? Colors.transparent,
              width: 2,
            ),
            borderRadius: BorderRadius.circular(15),
          ),
          child: widget.child,
        );
      },
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
