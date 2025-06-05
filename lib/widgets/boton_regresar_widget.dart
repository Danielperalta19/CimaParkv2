import 'package:flutter/material.dart';

class BotonRegresar extends StatelessWidget {
  final Color? color;
  final VoidCallback? onPressed;

  const BotonRegresar({
    super.key,
    this.color,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      heroTag: 'regresar_fab',
      backgroundColor: color ?? Colors.green,
      mini: true,
      onPressed: onPressed ?? () => Navigator.of(context).pop(),
      child: const Icon(
        Icons.arrow_back,
        color: Colors.white,
      ),
    );
  }
} 