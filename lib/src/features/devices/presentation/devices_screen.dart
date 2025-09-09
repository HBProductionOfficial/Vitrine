import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vitrine/l10n/gen/app_localizations.dart';

import '../../../core/design/tokens.dart';
import '../../../core/errors.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/widgets/feedback.dart';
import '../../../core/widgets/notice.dart';
import '../../../core/widgets/page_body.dart';
import '../../../core/widgets/skeleton.dart';
import '../../../core/widgets/state_views.dart';
import '../domain/device.dart';
import 'devices_controller.dart';
import 'widgets/device_form_sheet.dart';
import 'widgets/device_tile.dart';

class DevicesScreen extends ConsumerStatefulWidget {
  const DevicesScreen({super.key});

  @override
  ConsumerState<DevicesScreen> createState() => _DevicesScreenState();
}

class _DevicesScreenState extends ConsumerState<DevicesScreen> {
  final _tileKeys = <String, GlobalKey>{};
  final _scroll = ScrollController();

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  GlobalKey _keyFor(String id) => _tileKeys.putIfAbsent(id, GlobalKey.new);

  Future<void> _toggle(String id) async {
    final controller = ref.read(devicesControllerProvider.notifier);
    controller.toggle(id);
    if (ref.read(devicesControllerProvider).expandedId != id) return;

    // Wait for the expand animation so we measure the final height.
    await Future<void>.delayed(Motion.base + const Duration(milliseconds: 40));
    await _bringIntoView(id);
  }

  /// New devices are appended at the end, usually below the fold. The row
  /// isn't built yet, so scroll to the end first and then line it up.
  Future<void> _revealNew() async {
    final id = ref.read(devicesControllerProvider).expandedId;
    await Future<void>.delayed(Motion.base + const Duration(milliseconds: 40));
    if (id == null || !_scroll.hasClients) return;
    await _scroll.animateTo(_scroll.position.maxScrollExtent, duration: Motion.slow, curve: Motion.move);
    await _bringIntoView(id);
  }

  Future<void> _bringIntoView(String id) async {
    final tile = _tileKeys[id]?.currentContext;
    if (tile == null || !tile.mounted) return;
    await Scrollable.ensureVisible(
      tile,
      duration: Motion.slow,
      curve: Motion.move,
      alignmentPolicy: ScrollPositionAlignmentPolicy.keepVisibleAtEnd,
    );
    // Taller than the screen: bring the top back into view instead.
    if (tile.mounted) {
      await Scrollable.ensureVisible(
        tile,
        duration: Motion.slow,
        curve: Motion.move,
        alignmentPolicy: ScrollPositionAlignmentPolicy.keepVisibleAtStart,
      );
    }
  }

  Future<void> _openForm({Device? device}) async {
    final l10n = AppLocalizations.of(context);
    final controller = ref.read(devicesControllerProvider.notifier);
    final saved = await showAppSheet<bool>(
      context,
      builder: (_) => DeviceFormSheet(
        device: device,
        onSubmit: (name, data) =>
            device == null ? controller.create(name, data) : controller.save(device.id, name, data),
      ),
    );
    if (!(saved ?? false) || !mounted) return;
    showSnack(context, l10n.deviceSaved);
    if (device == null) await _revealNew();
  }

  Future<void> _delete(Device device) async {
    final l10n = AppLocalizations.of(context);
    final ok = await confirm(
      context,
      title: l10n.deleteDeviceTitle(device.name),
      message: l10n.deleteDeviceBody,
      confirmLabel: l10n.delete,
      destructive: true,
    );
    if (!ok || !mounted) return;
    try {
      await ref.read(devicesControllerProvider.notifier).delete(device.id);
      if (mounted) showSnack(context, l10n.deviceDeleted);
    } catch (e) {
      if (!mounted) return;
      final readOnly = e is ApiException && e.kind == ApiErrorKind.forbidden;
      showSnack(context, readOnly ? l10n.deviceReadOnly : describeError(e, l10n));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(devicesControllerProvider);
    final controller = ref.read(devicesControllerProvider.notifier);

    final Widget body;
    if (state.loading && state.devices.isEmpty) {
      body = const _LoadingList();
    } else if (state.error != null && state.devices.isEmpty) {
      body = ErrorView(message: describeError(state.error!, l10n), onRetry: controller.load);
    } else if (state.devices.isEmpty) {
      body = MessageView(
        icon: Icons.devices_other_outlined,
        title: l10n.devicesEmptyTitle,
        message: l10n.devicesEmptyBody,
      );
    } else {
      body = RefreshIndicator(
        onRefresh: controller.load,
        child: ListView.separated(
          controller: _scroll,
          padding: const EdgeInsets.fromLTRB(Insets.page, Insets.sm, Insets.page, Insets.xl),
          itemCount: state.devices.length + (state.fromCache ? 1 : 0),
          separatorBuilder: (_, _) => const SizedBox(height: Insets.sm),
          itemBuilder: (context, index) {
            if (state.fromCache && index == 0) {
              return Notice(message: l10n.showingSavedList, tone: NoticeTone.info);
            }
            final device = state.devices[index - (state.fromCache ? 1 : 0)];
            return DeviceTile(
              key: _keyFor(device.id),
              device: device,
              expanded: state.expandedId == device.id,
              updated: state.unseen.contains(device.id),
              telemetry: state.telemetry[device.id],
              onToggle: () => _toggle(device.id),
              onEdit: () => _openForm(device: device),
              onDelete: () => _delete(device),
            );
          },
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.devicesTitle),
            Text(l10n.devicesSubtitle, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
        actions: [
          // In the app bar rather than a FAB, which would sit on top of the
          // expanded row that auto-scroll just brought into view.
          Padding(
            padding: const EdgeInsets.only(right: Insets.sm),
            child: TextButton.icon(
              style: TextButton.styleFrom(textStyle: Theme.of(context).textTheme.labelLarge),
              onPressed: () => _openForm(),
              icon: const Icon(Icons.add_rounded, size: 20),
              label: Text(l10n.addDevice),
            ),
          ),
        ],
      ),
      body: PageBody(maxWidth: 760, child: body),
    );
  }
}

class _LoadingList extends StatelessWidget {
  const _LoadingList();

  @override
  Widget build(BuildContext context) {
    return Shimmer(
      child: ListView.separated(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(Insets.page, Insets.sm, Insets.page, Insets.sm),
        itemCount: 8,
        separatorBuilder: (_, _) => const SizedBox(height: Insets.sm),
        itemBuilder: (_, i) => Container(
          height: 60,
          padding: const EdgeInsets.symmetric(horizontal: Insets.lg),
          child: Row(
            children: [
              const SkeletonBox(width: 44, height: 22),
              const SizedBox(width: Insets.md),
              SkeletonBox(width: 120.0 + (i % 3) * 50),
            ],
          ),
        ),
      ),
    );
  }
}
