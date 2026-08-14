import 'package:asisteqr_baker/app/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:quickalert/quickalert.dart';

enum AppFeedbackType { success, error, warning, info }

enum SavedFileAction { close, preview, reveal }

Future<void> showAppFeedback(
  BuildContext context, {
  required AppFeedbackType type,
  required String title,
  required String message,
  String actionLabel = 'Entendido',
}) async {
  final alertType = switch (type) {
    AppFeedbackType.success => QuickAlertType.success,
    AppFeedbackType.error => QuickAlertType.error,
    AppFeedbackType.warning => QuickAlertType.warning,
    AppFeedbackType.info => QuickAlertType.info,
  };
  final headerColor = switch (type) {
    AppFeedbackType.success => AppColors.greenSoft,
    AppFeedbackType.error => AppColors.redSoft,
    AppFeedbackType.warning => AppColors.amberSoft,
    AppFeedbackType.info => AppColors.blueSoft,
  };
  final width = (MediaQuery.sizeOf(context).width - 40).clamp(280, 420);

  await QuickAlert.show(
    context: context,
    type: alertType,
    animType: QuickAlertAnimType.scale,
    title: title,
    text: message,
    titleAlignment: TextAlign.center,
    textAlignment: TextAlign.center,
    confirmBtnText: actionLabel,
    confirmBtnColor: AppColors.navy,
    confirmBtnTextStyle: const TextStyle(
      color: Colors.white,
      fontWeight: FontWeight.w700,
      fontSize: 15,
    ),
    backgroundColor: AppColors.surface,
    headerBackgroundColor: headerColor,
    titleColor: AppColors.ink,
    textColor: AppColors.inkMuted,
    barrierColor: Colors.black54,
    barrierDismissible: true,
    borderRadius: 8,
    width: width.toDouble(),
  );
}

Future<void> showAppSuccess(
  BuildContext context,
  String message, {
  String title = 'Listo',
}) => showAppFeedback(
  context,
  type: AppFeedbackType.success,
  title: title,
  message: message,
);

Future<void> showAppWarning(
  BuildContext context, {
  required String title,
  required String message,
  String actionLabel = 'Entendido',
}) => showAppFeedback(
  context,
  type: AppFeedbackType.warning,
  title: title,
  message: message,
  actionLabel: actionLabel,
);

Future<void> showAppErrorDialog(
  BuildContext context, {
  required String title,
  required String message,
  String actionLabel = 'Entendido',
}) => showAppFeedback(
  context,
  type: AppFeedbackType.error,
  title: title,
  message: message,
  actionLabel: actionLabel,
);

Future<SavedFileAction> showSavedFileDialog(
  BuildContext context, {
  required String fileName,
  required String location,
  required bool canReveal,
}) async {
  final result = await showDialog<SavedFileAction>(
    context: context,
    builder: (context) => AlertDialog(
      icon: const Icon(
        LucideIcons.circleCheckBig,
        color: AppColors.green,
        size: 34,
      ),
      title: const Text('PDF guardado'),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              fileName,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            const Text(
              'Ubicación',
              style: TextStyle(
                color: AppColors.inkMuted,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            SelectableText(location),
          ],
        ),
      ),
      actionsOverflowDirection: VerticalDirection.down,
      actionsOverflowButtonSpacing: 6,
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, SavedFileAction.close),
          child: const Text('Cerrar'),
        ),
        if (canReveal)
          OutlinedButton.icon(
            onPressed: () => Navigator.pop(context, SavedFileAction.reveal),
            icon: const Icon(LucideIcons.folderOpen, size: 18),
            label: const Text('Abrir carpeta'),
          ),
        ElevatedButton.icon(
          onPressed: () => Navigator.pop(context, SavedFileAction.preview),
          icon: const Icon(LucideIcons.eye, size: 18),
          label: const Text('Ver o imprimir'),
        ),
      ],
    ),
  );
  return result ?? SavedFileAction.close;
}
