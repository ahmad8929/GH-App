import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/format.dart';
import '../../core/models/models.dart';
import '../../core/theme/app_tokens.dart';
import '../../shared/widgets/common.dart';
import '../../shared/widgets/listing_card.dart';
import '../../state/providers.dart';

class ShopScreen extends ConsumerStatefulWidget {
  final String? initialCategorySlug;
  final String? initialSearch;

  const ShopScreen({super.key, this.initialCategorySlug, this.initialSearch});

  @override
  ConsumerState<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends ConsumerState<ShopScreen> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  Timer? _debounce;

  String? _pendingCategorySlug;
  String? _categoryId;
  String _search = '';
  String _condition = '';
  String _listingType = '';
  String _sort = 'newest';
  double? _minPrice;
  double? _maxPrice;

  final List<Listing> _items = [];
  Pagination _pagination = Pagination.empty;
  bool _loading = false;
  bool _initialLoaded = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _pendingCategorySlug = widget.initialCategorySlug;
    _search = widget.initialSearch ?? '';
    _searchController.text = _search;
    _scrollController.addListener(_onScroll);
    _load(reset: true);
  }

  @override
  void didUpdateWidget(ShopScreen old) {
    super.didUpdateWidget(old);
    // Category deep-links from Home while the tab is alive.
    if (widget.initialCategorySlug != old.initialCategorySlug &&
        widget.initialCategorySlug != null) {
      _pendingCategorySlug = widget.initialCategorySlug;
      _categoryId = null;
      _load(reset: true);
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >
            _scrollController.position.maxScrollExtent - 400 &&
        !_loading &&
        _pagination.hasNext) {
      _load();
    }
  }

  Future<void> _resolvePendingCategory() async {
    final slug = _pendingCategorySlug;
    if (slug == null) return;
    _pendingCategorySlug = null;
    final options = await ref.read(categoryOptionsProvider.future);
    final shop = shopCategories.where((c) => c.slug == slug).firstOrNull;
    if (shop != null) {
      _categoryId = matchCategory(options, shop)?.id;
    }
  }

  Future<void> _load({bool reset = false}) async {
    if (_loading) return;
    setState(() {
      _loading = true;
      _error = null;
      if (reset) {
        _items.clear();
        _pagination = Pagination.empty;
      }
    });
    try {
      await _resolvePendingCategory();
      final page = reset ? 1 : _pagination.page + 1;
      final res = await ref.read(listingsApiProvider).list(
            search: _search,
            categoryId: _categoryId,
            condition: _condition,
            listingType: _listingType,
            minPrice: _minPrice,
            maxPrice: _maxPrice,
            sort: _sort,
            page: page,
            limit: 12,
          );
      setState(() {
        _items.addAll(res.data);
        _pagination = res.pagination;
        _initialLoaded = true;
      });
    } catch (err) {
      setState(() => _error = err.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      _search = value;
      _load(reset: true);
    });
  }

  Future<void> _openFilters() async {
    final options = await ref.read(categoryOptionsProvider.future);
    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) => _FilterSheet(
        options: options,
        categoryId: _categoryId,
        condition: _condition,
        listingType: _listingType,
        sort: _sort,
        minPrice: _minPrice,
        maxPrice: _maxPrice,
        onApply: (categoryId, condition, listingType, sort, minPrice, maxPrice) {
          _categoryId = categoryId;
          _condition = condition;
          _listingType = listingType;
          _sort = sort;
          _minPrice = minPrice;
          _maxPrice = maxPrice;
          _load(reset: true);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Shop')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
                AppTokens.s4, 0, AppTokens.s4, AppTokens.s2),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    onChanged: _onSearchChanged,
                    textInputAction: TextInputAction.search,
                    decoration: const InputDecoration(
                      hintText: 'Book, blazer, geometry box…',
                      prefixIcon: Icon(Icons.search),
                    ),
                  ),
                ),
                const SizedBox(width: AppTokens.s2),
                IconButton.filledTonal(
                  onPressed: _openFilters,
                  icon: const Icon(Icons.tune),
                  tooltip: 'Filters',
                ),
              ],
            ),
          ),
          SizedBox(
            height: 42,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding:
                  const EdgeInsets.symmetric(horizontal: AppTokens.s4),
              children: [
                _CategoryChip(
                    label: 'All',
                    selected: _categoryId == null,
                    onTap: () {
                      _categoryId = null;
                      _load(reset: true);
                    }),
                ...shopCategories
                    .where((c) => c.slug != 'custom-notebooks')
                    .map((shop) => _AsyncCategoryChip(
                          shop: shop,
                          selectedId: _categoryId,
                          onSelect: (id) {
                            _categoryId = id;
                            _load(reset: true);
                          },
                        )),
                _CategoryChip(
                    label: '📒 Custom Notebook',
                    selected: false,
                    onTap: () => context.push('/notebook')),
              ],
            ),
          ),
          Expanded(
            child: _error != null && _items.isEmpty
                ? EmptyState(
                    emoji: '😵',
                    title: "Couldn't load the catalog",
                    body: _error,
                    ctaLabel: 'Try again',
                    onCta: () => _load(reset: true),
                  )
                : !_initialLoaded
                    ? const Center(child: CircularProgressIndicator())
                    : _items.isEmpty
                        ? const EmptyState(
                            title: 'No items match yet',
                            body:
                                'Try clearing a filter — new items arrive all the time.')
                        : RefreshIndicator(
                            onRefresh: () => _load(reset: true),
                            child: GridView.builder(
                              controller: _scrollController,
                              padding: const EdgeInsets.all(AppTokens.s4),
                              gridDelegate:
                                  const SliverGridDelegateWithMaxCrossAxisExtent(
                                maxCrossAxisExtent: 220,
                                mainAxisExtent: 250,
                                crossAxisSpacing: AppTokens.s3,
                                mainAxisSpacing: AppTokens.s3,
                              ),
                              itemCount:
                                  _items.length + (_pagination.hasNext ? 1 : 0),
                              itemBuilder: (context, index) {
                                if (index >= _items.length) {
                                  return const Center(
                                      child: CircularProgressIndicator());
                                }
                                return ListingCard(listing: _items[index]);
                              },
                            ),
                          ),
          ),
        ],
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _CategoryChip(
      {required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: AppTokens.s2),
      child: FilterChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onTap(),
        labelStyle: TextStyle(
            color: selected ? Colors.white : AppTokens.primaryDark),
      ),
    );
  }
}

class _AsyncCategoryChip extends ConsumerWidget {
  final ShopCategory shop;
  final String? selectedId;
  final void Function(String?) onSelect;

  const _AsyncCategoryChip(
      {required this.shop, required this.selectedId, required this.onSelect});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final options = ref.watch(categoryOptionsProvider).value ?? const [];
    final matched = matchCategory(options, shop);
    final selected = matched != null && matched.id == selectedId;
    return _CategoryChip(
      label: '${shop.emoji} ${shop.label}',
      selected: selected,
      onTap: () => onSelect(selected ? null : matched?.id),
    );
  }
}

class _FilterSheet extends StatefulWidget {
  final List<CategoryRef> options;
  final String? categoryId;
  final String condition;
  final String listingType;
  final String sort;
  final double? minPrice;
  final double? maxPrice;
  final void Function(String?, String, String, String, double?, double?) onApply;

  const _FilterSheet({
    required this.options,
    required this.categoryId,
    required this.condition,
    required this.listingType,
    required this.sort,
    required this.minPrice,
    required this.maxPrice,
    required this.onApply,
  });

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  late String? categoryId = widget.categoryId;
  late String condition = widget.condition;
  late String listingType = widget.listingType;
  late String sort = widget.sort;
  late final minController = TextEditingController(
      text: widget.minPrice?.toStringAsFixed(0) ?? '');
  late final maxController = TextEditingController(
      text: widget.maxPrice?.toStringAsFixed(0) ?? '');

  @override
  void dispose() {
    minController.dispose();
    maxController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.only(
        left: AppTokens.s4,
        right: AppTokens.s4,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppTokens.s4,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Filters', style: theme.textTheme.titleLarge),
            const SizedBox(height: AppTokens.s3),
            if (widget.options.isNotEmpty) ...[
              Text('Category', style: theme.textTheme.titleSmall),
              const SizedBox(height: AppTokens.s2),
              Wrap(
                spacing: AppTokens.s2,
                runSpacing: AppTokens.s2,
                children: [
                  ChoiceChip(
                    label: const Text('Any'),
                    selected: categoryId == null,
                    onSelected: (_) => setState(() => categoryId = null),
                  ),
                  ...widget.options.map((option) => ChoiceChip(
                        label: Text(option.name),
                        selected: categoryId == option.id,
                        onSelected: (_) =>
                            setState(() => categoryId = option.id),
                      )),
                ],
              ),
              const SizedBox(height: AppTokens.s3),
            ],
            Text('Condition', style: theme.textTheme.titleSmall),
            const SizedBox(height: AppTokens.s2),
            Wrap(
              spacing: AppTokens.s2,
              runSpacing: AppTokens.s2,
              children: [
                ChoiceChip(
                  label: const Text('Any'),
                  selected: condition.isEmpty,
                  onSelected: (_) => setState(() => condition = ''),
                ),
                ...conditionLabels.entries.map((entry) => ChoiceChip(
                      label: Text(entry.value),
                      selected: condition == entry.key,
                      onSelected: (_) => setState(() => condition = entry.key),
                    )),
              ],
            ),
            const SizedBox(height: AppTokens.s3),
            Text('Type', style: theme.textTheme.titleSmall),
            const SizedBox(height: AppTokens.s2),
            Wrap(
              spacing: AppTokens.s2,
              children: [
                ChoiceChip(
                  label: const Text('Any'),
                  selected: listingType.isEmpty,
                  onSelected: (_) => setState(() => listingType = ''),
                ),
                ...listingTypeLabels.entries.map((entry) => ChoiceChip(
                      label: Text(entry.value),
                      selected: listingType == entry.key,
                      onSelected: (_) =>
                          setState(() => listingType = entry.key),
                    )),
              ],
            ),
            const SizedBox(height: AppTokens.s3),
            Text('Price (₹)', style: theme.textTheme.titleSmall),
            const SizedBox(height: AppTokens.s2),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: minController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Min'),
                  ),
                ),
                const SizedBox(width: AppTokens.s3),
                Expanded(
                  child: TextField(
                    controller: maxController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Max'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTokens.s3),
            Text('Sort', style: theme.textTheme.titleSmall),
            const SizedBox(height: AppTokens.s2),
            Wrap(
              spacing: AppTokens.s2,
              children: [
                for (final entry in const [
                  ('newest', 'Newest'),
                  ('featured', 'Featured'),
                  ('price_asc', 'Price ↑'),
                  ('price_desc', 'Price ↓'),
                ])
                  ChoiceChip(
                    label: Text(entry.$2),
                    selected: sort == entry.$1,
                    onSelected: (_) => setState(() => sort = entry.$1),
                  ),
              ],
            ),
            const SizedBox(height: AppTokens.s4),
            FilledButton(
              onPressed: () {
                widget.onApply(
                  categoryId,
                  condition,
                  listingType,
                  sort,
                  double.tryParse(minController.text),
                  double.tryParse(maxController.text),
                );
                Navigator.pop(context);
              },
              child: const Text('Apply filters'),
            ),
          ],
        ),
      ),
    );
  }
}
