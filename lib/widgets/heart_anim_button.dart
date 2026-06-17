import 'package:flutter/material.dart';

class HeartAnimButton extends StatefulWidget {
  final bool isLiked;
  final VoidCallback onTap;
  final double size;
  final Color? color;

  HeartAnimButton({
    super.key,
    required this.isLiked,
    required this.onTap,
    this.size = 28,
    this.color,
  });

  @override
  State<HeartAnimButton> createState() => _HeartAnimButtonState();
}

class _HeartAnimButtonState extends State<HeartAnimButton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: Duration(milliseconds: 300),
      vsync: this,
    );

    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.08).chain(CurveTween(curve: Curves.easeOut)), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 1.08, end: 1.0).chain(CurveTween(curve: Curves.easeIn)), weight: 50),
    ]).animate(_controller);

    _glowAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 70),
    ]).animate(_controller);
  }

  @override
  void didUpdateWidget(HeartAnimButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isLiked && !oldWidget.isLiked) {
      _controller.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Stack(
            alignment: Alignment.center,
            children: [
              // Glow effect (Subtle)
              if (_glowAnimation.value > 0)
                Container(
                  width: widget.size * 0.8,
                  height: widget.size * 0.8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: (widget.color ?? Colors.redAccent).withOpacity(_glowAnimation.value * 0.2),
                        blurRadius: (widget.size * 0.4) * _glowAnimation.value,
                        spreadRadius: (widget.size * 0.15) * _glowAnimation.value,
                      ),
                    ],
                  ),
                ),
              
              // Heart Icon
              Transform.scale(
                scale: _scaleAnimation.isAnimating ? _scaleAnimation.value : 1.0,
                child: Icon(
                  widget.isLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                  color: widget.isLiked ? (widget.color ?? Colors.redAccent) : (widget.color ?? Colors.white.withOpacity(0.5)),
                  size: widget.size,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
