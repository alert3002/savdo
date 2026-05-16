import 'package:flutter/material.dart';

/// Дружелюбное сообщение об ошибке (без сырого exception).
String friendlyErrorMessage(Object error) {
  final s = error.toString();
  if (s.contains('SocketException') || s.contains('Failed host lookup')) {
    return 'Нет подключения к интернету. Проверьте сеть и попробуйте снова.';
  }
  if (s.contains('TimeoutException') || s.contains('timed out')) {
    return 'Сервер не отвечает. Попробуйте позже.';
  }
  if (s.contains('ApiException')) {
    return 'Ошибка сервера. Попробуйте позже.';
  }
  return 'Что-то пошло не так. Попробуйте снова.';
}

class ErrorRetryPanel extends StatelessWidget {
  const ErrorRetryPanel({
    super.key,
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.cloud_off_outlined, size: 48, color: scheme.primary.withValues(alpha: 0.7)),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: textTheme.bodyMedium?.copyWith(
              color: scheme.onSurface.withValues(alpha: 0.75),
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.tonal(
            onPressed: onRetry,
            child: const Text('Повторить'),
          ),
        ],
      ),
    );
  }
}
