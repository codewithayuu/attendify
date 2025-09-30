import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class EmptyStateWidget extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String? actionText;
  final VoidCallback? onAction;

  const EmptyStateWidget({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.actionText,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 60,
                color: Theme.of(context).primaryColor.withOpacity(0.6),
              ),
            ).animate().scale(duration: 600.ms, curve: Curves.elasticOut),
            
            const SizedBox(height: 32),
            
            // Title
            Text(
              title,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ).animate().fadeIn(duration: 300.ms, delay: 200.ms).slideY(),
            
            const SizedBox(height: 16),
            
            // Subtitle
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).textTheme.bodyLarge?.color?.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ).animate().fadeIn(duration: 300.ms, delay: 400.ms).slideY(),
            
            if (actionText != null && onAction != null) ...[
              const SizedBox(height: 32),
              
              // Action button
              ElevatedButton.icon(
                onPressed: onAction,
                icon: const Icon(Icons.add),
                label: Text(actionText!),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                ),
              ).animate().fadeIn(duration: 300.ms, delay: 600.ms).slideY(),
            ],
          ],
        ),
      ),
    );
  }
}

