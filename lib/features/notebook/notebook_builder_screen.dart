import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/format.dart';
import '../../core/models/models.dart';
import '../../core/theme/app_tokens.dart';
import '../../shared/widgets/common.dart';
import '../../state/auth_state.dart';
import '../../state/providers.dart';
import 'cover_designer.dart';
import 'notebook_3d_view.dart';

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

  final _designerKey = GlobalKey<CoverDesignerState>();
  final List<CoverLayer> _layers = [];
  int _tab = 0; // 0 = design, 1 = 3D preview
  Uint8List? _coverArtPng;
  bool _submitting = false;

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
    total += _layers.length * 20; // photo print charge per photo
    return total.roundToDouble();
  }

  Future<void> _openPreview() async {
    final png = await _designerKey.currentState?.capturePng();
    setState(() {
      _coverArtPng = png;
      _tab = 1;
    });
  }

  Future<void> _order(NotebookTemplate? template, double price) async {
    final auth = ref.read(authControllerProvider);
    if (!auth.isSignedIn) {
      context.push('/login?next=/notebook');
      return;
    }
    final delivery = await _askDelivery();
    if (delivery == null || !mounted) return;

    setState(() => _submitting = true);
    try {
      final png =
          _coverArtPng ?? await _designerKey.currentState?.capturePng();
      await ref.read(notebooksApiProvider).submitOrder(
            templateId: template?.id,
            coverColor:
                '#${(_coverColor.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0')}',
            ruling: _ruling,
            binding: _binding,
            pages: _pages,
            nameOnCover: _nameController.text.trim(),
            price: price,
            designLayers: _layers.map((l) => l.toJson()).toList(),
            photos: _layers.map((l) => l.bytes).toList(),
            previewPng: png,
            contactName: delivery.$1,
            contactPhone: delivery.$2,
            address: delivery.$3,
            city: delivery.$4,
          );
      if (mounted) {
        showSuccess(context, 'Order placed! We\'ll start printing soon.');
        context.pop();
      }
    } catch (err) {
      if (mounted) showError(context, err);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  /// Collects (name, phone, address, city); null when dismissed.
  Future<(String, String, String, String)?> _askDelivery() {
    final name = TextEditingController(
        text: ref.read(authControllerProvider).user?.name ?? '');
    final phone = TextEditingController();
    final address = TextEditingController();
    final city = TextEditingController();
    return showModalBottomSheet<(String, String, String, String)>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.only(
          left: AppTokens.s4,
          right: AppTokens.s4,
          top: AppTokens.s4,
          bottom:
              MediaQuery.of(sheetContext).viewInsets.bottom + AppTokens.s4,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Deliver to',
                style: Theme.of(sheetContext).textTheme.titleLarge),
            const SizedBox(height: AppTokens.s3),
            TextField(
                controller: name,
                decoration: const InputDecoration(labelText: 'Name')),
            const SizedBox(height: AppTokens.s2),
            TextField(
                controller: phone,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: 'Phone')),
            const SizedBox(height: AppTokens.s2),
            TextField(
                controller: address,
                decoration: const InputDecoration(labelText: 'Address')),
            const SizedBox(height: AppTokens.s2),
            TextField(
                controller: city,
                decoration: const InputDecoration(labelText: 'City')),
            const SizedBox(height: AppTokens.s4),
            FilledButton(
              style: FilledButton.styleFrom(
                  backgroundColor: AppTokens.gold,
                  foregroundColor: AppTokens.ink,
                  minimumSize: const Size.fromHeight(54)),
              onPressed: () {
                if (phone.text.trim().isEmpty ||
                    address.text.trim().isEmpty ||
                    city.text.trim().isEmpty) {
                  return; // required fields
                }
                Navigator.of(sheetContext).pop((
                  name.text.trim(),
                  phone.text.trim(),
                  address.text.trim(),
                  city.text.trim(),
                ));
              },
              child: const Text('Confirm order'),
            ),
          ],
        ),
      ),
    );
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

          return ListView(
            padding: const EdgeInsets.all(AppTokens.s4),
            children: [
              // Design ⟷ 3D preview switch
              Row(
                children: [
                  Expanded(
                    child: _TabPill(
                      label: '🎨 Design',
                      selected: _tab == 0,
                      onTap: () => setState(() => _tab = 0),
                    ),
                  ),
                  const SizedBox(width: AppTokens.s2),
                  Expanded(
                    child: _TabPill(
                      label: '🧊 3D · 360°',
                      selected: _tab == 1,
                      onTap: _openPreview,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppTokens.s4),
              if (_tab == 0) ...[
                Center(
                  child: SizedBox(
                    width: 260 * AppTokens.scale,
                    child: CoverDesigner(
                      key: _designerKey,
                      background: _coverColor,
                      name: _nameController.text.trim(),
                      badge: template?.name ?? 'Classic',
                      layers: _layers,
                      onChanged: () => setState(() {}),
                    ),
                  ),
                ),
                const SizedBox(height: AppTokens.s3),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    OutlinedButton.icon(
                      onPressed: () async {
                        await _designerKey.currentState?.addPhoto();
                        setState(() {});
                      },
                      icon: const Icon(Icons.add_photo_alternate_outlined),
                      label: const Text('Add photo'),
                    ),
                    const SizedBox(width: AppTokens.s2),
                    if (_designerKey.currentState?.hasSelection == true)
                      OutlinedButton.icon(
                        onPressed: () {
                          _designerKey.currentState?.removeSelected();
                          setState(() {});
                        },
                        icon: const Icon(Icons.delete_outline),
                        label: const Text('Remove'),
                      ),
                  ],
                ),
                Center(
                  child: Text(
                    'Tap a photo to select · drag to move · pinch to resize & rotate',
                    style: theme.textTheme.labelSmall
                        ?.copyWith(color: AppTokens.inkSoft),
                    textAlign: TextAlign.center,
                  ),
                ),
              ] else
                SizedBox(
                  height: 380 * AppTokens.scale,
                  child: Notebook3DView(
                    coverColor: _coverColor,
                    showSpiral: _binding == 'spiral',
                    coverArtPng: _coverArtPng,
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
                            width: 40 * AppTokens.scale,
                            height: 40 * AppTokens.scale,
                            decoration: BoxDecoration(
                              color: entry.$1,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: _coverColor == entry.$1
                                    ? AppTokens.ink
                                    : Colors.transparent,
                                width: 3,
                              ),
                            ),
                            child: _coverColor == entry.$1
                                ? const Icon(Icons.check,
                                    color: Colors.white, size: 18 * AppTokens.scale)
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
                          label: Text(option == 'spiral' ? '🌀 spiral' : option),
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
                                  ?.copyWith(color: AppTokens.ink)),
                        ],
                      ),
                      if (_layers.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: AppTokens.s1),
                          child: Text(
                            '${_layers.length} photo${_layers.length == 1 ? '' : 's'} on the cover · ₹20 each',
                            style: theme.textTheme.labelSmall
                                ?.copyWith(color: AppTokens.inkSoft),
                          ),
                        ),
                      const SizedBox(height: AppTokens.s3),
                      FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: AppTokens.gold,
                          foregroundColor: AppTokens.ink,
                          minimumSize: const Size.fromHeight(54),
                        ),
                        onPressed: _submitting
                            ? null
                            : () => _order(template, price),
                        icon: const Icon(Icons.auto_awesome),
                        label: Text(_submitting
                            ? 'Placing order…'
                            : 'Order this notebook'),
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

class _TabPill extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _TabPill(
      {required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppTokens.ink : AppTokens.surface,
      shape: const StadiumBorder(),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppTokens.s3),
          child: Center(
            child: Text(
              label,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: selected ? Colors.white : AppTokens.ink),
            ),
          ),
        ),
      ),
    );
  }
}
