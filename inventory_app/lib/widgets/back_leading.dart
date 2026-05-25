import 'package:flutter/material.dart';

/// Botón ← para volver al menú principal (pestaña Inicio) o a la pantalla anterior.
Widget? buildBackLeading(
  BuildContext context, {
  VoidCallback? onBackToMenu,
}) {
  if (onBackToMenu != null) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      tooltip: 'Volver al inicio',
      onPressed: onBackToMenu,
    );
  }
  if (Navigator.of(context).canPop()) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () => Navigator.of(context).pop(),
    );
  }
  return null;
}
