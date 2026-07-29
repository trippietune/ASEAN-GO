import 'package:flutter/material.dart';
import 'gradient_button.dart';

class EmptyStateWidget extends StatelessWidget {
  const EmptyStateWidget({
    super.key,
    required this.icon,
    required this.message,
    this.onRetry,
    this.retryLabel = 'ลองใหม่อีกครั้ง',
  });

  final IconData icon;
  final String message;
  final VoidCallback? onRetry;
  final String retryLabel;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 72, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 15),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 20),
              GradientButton(label: retryLabel, onPressed: onRetry, expand: false),
            ],
          ],
        ),
      ),
    );
  }
}
