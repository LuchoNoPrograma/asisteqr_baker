import 'package:asisteqr_baker/app/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:quickalert/quickalert.dart';

enum AppFeedbackType { success, error, warning, info }

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
