import 'package:flutter/material.dart';

Future<bool> confirmDelete(BuildContext context) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Eliminar'),
      content: const Text(
        '¿Estás seguro de que quieres eliminar este elemento? '
        'Esta acción no se puede deshacer',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancelar'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Eliminar'),
        ),
      ],
    ),
  );
  return confirmed == true;
}

Future<bool> confirmSaveChanges(BuildContext context) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Guardar cambios'),
      content: const Text('¿Deseas guardar los cambios?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancelar'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Guardar'),
        ),
      ],
    ),
  );
  return confirmed == true;
}

Future<bool> confirmDiscardChanges(BuildContext context) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Descartar cambios'),
      content: const Text('¿Deseas descartar los cambios?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancelar'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Descartar'),
        ),
      ],
    ),
  );
  return confirmed == true;
}

Future<void> closeFormSheet(
  BuildContext context, {
  required bool isEditMode,
  required bool Function() hasUnsavedChanges,
}) async {
  if (!isEditMode || !hasUnsavedChanges()) {
    Navigator.of(context).pop();
    return;
  }
  final discard = await confirmDiscardChanges(context);
  if (discard && context.mounted) {
    Navigator.of(context).pop();
  }
}

/// Bloquea el cierre del sheet en edición si hay cambios sin guardar.
class FormDiscardPopScope extends StatelessWidget {
  final bool isEditMode;
  final bool Function() hasUnsavedChanges;
  final Widget child;

  const FormDiscardPopScope({
    super.key,
    required this.isEditMode,
    required this.hasUnsavedChanges,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !isEditMode || !hasUnsavedChanges(),
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        await closeFormSheet(
          context,
          isEditMode: isEditMode,
          hasUnsavedChanges: hasUnsavedChanges,
        );
      },
      child: child,
    );
  }
}
