import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/models.dart';
import '../../core/theme/app_tokens.dart';
import '../../shared/widgets/common.dart';
import '../../state/providers.dart';
import '../../state/theme_state.dart';

final _themesListProvider =
    FutureProvider.autoDispose<List<ThemeOption>>((ref) async {
  final res = await ref.watch(themesApiProvider).list();
  return res;
});

/// Lets a signed-in user pick a color theme for their own Gyaan Hub app —
/// stored on their profile via `PATCH /profile/me/theme`, re-applied on
/// every device. Mirrors the Website's `/dashboard/theme` page.
class ThemeScreen extends ConsumerStatefulWidget {
  const ThemeScreen({super.key});

  @override
  ConsumerState<ThemeScreen> createState() => _ThemeScreenState();
}

class _ThemeScreenState extends ConsumerState<ThemeScreen> {
  String? _busyId;

  Future<void> _apply(String? themeId) async {
    setState(() => _busyId = themeId ?? 'default');
    try {
      await ref.read(profileApiProvider).selectTheme(themeId);
      ref.invalidate(selectedThemeProvider);
      if (mounted) {
        showSuccess(context, themeId == null ? 'Reset to default look' : 'Theme applied');
      }
    } catch (err) {
      if (mounted) showError(context, err);
    } finally {
      if (mounted) setState(() => _busyId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final themes = ref.watch(_themesListProvider);
    final selected = ref.watch(selectedThemeProvider).asData?.value;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Theme'),
        actions: [
          TextButton(
            onPressed: selected == null || _busyId != null
                ? null
                : () => _apply(null),
            child: _busyId == 'default'
                ? const SizedBox(
                    width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Use default'),
          ),
        ],
      ),
      body: themes.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => EmptyState(
            emoji: '😵', title: "Couldn't load themes", body: err.toString()),
        data: (items) => items.isEmpty
            ? const EmptyState(
                emoji: '🎨',
                title: 'No themes available yet',
                body: 'Check back soon for new looks.')
            : RefreshIndicator(
                onRefresh: () async => ref.invalidate(_themesListProvider),
                child: ListView.separated(
                  padding: const EdgeInsets.all(AppTokens.s4),
                  itemCount: items.length,
                  separatorBuilder: (_, _) => const SizedBox(height: AppTokens.s4),
                  itemBuilder: (context, index) {
                    final theme = items[index];
                    final isSelected = selected?.id == theme.id;
                    final busy = _busyId == theme.id;
                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(AppTokens.s3),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(theme.name,
                                style: Theme.of(context).textTheme.titleMedium),
                            const SizedBox(height: AppTokens.s2),
                            _ThemePreview(theme: theme),
                            const SizedBox(height: AppTokens.s3),
                            SizedBox(
                              width: double.infinity,
                              child: isSelected
                                  ? const OutlinedButton(
                                      onPressed: null, child: Text('Selected'))
                                  : FilledButton(
                                      onPressed: _busyId != null
                                          ? null
                                          : () => _apply(theme.id),
                                      child: busy
                                          ? const SizedBox(
                                              width: 18,
                                              height: 18,
                                              child: CircularProgressIndicator(
                                                  strokeWidth: 2, color: Colors.white))
                                          : const Text('Apply theme'),
                                    ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
      ),
    );
  }
}

class _ThemePreview extends StatelessWidget {
  final ThemeOption theme;
  const _ThemePreview({required this.theme});

  @override
  Widget build(BuildContext context) {
    final border = AppTokens.hexToColor(theme.borderColor);
    return ClipRRect(
      borderRadius: AppTokens.brMd,
      child: Container(
        decoration: BoxDecoration(border: Border.all(color: border)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                  horizontal: AppTokens.s3, vertical: AppTokens.s2),
              color: AppTokens.hexToColor(theme.navbarColor),
              child: Text('Gyaan Hub',
                  style: TextStyle(
                      color: AppTokens.hexToColor(theme.headingColor),
                      fontWeight: FontWeight.w700,
                      fontSize: 13)),
            ),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppTokens.s3),
              color: AppTokens.hexToColor(theme.backgroundColor),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Sample heading',
                      style: TextStyle(
                          color: AppTokens.hexToColor(theme.headingColor),
                          fontWeight: FontWeight.w700,
                          fontSize: 15)),
                  const SizedBox(height: AppTokens.s1),
                  Text('This is how body text will look.',
                      style: TextStyle(
                          color: AppTokens.hexToColor(theme.textColor), fontSize: 12)),
                  const SizedBox(height: AppTokens.s2),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppTokens.s3, vertical: AppTokens.s1),
                    decoration: BoxDecoration(
                      color: AppTokens.hexToColor(theme.buttonBackground),
                      borderRadius: AppTokens.brSm,
                    ),
                    child: Text('Sample button',
                        style: TextStyle(
                            color: AppTokens.hexToColor(theme.buttonText),
                            fontSize: 12,
                            fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                  horizontal: AppTokens.s3, vertical: AppTokens.s1),
              color: AppTokens.hexToColor(theme.footerColor),
              child: const Text('Footer',
                  style: TextStyle(color: Colors.white, fontSize: 11)),
            ),
          ],
        ),
      ),
    );
  }
}
