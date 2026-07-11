import 'package:flutter/material.dart';

import '../../core/theme/app_tokens.dart';

/// Dark circular − / + stepper with the count between, per the redesign.
/// Decrementing below [min] fires [onChanged] with min−1 (callers treat it as
/// remove) when [removableBelowMin] is set, otherwise clamps at [min].
/// Tapping the number opens a dialog to type an exact quantity — nobody
/// should have to tap + a hundred times to get from 50 to 150.
class QuantityStepper extends StatelessWidget {
  final int value;
  final int min;
  final int? max;
  final bool removableBelowMin;
  final ValueChanged<int> onChanged;

  const QuantityStepper({
    super.key,
    required this.value,
    required this.onChanged,
    this.min = 1,
    this.max,
    this.removableBelowMin = false,
  });

  Future<void> _typeExact(BuildContext context) async {
    final controller = TextEditingController(text: '$value');
    final typed = await showDialog<int>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Quantity'),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            helperText:
                'Minimum $min${max != null ? ' · up to $max' : ''}',
          ),
          onSubmitted: (text) =>
              Navigator.of(dialogContext).pop(int.tryParse(text.trim())),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext)
                .pop(int.tryParse(controller.text.trim())),
            child: const Text('Set'),
          ),
        ],
      ),
    );
    if (typed == null) return;
    onChanged(typed.clamp(min, max ?? 1 << 30));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final canDecrement = value > min || removableBelowMin;
    final canIncrement = max == null || value < max!;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _RoundButton(
          icon: Icons.remove_rounded,
          enabled: canDecrement,
          // At min with removableBelowMin, emit 0 so the caller removes the line.
          onTap: () => onChanged(value > min ? value - 1 : 0),
        ),
        InkWell(
          borderRadius: AppTokens.brSm,
          onTap: () => _typeExact(context),
          child: Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: AppTokens.s3, vertical: AppTokens.s1),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('$value',
                    style: theme.textTheme.titleMedium
                        ?.copyWith(color: AppTokens.ink)),
                Text('edit',
                    style: theme.textTheme.labelSmall?.copyWith(
                        color: AppTokens.inkSoft, fontSize: 9, height: 1)),
              ],
            ),
          ),
        ),
        _RoundButton(
          icon: Icons.add_rounded,
          enabled: canIncrement,
          onTap: () => onChanged(value + 1),
        ),
      ],
    );
  }
}

class _RoundButton extends StatelessWidget {
  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  const _RoundButton(
      {required this.icon, required this.enabled, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: enabled ? AppTokens.ink : AppTokens.tint,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: enabled ? onTap : null,
        child: SizedBox(
          width: 32,
          height: 32,
          child: Icon(icon,
              size: 18, color: enabled ? Colors.white : AppTokens.inkSoft),
        ),
      ),
    );
  }
}
