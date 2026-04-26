import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/location_record.dart';

/// Empty state, optional latest-fix summary, and efficient list of records.
class LocationLogPanel extends StatelessWidget {
  const LocationLogPanel({
    super.key,
    required this.records,
    required this.initialLoadComplete,
    required this.lastUpdated,
  });

  final List<LocationRecord> records;
  final bool initialLoadComplete;
  final DateTime? lastUpdated;

  static String _formatTimestamp(DateTime utc) {
    final local = utc.toLocal();
    return DateFormat.yMMMd().add_Hms().format(local);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    if (!initialLoadComplete) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: Center(
          child: SizedBox(
            width: 28,
            height: 28,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color: scheme.primary,
            ),
          ),
        ),
      );
    }

    if (records.isEmpty) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(8, 24, 8, 32),
        child: Column(
          children: [
            Icon(
              Icons.route_outlined,
              size: 56,
              color: scheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              'No location logs yet',
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Grant permissions, then start tracking. '
              'New fixes appear here after a few seconds.',
              style: textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
                height: 1.35,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    final latest = records.first;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (lastUpdated != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              'List updated · ${_formatTimestamp(lastUpdated!)}',
              style: textTheme.labelSmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ),
        Card(
          elevation: 0,
          color: scheme.surfaceContainerLow,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: BorderSide(
              color: scheme.outlineVariant.withValues(alpha: 0.5),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Latest fix',
                  style: textTheme.labelLarge?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 6),
                SelectableText(
                  '${latest.latitude.toStringAsFixed(6)}, '
                  '${latest.longitude.toStringAsFixed(6)}',
                  style: textTheme.titleSmall?.copyWith(
                    fontFamily: 'monospace',
                    fontFamilyFallback: const ['monospace'],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatTimestamp(latest.timestamp),
                  style: textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: records.length,
          itemBuilder: (context, index) {
            final record = records[index];
            return Padding(
              padding: EdgeInsets.only(bottom: index == records.length - 1 ? 0 : 10),
              child: _LocationRecordCard(record: record),
            );
          },
        ),
      ],
    );
  }
}

class _LocationRecordCard extends StatelessWidget {
  const _LocationRecordCard({required this.record});

  final LocationRecord record;

  static String _formatTimestamp(DateTime utc) {
    final local = utc.toLocal();
    return DateFormat.yMMMd().add_Hms().format(local);
  }

  static String _speedLabel(double speedMetersPerSecond) {
    if (speedMetersPerSecond.isNaN || speedMetersPerSecond < 0) {
      return '—';
    }
    final kmh = speedMetersPerSecond * 3.6;
    if (kmh < 0.05 && speedMetersPerSecond < 0.05) {
      return '0 m/s';
    }
    return '${speedMetersPerSecond.toStringAsFixed(1)} m/s · '
        '${kmh.toStringAsFixed(1)} km/h';
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Card(
      elevation: 0,
      color: scheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: scheme.outlineVariant.withValues(alpha: 0.55),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: SelectableText(
                    '${record.latitude.toStringAsFixed(6)}\n'
                    '${record.longitude.toStringAsFixed(6)}',
                    style: textTheme.titleSmall?.copyWith(
                      fontFamily: 'monospace',
                      fontFamilyFallback: const ['monospace'],
                      height: 1.35,
                    ),
                  ),
                ),
                if (record.isMocked)
                  Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: Icon(
                      Icons.science_outlined,
                      size: 18,
                      color: scheme.tertiary,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            _MetaRow(
              icon: Icons.gps_fixed_rounded,
              text:
                  'Accuracy ${record.accuracy.toStringAsFixed(1)} m',
            ),
            const SizedBox(height: 6),
            _MetaRow(
              icon: Icons.speed_rounded,
              text: 'Speed ${_speedLabel(record.speed)}',
            ),
            const SizedBox(height: 6),
            _MetaRow(
              icon: Icons.schedule_rounded,
              text: _formatTimestamp(record.timestamp),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetaRow extends StatelessWidget {
  const _MetaRow({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final style = Theme.of(context).textTheme.bodySmall?.copyWith(
          color: scheme.onSurfaceVariant,
          height: 1.25,
        );
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: scheme.outline),
        const SizedBox(width: 8),
        Expanded(child: Text(text, style: style)),
      ],
    );
  }
}
