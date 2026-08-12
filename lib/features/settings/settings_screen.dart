import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router.dart';
import '../../core/state/providers.dart';
import '../../core/prefs/app_preferences.dart';
import '../../domain/models/user_profile.dart';
import 'data_port.dart';

/// App settings: appearance, region, daily reminder, privacy and data
/// management (export / import / delete).
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  String? _importError;

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(profileProvider).value;
    final themePref = ref.watch(themePreferenceProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: profile == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                ..._section(context, 'Appearance', [
                  _appearanceTile(context, themePref),
                ]),
                ..._section(context, 'Personalization', [
                  _regionTile(profile),
                  _reminderTile(profile),
                ]),
                ..._section(context, 'Privacy', [
                  ListTile(
                    leading: const Icon(Icons.shield_outlined),
                    title: const Text('Privacy policy'),
                    subtitle: const Text('What we do with your data'),
                    onTap: () => context.pushNamed(AppRoutes.privacy),
                  ),
                  ListTile(
                    leading: const Icon(Icons.info_outline),
                    title: const Text('About EcoAction'),
                    subtitle: const Text('Version and credits'),
                    onTap: () => context.pushNamed(AppRoutes.about),
                  ),
                  ListTile(
                    leading: const Icon(Icons.functions),
                    title: const Text('How we estimate'),
                    subtitle: const Text('Where the numbers come from'),
                    onTap: () => context.pushNamed(AppRoutes.methodology),
                  ),
                ]),
                ..._section(
                  context,
                  'Data management',
                  _dataTiles(context),
                ),
              ],
            ),
    );
  }

  List<Widget> _section(BuildContext context, String title, List<Widget> rows) {
    return [
      Padding(
        padding: const EdgeInsets.only(top: 16, bottom: 4),
        child: Text(title, style: Theme.of(context).textTheme.labelLarge),
      ),
      Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Column(children: rows)),
    ];
  }

  Widget _appearanceTile(BuildContext context, AppearancePreference themePref) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.brightness_6, color: scheme.primary),
              const SizedBox(width: 12),
              Text(
                'Theme',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: SegmentedButton<AppearancePreference>(
              segments: const [
                ButtonSegment(
                  value: AppearancePreference.system,
                  icon: Icon(Icons.brightness_auto),
                  label: Text('System'),
                ),
                ButtonSegment(
                  value: AppearancePreference.light,
                  icon: Icon(Icons.light_mode),
                  label: Text('Light'),
                ),
                ButtonSegment(
                  value: AppearancePreference.dark,
                  icon: Icon(Icons.dark_mode),
                  label: Text('Dark'),
                ),
              ],
              selected: {themePref},
              showSelectedIcon: false,
              onSelectionChanged: (selection) {
                ref
                    .read(themePreferenceProvider.notifier)
                    .setAppearance(selection.first);
              },
            ),
          ),
        ],
      ),
    );
  }

  ListTile _regionTile(UserProfile profile) {
    return ListTile(
      leading: const Icon(Icons.public),
      title: const Text('Region'),
      subtitle: Text(profile.region == 'in'
          ? 'India — regional emission factors'
          : 'Global — international factors'),
      trailing: PopupMenuButton<String>(
        initialValue: profile.region,
        onSelected: (value) {
          final updated = UserProfile(
            region: value,
            transportBaseline: profile.transportBaseline,
            dailyCommuteKm: profile.dailyCommuteKm,
            interests: profile.interests,
            habits: profile.habits,
            onboarded: profile.onboarded,
            reminderMinutesFromMidnight: profile.reminderMinutesFromMidnight,
          );
          ref.read(profileProvider.notifier).save(updated);
        },
        itemBuilder: (context) => const [
          PopupMenuItem(value: 'in', child: Text('India')),
          PopupMenuItem(value: 'global', child: Text('Global')),
        ],
      ),
    );
  }

  SwitchListTile _reminderTile(UserProfile profile) {
    final enabled = profile.reminderMinutesFromMidnight != null;
    return SwitchListTile(
      secondary: const Icon(Icons.notifications),
      title: const Text('Daily action reminder'),
      subtitle: Text(enabled
          ? 'Every day at ${_formatReminder(profile.reminderMinutesFromMidnight!)}'
          : 'Off'),
      value: enabled,
      onChanged: (value) {
        if (value) {
          _pickReminderTime(profile);
        } else {
          _toggleReminder(profile, null);
        }
      },
    );
  }

  Future<void> _pickReminderTime(UserProfile profile) async {
    final now = TimeOfDay.now();
    final picked = await showTimePicker(context: context, initialTime: now);
    if (picked != null) {
      _toggleReminder(profile, picked);
    }
  }

  Future<void> _toggleReminder(UserProfile profile, TimeOfDay? time) async {
    final minutes = time == null ? null : time.hour * 60 + time.minute;
    final updated = UserProfile(
      region: profile.region,
      transportBaseline: profile.transportBaseline,
      dailyCommuteKm: profile.dailyCommuteKm,
      interests: profile.interests,
      habits: profile.habits,
      onboarded: profile.onboarded,
      reminderMinutesFromMidnight: minutes,
    );
    await ref.read(profileProvider.notifier).save(updated);

    final scheduler = await ref.read(reminderSchedulerProvider.future);
    if (time == null) {
      await scheduler.cancelAll();
    } else {
      await scheduler.scheduleDaily(
        hourOfDay: time.hour,
        minute: time.minute,
        title: 'Daily action reminder',
        body: 'Small actions add up. Log one today.',
      );
    }
  }

  String _formatReminder(int minutes) {
    final h = minutes ~/ 60;
    final m = minutes % 60;
    final period = h >= 12 ? 'PM' : 'AM';
    final hour12 = h % 12 == 0 ? 12 : h % 12;
    return '${hour12.toString().padLeft(2, '0')}:'
        '${m.toString().padLeft(2, '0')} $period';
  }

  List<Widget> _dataTiles(BuildContext context) {
    const actions = [
      _DataAction(
        icon: Icons.file_download_outlined,
        type: _DataActionType.export,
        label: 'Export my data',
      ),
      _DataAction(
        icon: Icons.file_upload_outlined,
        type: _DataActionType.import,
        label: 'Import a backup',
      ),
      _DataAction(
        icon: Icons.delete_outline,
        type: _DataActionType.delete,
        label: 'Delete all data',
      ),
    ];
    return [
      for (final action in actions)
        ListTile(
          leading: Icon(
            action.icon,
            color: action.type == _DataActionType.delete
                ? Theme.of(context).colorScheme.error
                : null,
          ),
          title: Text(
            action.label,
            style: action.type == _DataActionType.delete
                ? TextStyle(color: Theme.of(context).colorScheme.error)
                : null,
          ),
          onTap: () => _onDataAction(action.type),
        ),
      if (_importError != null)
        Padding(
          padding: const EdgeInsets.all(12),
          child: Text(
            _importError!,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ),
    ];
  }

  Future<void> _onDataAction(_DataActionType type) async {
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    final port = await ref.read(dataPortProvider.future);
    switch (type) {
      case _DataActionType.export:
        final payload = await port.exportAll();
        final json = DataPortService.encode(payload);
        await Clipboard.setData(ClipboardData(text: json));
        messenger.showSnackBar(
            const SnackBar(content: Text('Backup JSON copied to clipboard.')));
      case _DataActionType.import:
        final text = await _promptForJson();
        if (text == null) return;
        try {
          final payload = BackupPayload.fromJson(DataPortService.decode(text));
          final problems = port.validate(payload);
          if (problems.isNotEmpty) {
            setState(() => _importError = problems.join('\n'));
            return;
          }
          await port.import(payload);
          ref.invalidate(profileProvider);
          ref.invalidate(dashboardStatsProvider);
          ref.invalidate(challengesProvider);
          ref.invalidate(impactProvider);
          setState(() => _importError = null);
          messenger
              .showSnackBar(const SnackBar(content: Text('Backup restored.')));
        } on FormatException {
          setState(() => _importError = 'Invalid backup JSON.');
        } catch (e) {
          setState(() => _importError = 'Import failed: $e');
        }
      case _DataActionType.delete:
        final ok = await _confirmDelete();
        if (ok) {
          await port.wipeAll();
          ref.invalidate(profileProvider);
          ref.invalidate(dashboardStatsProvider);
          ref.invalidate(challengesProvider);
          ref.invalidate(impactProvider);
          if (mounted) {
            messenger.showSnackBar(
                const SnackBar(content: Text('All data deleted.')));
          }
        }
    }
  }

  Future<String?> _promptForJson() {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Import backup'),
        content: TextField(
          controller: controller,
          maxLines: 6,
          decoration: const InputDecoration(
            hintText: 'Paste backup JSON here',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Import'),
          ),
        ],
      ),
    );
  }

  Future<bool> _confirmDelete() {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete all data?'),
        content: const Text('This removes your profile, diary, badges and '
            'challenge progress from this device. This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    ).then((value) => value ?? false);
  }
}

enum _DataActionType { export, import, delete }

class _DataAction {
  const _DataAction({
    required this.icon,
    required this.type,
    required this.label,
  });

  final IconData icon;
  final _DataActionType type;
  final String label;
}
