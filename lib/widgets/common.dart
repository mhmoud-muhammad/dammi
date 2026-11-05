import 'package:flutter/material.dart';

import '../core/theme.dart';

/// عنوان الحقل فوق مدخل النموذج.
class FieldLabel extends StatelessWidget {
  final String text;
  const FieldLabel(this.text, {super.key});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(text, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
      );
}

class HelperText extends StatelessWidget {
  final String text;
  const HelperText(this.text, {super.key});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 6),
        child: Text(text, style: const TextStyle(fontSize: 13, color: AppColors.muted)),
      );
}

class LoadingView extends StatelessWidget {
  const LoadingView({super.key});

  @override
  Widget build(BuildContext context) =>
      const Scaffold(body: Center(child: CircularProgressIndicator()));
}

class MessageView extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;

  const MessageView({super.key, required this.icon, required this.title, this.subtitle});

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 48, color: AppColors.muted),
              const SizedBox(height: 12),
              Text(title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
              if (subtitle != null) ...[
                const SizedBox(height: 6),
                Text(subtitle!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 14, color: AppColors.muted)),
              ],
            ],
          ),
        ),
      );
}

void showSnack(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}
