import 'package:flutter/material.dart';
import 'package:vitrine/l10n/gen/app_localizations.dart';

import '../../../../core/design/palette.dart';
import '../../../../core/design/tokens.dart';
import '../../../../core/widgets/motion.dart';
import '../../domain/device.dart';
import '../../domain/telemetry.dart';
import 'flash_on_change.dart';

class DeviceTile extends StatefulWidget {
  const DeviceTile({
    super.key,
    required this.device,
    required this.expanded,
    required this.updated,
    required this.onToggle,
    this.telemetry,
    this.onEdit,
    this.onDelete,
  });

  final Device device;
  final bool expanded;

  /// Changed while collapsed and not opened since.
  final bool updated;
  final Telemetry? telemetry;
  final VoidCallback onToggle;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  @override
  State<DeviceTile> createState() => _DeviceTileState();
}

class _DeviceTileState extends State<DeviceTile> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final p = context.palette;
    final theme = Theme.of(context);
    final device = widget.device;
    final expanded = widget.expanded;

    return PressScale(
      down: _down,
      scale: 0.985,
      child: Container(
        decoration: BoxDecoration(color: p.surface, borderRadius: BorderRadius.circular(Corners.card)),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            InkWell(
              onTap: widget.onToggle,
              onHighlightChanged: (down) => setState(() => _down = down),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(Insets.lg, Insets.sm, Insets.xs, Insets.sm),
                child: Row(
                  children: [
                    Container(
                      constraints: const BoxConstraints(minWidth: 44),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: p.surfaceMuted, borderRadius: BorderRadius.circular(6)),
                      child: Text(
                        device.id.length > 6 ? '#${device.id.substring(device.id.length - 4)}' : device.id,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.labelSmall,
                        semanticsLabel: l10n.deviceId(device.id),
                      ),
                    ),
                    const SizedBox(width: Insets.md),
                    Expanded(
                      child: Text(
                        device.name,
                        style: theme.textTheme.titleSmall,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    AnimatedSwitcher(
                      duration: Motion.slow,
                      switchInCurve: Curves.elasticOut,
                      switchOutCurve: Motion.exit,
                      transitionBuilder: (child, animation) => ScaleTransition(scale: animation, child: child),
                      child: widget.updated
                          ? Semantics(
                              key: const ValueKey('dot'),
                              label: l10n.updatedSinceViewed,
                              child: Container(
                                width: 9,
                                height: 9,
                                margin: const EdgeInsets.only(left: Insets.sm),
                                decoration: BoxDecoration(color: p.accent, shape: BoxShape.circle),
                              ),
                            )
                          : const SizedBox.shrink(),
                    ),
                    IconButton(
                      tooltip: expanded ? l10n.collapseDevice : l10n.expandDevice,
                      onPressed: widget.onToggle,
                      icon: AnimatedRotation(
                        turns: expanded ? 0.5 : 0,
                        duration: Motion.base,
                        curve: Motion.move,
                        child: const Icon(Icons.keyboard_arrow_down_rounded),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            AnimatedSize(
              duration: Motion.base,
              curve: Motion.move,
              alignment: Alignment.topCenter,
              child: expanded
                  ? FadeSlideIn(
                      child: _Details(
                        device: device,
                        telemetry: widget.telemetry,
                        onEdit: widget.onEdit,
                        onDelete: widget.onDelete,
                      ),
                    )
                  : const SizedBox(width: double.infinity),
            ),
          ],
        ),
      ),
    );
  }
}

class _Details extends StatelessWidget {
  const _Details({required this.device, this.telemetry, this.onEdit, this.onDelete});

  final Device device;
  final Telemetry? telemetry;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final p = context.palette;
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(Insets.lg, 0, Insets.lg, Insets.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Divider(),
          const SizedBox(height: Insets.md),
          if (device.data.isEmpty)
            Text(l10n.noDeviceDetails, style: theme.textTheme.bodyMedium)
          else
            for (final entry in device.data.entries)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 5),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 2,
                      child: Text(entry.key, style: theme.textTheme.bodyMedium?.copyWith(color: p.inkFaint)),
                    ),
                    const SizedBox(width: Insets.md),
                    Expanded(
                      flex: 3,
                      child: Text(
                        Device.formatValue(entry.value),
                        style: theme.textTheme.bodyMedium?.copyWith(color: p.ink),
                      ),
                    ),
                  ],
                ),
              ),
          if (telemetry != null) ...[
            const SizedBox(height: Insets.lg),
            Text(l10n.liveReadings, style: theme.textTheme.titleSmall),
            Text(l10n.liveReadingsNote, style: theme.textTheme.bodySmall),
            const SizedBox(height: Insets.md),
            _TelemetryGrid(telemetry: telemetry!),
          ],
          if (device.createdByUser) ...[
            const SizedBox(height: Insets.lg),
            Row(
              children: [
                Icon(Icons.person_outline_rounded, size: 16, color: p.inkFaint),
                const SizedBox(width: 6),
                Expanded(child: Text(l10n.yourDevice, style: theme.textTheme.bodySmall)),
                TextButton.icon(
                  style: TextButton.styleFrom(textStyle: theme.textTheme.labelLarge),
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  label: Text(l10n.edit),
                ),
                TextButton.icon(
                  onPressed: onDelete,
                  style: TextButton.styleFrom(foregroundColor: p.danger, textStyle: theme.textTheme.labelLarge),
                  icon: const Icon(Icons.delete_outline_rounded, size: 18),
                  label: Text(l10n.delete),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _TelemetryGrid extends StatelessWidget {
  const _TelemetryGrid({required this.telemetry});

  final Telemetry telemetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final readings = [
      (Icons.battery_5_bar_rounded, l10n.batteryLevel, '${telemetry.batteryLevel}%', telemetry.batteryLevel as Object),
      (
        Icons.thermostat_rounded,
        l10n.temperature,
        '${telemetry.temperature.toStringAsFixed(1)} °C',
        telemetry.temperature,
      ),
      (Icons.memory_rounded, l10n.cpuLoad, '${telemetry.cpuLoad}%', telemetry.cpuLoad),
      (Icons.wifi_rounded, l10n.wifiSignal, '${telemetry.wifiSignal} dBm', telemetry.wifiSignal),
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth > 420 ? 4 : 2;
        final width = (constraints.maxWidth - (columns - 1) * Insets.sm) / columns;
        return Wrap(
          spacing: Insets.sm,
          runSpacing: Insets.sm,
          children: [
            for (final (icon, label, text, raw) in readings)
              SizedBox(
                width: width,
                child: FlashOnChange(
                  value: raw,
                  borderRadius: BorderRadius.circular(Corners.input),
                  child: Padding(
                    padding: const EdgeInsets.all(Insets.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(icon, size: 16, color: context.palette.inkFaint),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                label,
                                style: Theme.of(context).textTheme.bodySmall,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(text, style: Theme.of(context).textTheme.titleMedium),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
