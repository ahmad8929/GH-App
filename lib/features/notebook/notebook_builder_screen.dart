import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/format.dart';
import '../../core/models/models.dart';
import '../../core/theme/app_tokens.dart';
import '../../shared/widgets/common.dart';
import '../../state/providers.dart';

final _templatesProvider = FutureProvider<List<NotebookTemplate>>(
    (ref) => ref.watch(notebooksApiProvider).templates());

const _coverColors = [
  (Color(0xFF1E56A0), 'Sky blue'),
  (Color(0xFFFF6F61), 'Coral'),
  (Color(0xFF24B899), 'Mint'),
  (Color(0xFF8B7CF6), 'Lavender'),
  (Color(0xFFFFC93C), 'Sunshine'),
  (Color(0xFF163172), 'Navy'),
];
const _rulings = ['ruled', 'plain', 'grid', 'dotted'];
const _bindings = ['spiral', 'stitched', 'hardbound'];
const _pageOptions = [80, 120, 160, 200];

class NotebookBuilderScreen extends ConsumerStatefulWidget {
  const NotebookBuilderScreen({super.key});

  @override
  ConsumerState<NotebookBuilderScreen> createState() =>
      _NotebookBuilderScreenState();
}

class _NotebookBuilderScreenState
    extends ConsumerState<NotebookBuilderScreen> {
  NotebookTemplate? _template;
  Color _coverColor = _coverColors.first.$1;
  String _ruling = 'ruled';
  String _binding = 'spiral';
  int _pages = 120;
  final _nameController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  double _price(NotebookTemplate? template) {
    var total = template?.basePrice ?? 149;
    total += ((_pages - 80) / 40).clamp(0, 10) * 25;
    if (_binding == 'stitched') total += 20;
    if (_binding == 'hardbound') total += 60;
    if (_nameController.text.trim().isNotEmpty) total += 30;
    return total.roundToDouble();
  }

  @override
  Widget build(BuildContext context) {
    final templatesAsync = ref.watch(_templatesProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Custom Notebook')),
      body: templatesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => ListView(
          padding: const EdgeInsets.all(AppTokens.s4),
          children: const [
            ComingSoonCard(
              emoji: '📒',
              title: 'The notebook studio is warming up',
              body:
                  'Templates are on their way — check back soon to design yours!',
            ),
          ],
        ),
        data: (templates) {
          final template =
              _template ?? (templates.isNotEmpty ? templates.first : null);
          final price = _price(template);
          final name = _nameController.text.trim();

          return ListView(
            padding: const EdgeInsets.all(AppTokens.s4),
            children: [
              // Live preview
              Center(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  width: 200,
                  height: 265,
                  padding: const EdgeInsets.all(AppTokens.s4),
                  decoration: BoxDecoration(
                    color: _coverColor,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(AppTokens.radiusSm),
                      topRight: Radius.circular(AppTokens.radiusLg),
                      bottomRight: Radius.circular(AppTokens.radiusLg),
                      bottomLeft: Radius.circular(AppTokens.radiusSm),
                    ),
                    border: const Border(
                        left: BorderSide(color: Colors.black26, width: 10)),
                    boxShadow: AppTokens.softShadow,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(template?.name ?? 'Classic',
                          style: theme.textTheme.labelSmall
                              ?.copyWith(color: Colors.white70)),
                      Text(
                        name.isEmpty ? 'Your name here' : name,
                        style: theme.textTheme.titleMedium
                            ?.copyWith(color: Colors.white),
                      ),
                      Text('$_pages pages · $_ruling · $_binding',
                          style: theme.textTheme.labelSmall
                              ?.copyWith(color: Colors.white70)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppTokens.s5),
              if (templates.isNotEmpty) ...[
                Text('1 · Template', style: theme.textTheme.titleMedium),
                const SizedBox(height: AppTokens.s2),
                Wrap(
                  spacing: AppTokens.s2,
                  runSpacing: AppTokens.s2,
                  children: templates
                      .map((t) => ChoiceChip(
                            label: Text('${t.name} · ${inr(t.basePrice)}'),
                            selected: template?.id == t.id,
                            onSelected: (_) => setState(() => _template = t),
                          ))
                      .toList(),
                ),
                const SizedBox(height: AppTokens.s4),
              ],
              Text('2 · Cover color', style: theme.textTheme.titleMedium),
              const SizedBox(height: AppTokens.s2),
              Wrap(
                spacing: AppTokens.s2,
                children: _coverColors
                    .map((entry) => GestureDetector(
                          onTap: () => setState(() => _coverColor = entry.$1),
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: entry.$1,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: _coverColor == entry.$1
                                    ? AppTokens.primaryDark
                                    : Colors.transparent,
                                width: 3,
                              ),
                            ),
                            child: _coverColor == entry.$1
                                ? const Icon(Icons.check,
                                    color: Colors.white, size: 18)
                                : null,
                          ),
                        ))
                    .toList(),
              ),
              const SizedBox(height: AppTokens.s4),
              Text('3 · Pages & ruling', style: theme.textTheme.titleMedium),
              const SizedBox(height: AppTokens.s2),
              Wrap(
                spacing: AppTokens.s2,
                children: _pageOptions
                    .map((option) => ChoiceChip(
                          label: Text('$option pages'),
                          selected: _pages == option,
                          onSelected: (_) => setState(() => _pages = option),
                        ))
                    .toList(),
              ),
              const SizedBox(height: AppTokens.s2),
              Wrap(
                spacing: AppTokens.s2,
                children: _rulings
                    .map((option) => ChoiceChip(
                          label: Text(option),
                          selected: _ruling == option,
                          onSelected: (_) => setState(() => _ruling = option),
                        ))
                    .toList(),
              ),
              const SizedBox(height: AppTokens.s4),
              Text('4 · Binding & name', style: theme.textTheme.titleMedium),
              const SizedBox(height: AppTokens.s2),
              Wrap(
                spacing: AppTokens.s2,
                children: _bindings
                    .map((option) => ChoiceChip(
                          label: Text(option),
                          selected: _binding == option,
                          onSelected: (_) =>
                              setState(() => _binding = option),
                        ))
                    .toList(),
              ),
              const SizedBox(height: AppTokens.s3),
              TextField(
                controller: _nameController,
                maxLength: 24,
                decoration: const InputDecoration(
                    labelText: 'Name on cover (+₹30)',
                    hintText: "e.g. Aarav's Science Notes"),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: AppTokens.s3),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppTokens.s4),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Your notebook',
                              style: theme.textTheme.titleMedium),
                          Text(inr(price),
                              style: theme.textTheme.headlineSmall
                                  ?.copyWith(color: AppTokens.primary)),
                        ],
                      ),
                      const SizedBox(height: AppTokens.s3),
                      // Backend has no notebook order-to-cart endpoint yet —
                      // don't fake it.
                      const FilledButton(
                          onPressed: null,
                          child: Text('Add to cart — coming soon')),
                      const SizedBox(height: AppTokens.s2),
                      Text(
                        'Made-to-order checkout is almost ready. Your design and price preview are live!',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppTokens.s4),
            ],
          );
        },
      ),
    );
  }
}
