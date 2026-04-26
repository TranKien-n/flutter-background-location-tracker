import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

/// Material 3 status summary for tracking and permissions.
class TrackingStatusCard extends StatelessWidget {
  const TrackingStatusCard({
    super.key,
    required this.isTracking,
    required this.locationServiceEnabled,
    required this.foregroundPermission,
    required this.backgroundPermission,
    required this.notificationPermission,
  });

  final bool isTracking;
  final bool locationServiceEnabled;
  final PermissionStatus? foregroundPermission;
  final PermissionStatus? backgroundPermission;
  final PermissionStatus? notificationPermission;

  static String _permissionLabel(PermissionStatus? status) {
    if (status == null) return 'Checking…';
    switch (status) {
      case PermissionStatus.granted:
        return 'Granted';
      case PermissionStatus.denied:
        return 'Denied';
      case PermissionStatus.restricted:
        return 'Restricted';
      case PermissionStatus.limited:
        return 'Limited';
      case PermissionStatus.permanentlyDenied:
        return 'Blocked — open Settings';
      case PermissionStatus.provisional:
        return 'Provisional';
    }
  }

  Color _statusColor(
    BuildContext context,
    PermissionStatus? permission,
  ) {
    final scheme = Theme.of(context).colorScheme;
    if (permission != null) {
      if (permission.isGranted) return scheme.primary;
      if (permission.isPermanentlyDenied || permission.isDenied) {
        return scheme.error;
      }
    }
    return scheme.outline;
  }

  Widget _row(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    required Color valueColor,
  }) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Theme.of(context).colorScheme.outline),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: textTheme.labelMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: textTheme.bodyMedium?.copyWith(
                    color: valueColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final trackingLabel = isTracking ? 'Active' : 'Stopped';
    final trackingColor =
        isTracking ? scheme.primary : scheme.onSurfaceVariant;

    return Card(
      elevation: 0,
      color: scheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isTracking ? Icons.radar_rounded : Icons.radar_outlined,
                  color: trackingColor,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Status',
                        style: textTheme.labelLarge?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                      Text(
                        trackingLabel,
                        style: textTheme.titleLarge?.copyWith(
                          color: trackingColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Divider(height: 24, color: scheme.outlineVariant.withValues(alpha: 0.4)),
            _row(
              context,
              icon: Icons.location_searching_rounded,
              label: 'Location service',
              value: locationServiceEnabled ? 'On' : 'Off',
              valueColor: locationServiceEnabled
                  ? scheme.primary
                  : scheme.error,
            ),
            _row(
              context,
              icon: Icons.my_location_rounded,
              label: 'Location (while in use)',
              value: _permissionLabel(foregroundPermission),
              valueColor: _statusColor(context, foregroundPermission),
            ),
            _row(
              context,
              icon: Icons.share_location_rounded,
              label: 'Location (always / background)',
              value: _permissionLabel(backgroundPermission),
              valueColor: _statusColor(context, backgroundPermission),
            ),
            _row(
              context,
              icon: Icons.notifications_active_outlined,
              label: 'Notifications',
              value: _permissionLabel(notificationPermission),
              valueColor: _statusColor(context, notificationPermission),
            ),
          ],
        ),
      ),
    );
  }
}
