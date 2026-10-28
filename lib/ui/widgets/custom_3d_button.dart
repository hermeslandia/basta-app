import 'package:flutter/material.dart';

class Custom3DButton extends StatefulWidget {
  final String text;
  final VoidCallback onPressed;
  final Color color;
  final Color shadowColor;
  final IconData? icon;

  const Custom3DButton({
    Key? key,
    required this.text,
    required this.onPressed,
    required this.color,
    required this.shadowColor,
    this.icon,
  }) : super(key: key);

  @override
  State<Custom3DButton> createState() => _Custom3DButtonState();
}

class _Custom3DButtonState extends State<Custom3DButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onPressed();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        margin: EdgeInsets.only(top: _isPressed ? 6.0 : 0.0),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              widget.color.withOpacity(0.8),
              widget.color,
              widget.color.withOpacity(0.9),
            ],
            stops: const [0.0, 0.5, 1.0],
          ),
          borderRadius: BorderRadius.circular(30),
          boxShadow: _isPressed
              ? [
                  BoxShadow(color: widget.shadowColor.withOpacity(0.5), blurRadius: 5, offset: const Offset(0, 2)),
                ]
              : [
                  BoxShadow(color: widget.shadowColor, offset: const Offset(0, 6)),
                  BoxShadow(color: Colors.white.withOpacity(0.3), offset: const Offset(0, -2), blurRadius: 4, spreadRadius: 1), // Highlight superior
                  BoxShadow(color: Colors.black.withOpacity(0.2), offset: const Offset(0, 2), blurRadius: 4, spreadRadius: 1), // Sombra interior simulada
                ],
          border: Border.all(
            color: Colors.white.withOpacity(0.6),
            width: 2,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (widget.icon != null) ...[
              Icon(widget.icon, color: Colors.white),
              const SizedBox(width: 8),
            ],
            Text(
              widget.text,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
