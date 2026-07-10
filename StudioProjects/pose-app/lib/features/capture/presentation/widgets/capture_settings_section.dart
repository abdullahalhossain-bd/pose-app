import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../capture/config/capture_config.dart';
import '../../../capture/presentation/providers/capture_providers.dart';
import '../../../capture/storage/capture_prefs.dart';
import '../../../../shared/widgets/widgets.dart';

/// সেটিংস স্ক্রিনের জন্য একটি রিইউজেবল সেকশন যা সমস্ত অটো-ক্যাপচার
/// প্রিফারেন্স প্রকাশ করে। মূল সেটিংস স্ক্রিন দ্বারা এম্বেড করা হয়েছে।
class CaptureSettingsSection extends ConsumerWidget {
  const CaptureSettingsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefs = ref.watch(capturePrefsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8, left: 4),
          child: Text(
            'SMART CAPTURE',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ),
        AppCard(
          child: Column(
            children: [
              SwitchListTile(
                value: prefs.autoCaptureEnabled,
                onChanged: (v) =>
                    ref.read(capturePrefsProvider.notifier).toggleAutoCapture(v),
                title: const Text('Auto Capture'),
                subtitle: const Text(
                    'AI captures the photo at the perfect moment'),
                contentPadding: EdgeInsets.zero,
              ),
              AnimatedCrossFade(
                duration: const Duration(milliseconds: 200),
                crossFadeState: prefs.autoCaptureEnabled
                    ? CrossFadeState.showSecond
                    : CrossFadeState.showFirst,
                firstChild: const SizedBox.shrink(),
                secondChild: Column(
                  children: [
                    const Divider(),
                    ListTile(
                      title: const Text('Countdown'),
                      subtitle: Text('${prefs.countdownSeconds}s'),
                      trailing: SizedBox(
                        width: 200,
                        child: Slider(
                          value: prefs.countdownSeconds.toDouble(),
                          min: 0,
                          max: 10,
                          divisions: 10,
                          label: '${prefs.countdownSeconds}s',
                          onChanged: (v) => ref
                              .read(capturePrefsProvider.notifier)
                              .setCountdownSeconds(v.round()),
                        ),
                      ),
                    ),
                    const Divider(),
                    ListTile(
                      title: const Text('Sensitivity'),
                      subtitle: Text(_sensitivityLabel(prefs.sensitivity)),
                      trailing: SegmentedButton<CaptureSensitivity>(
                        segments: const [
                          ButtonSegment(
                              value: CaptureSensitivity.conservative,
                              label: Text('Safe')),
                          ButtonSegment(
                              value: CaptureSensitivity.balanced,
                              label: Text('Balanced')),
                          ButtonSegment(
                              value: CaptureSensitivity.eager,
                              label: Text('Eager')),
                        ],
                        selected: {prefs.sensitivity},
                        onSelectionChanged: (s) => ref
                            .read(capturePrefsProvider.notifier)
                            .setSensitivity(s.first),
                      ),
                    ),
                    const Divider(),
                    SwitchListTile(
                      value: prefs.voicePromptsEnabled,
                      onChanged: (v) => ref
                          .read(capturePrefsProvider.notifier)
                          .setVoicePrompts(v),
                      title: const Text('Voice prompts'),
                      subtitle: const Text('Spoken countdown + capture cue'),
                      contentPadding: EdgeInsets.zero,
                    ),
                    SwitchListTile(
                      value: prefs.vibrationEnabled,
                      onChanged: (v) => ref
                          .read(capturePrefsProvider.notifier)
                          .setVibration(v),
                      title: const Text('Vibration'),
                      subtitle: const Text('Haptic feedback on capture'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _sensitivityLabel(CaptureSensitivity s) => switch (s) {
        CaptureSensitivity.conservative =>
          'Fewer captures, higher quality bar',
        CaptureSensitivity.balanced => 'Recommended for most situations',
        CaptureSensitivity.eager => 'More captures, accepts lower quality',
      };
}
