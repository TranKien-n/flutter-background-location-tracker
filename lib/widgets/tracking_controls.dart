import 'package:flutter/material.dart';

/// Start / stop / permissions / clear actions with clear visual hierarchy.
class TrackingControls extends StatelessWidget {
  const TrackingControls({
    super.key,
    required this.isTracking,
    required this.canStart,
    required this.hasRecords,
    required this.onRequestPermissions,
    required this.onStart,
    required this.onStop,
    required this.onClear,
  });

  final bool isTracking;
  final bool canStart;
  final bool hasRecords;
  final VoidCallback onRequestPermissions;
  final VoidCallback onStart;
  final VoidCallback onStop;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FilledButton.tonalIcon(
          onPressed: onRequestPermissions,
          icon: const Icon(Icons.shield_outlined, size: 20),
          label: const Text('Request permissions'),
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 14),
            alignment: Alignment.center,
          ),
        ),
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: isTracking || !canStart ? null : onStart,
          icon: const Icon(Icons.play_arrow_rounded, size: 22),
          label: const Text('Start tracking'),
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
        ),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          onPressed: isTracking ? onStop : null,
          icon: Icon(
            Icons.stop_rounded,
            size: 22,
            color: isTracking ? scheme.error : scheme.onSurface.withValues(alpha: 0.38),
          ),
          label: Text(
            'Stop tracking',
            style: TextStyle(
              color: isTracking
                  ? scheme.error
                  : scheme.onSurface.withValues(alpha: 0.38),
              fontWeight: FontWeight.w600,
            ),
          ),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 14),
            side: BorderSide(
              color: isTracking
                  ? scheme.error.withValues(alpha: 0.65)
                  : scheme.outlineVariant,
            ),
            disabledForegroundColor: scheme.onSurface.withValues(alpha: 0.38),
            disabledIconColor: scheme.onSurface.withValues(alpha: 0.38),
          ),
        ),
        const SizedBox(height: 10),
        TextButton.icon(
          onPressed: hasRecords ? onClear : null,
          icon: Icon(
            Icons.delete_outline_rounded,
            size: 20,
            color: hasRecords
                ? scheme.onSurfaceVariant
                : scheme.onSurface.withValues(alpha: 0.28),
          ),
          label: Text(
            'Clear saved logs',
            style: TextStyle(
              color: hasRecords
                  ? scheme.onSurfaceVariant
                  : scheme.onSurface.withValues(alpha: 0.28),
            ),
          ),
        ),
      ],
    );
  }
}
