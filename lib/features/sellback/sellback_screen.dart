import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/format.dart';
import '../../core/models/models.dart';
import '../../core/theme/app_tokens.dart';
import '../../shared/widgets/common.dart';
import '../../state/auth_state.dart';
import '../../state/providers.dart';

final mySubmissionsProvider =
    FutureProvider.autoDispose<List<SellbackRequest>>((ref) async {
  final auth = ref.watch(authControllerProvider);
  if (!auth.isSignedIn) return const [];
  final res = await ref.watch(sellbackApiProvider).mine();
  return res.data;
});

/// Sell/Donate intake: a pickup request — we collect, inspect, and list the
/// item as Gyaan Hub inventory. The submitter is never shown as a seller.
class SellbackScreen extends ConsumerWidget {
  const SellbackScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authControllerProvider);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Sell / Donate'),
          bottom: const TabBar(tabs: [
            Tab(text: 'Submit an item'),
            Tab(text: 'My submissions'),
          ]),
        ),
        body: !auth.isSignedIn
            ? EmptyState(
                emoji: '🔐',
                title: 'Log in to sell or donate',
                body:
                    'Submit an item, we pick it up, check it, and list it in the store.',
                ctaLabel: 'Login',
                onCta: () => context.push('/login?next=/sell'),
              )
            : const TabBarView(children: [
                _SubmitForm(),
                _SubmissionsList(),
              ]),
      ),
    );
  }
}

class _SubmitForm extends ConsumerStatefulWidget {
  const _SubmitForm();

  @override
  ConsumerState<_SubmitForm> createState() => _SubmitFormState();
}

class _SubmitFormState extends ConsumerState<_SubmitForm>
    with AutomaticKeepAliveClientMixin {
  final _formKey = GlobalKey<FormState>();
  String _kind = 'sell';
  final _title = TextEditingController();
  final _description = TextEditingController();
  String _condition = 'good';
  String? _categoryId;
  final _expectedPrice = TextEditingController();
  final _contactName = TextEditingController();
  final _contactPhone = TextEditingController();
  final _pickupAddress = TextEditingController();
  final _city = TextEditingController();
  final _pincode = TextEditingController();
  final List<XFile> _images = [];
  bool _busy = false;
  String? _error;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _contactName.text = ref.read(authControllerProvider).user?.name ?? '';
  }

  @override
  void dispose() {
    for (final c in [
      _title,
      _description,
      _expectedPrice,
      _contactName,
      _contactPhone,
      _pickupAddress,
      _city,
      _pincode
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _pickImages() async {
    final picked = await ImagePicker().pickMultiImage(limit: 6);
    if (picked.isNotEmpty) {
      setState(() {
        _images
          ..clear()
          ..addAll(picked.take(6));
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(sellbackApiProvider).submit(
            kind: _kind,
            title: _title.text.trim(),
            description: _description.text.trim(),
            condition: _condition,
            categoryId: _categoryId,
            expectedPrice: _kind == 'sell' ? _expectedPrice.text.trim() : null,
            contactName: _contactName.text.trim(),
            contactPhone: _contactPhone.text.trim(),
            pickupAddress: _pickupAddress.text.trim(),
            city: _city.text.trim(),
            pincode: _pincode.text.trim(),
            images: _images,
          );
      ref.invalidate(mySubmissionsProvider);
      if (!mounted) return;
      showSuccess(context, "Thanks! We'll review it and arrange a pickup. 🚚");
      _formKey.currentState!.reset();
      _title.clear();
      _description.clear();
      _expectedPrice.clear();
      setState(() => _images.clear());
      DefaultTabController.of(context).animateTo(1);
    } catch (err) {
      setState(() => _error = err.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final theme = Theme.of(context);
    final options = ref.watch(categoryOptionsProvider).value ?? const [];
    final isSell = _kind == 'sell';

    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(AppTokens.s4),
        children: [
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(
                  value: 'sell',
                  icon: Icon(Icons.currency_rupee),
                  label: Text('Sell — I want money')),
              ButtonSegment(
                  value: 'donate',
                  icon: Icon(Icons.favorite),
                  label: Text('Donate')),
            ],
            selected: {_kind},
            onSelectionChanged: (selection) =>
                setState(() => _kind = selection.first),
          ),
          const SizedBox(height: AppTokens.s3),
          Text(
            isSell
                ? 'Tell us what you have — we pick it up, check it, and pay you once agreed.'
                : 'Give it a second life — we pick it up and pass it on. 💙',
            style: theme.textTheme.bodyMedium
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: AppTokens.s4),
          if (_error != null) ...[
            Container(
              padding: const EdgeInsets.all(AppTokens.s3),
              decoration: BoxDecoration(
                color: AppTokens.danger.withValues(alpha: 0.1),
                borderRadius: AppTokens.brSm,
              ),
              child: Text(_error!, style: TextStyle(color: AppTokens.danger)),
            ),
            const SizedBox(height: AppTokens.s3),
          ],
          TextFormField(
            controller: _title,
            decoration: const InputDecoration(
                labelText: 'Item title',
                hintText: 'e.g. NCERT Science Class 8'),
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Required' : null,
          ),
          const SizedBox(height: AppTokens.s3),
          if (options.isNotEmpty) ...[
            DropdownButtonFormField<String>(
              initialValue: _categoryId,
              decoration:
                  const InputDecoration(labelText: 'Category (optional)'),
              items: [
                const DropdownMenuItem(value: null, child: Text('Choose…')),
                ...options.map((option) => DropdownMenuItem(
                    value: option.id, child: Text(option.name))),
              ],
              onChanged: (v) => setState(() => _categoryId = v),
            ),
            const SizedBox(height: AppTokens.s3),
          ],
          DropdownButtonFormField<String>(
            initialValue: _condition,
            decoration: const InputDecoration(labelText: 'Condition'),
            items: conditionLabels.entries
                .map((entry) => DropdownMenuItem(
                    value: entry.key, child: Text(entry.value)))
                .toList(),
            onChanged: (v) => setState(() => _condition = v!),
          ),
          if (isSell) ...[
            const SizedBox(height: AppTokens.s3),
            TextFormField(
              controller: _expectedPrice,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                  labelText: 'How much would you like? (₹)'),
              validator: (v) => isSell &&
                      (v == null ||
                          v.trim().isEmpty ||
                          (double.tryParse(v) ?? 0) <= 0)
                  ? 'Enter an amount'
                  : null,
            ),
          ],
          const SizedBox(height: AppTokens.s3),
          TextFormField(
            controller: _description,
            maxLines: 3,
            decoration: const InputDecoration(
                labelText: 'Details (optional)',
                hintText: 'Edition, wear and tear, anything we should know'),
          ),
          const SizedBox(height: AppTokens.s4),
          Text('Photos', style: theme.textTheme.titleMedium),
          const SizedBox(height: AppTokens.s2),
          Row(
            children: [
              OutlinedButton.icon(
                onPressed: _pickImages,
                icon: const Icon(Icons.photo_library_outlined),
                label: Text(_images.isEmpty
                    ? 'Add photos (up to 6)'
                    : '${_images.length} photo${_images.length == 1 ? '' : 's'} selected'),
              ),
              if (_images.isNotEmpty)
                TextButton(
                  onPressed: () => setState(() => _images.clear()),
                  child: const Text('Clear'),
                ),
            ],
          ),
          const SizedBox(height: AppTokens.s4),
          Text('Pickup details', style: theme.textTheme.titleMedium),
          const SizedBox(height: AppTokens.s2),
          TextFormField(
            controller: _contactName,
            decoration: const InputDecoration(labelText: 'Contact name'),
          ),
          const SizedBox(height: AppTokens.s3),
          TextFormField(
            controller: _contactPhone,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(labelText: 'Contact phone'),
            validator: (v) =>
                (v == null || v.trim().length < 8) ? 'Enter a phone' : null,
          ),
          const SizedBox(height: AppTokens.s3),
          TextFormField(
            controller: _pickupAddress,
            decoration: const InputDecoration(labelText: 'Pickup address'),
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Required' : null,
          ),
          const SizedBox(height: AppTokens.s3),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _city,
                  decoration: const InputDecoration(labelText: 'City'),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
              ),
              const SizedBox(width: AppTokens.s3),
              Expanded(
                child: TextFormField(
                  controller: _pincode,
                  keyboardType: TextInputType.number,
                  decoration:
                      const InputDecoration(labelText: 'Pincode (optional)'),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTokens.s4),
          FilledButton(
            onPressed: _busy ? null : _submit,
            child: Text(_busy
                ? 'Submitting…'
                : isSell
                    ? 'Submit for pickup & payout'
                    : 'Donate this item'),
          ),
          const SizedBox(height: AppTokens.s2),
          Text(
            'Our team reviews every request. Once collected and checked, items are listed by Gyaan Hub — your name is never shown.',
            style: theme.textTheme.bodySmall
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: AppTokens.s5),
        ],
      ),
    );
  }
}

class _SubmissionsList extends ConsumerWidget {
  const _SubmissionsList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final submissions = ref.watch(mySubmissionsProvider);

    return submissions.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => EmptyState(
          emoji: '😵', title: "Couldn't load submissions", body: err.toString()),
      data: (items) => items.isEmpty
          ? const EmptyState(
              emoji: '📮',
              title: 'Nothing submitted yet',
              body: 'Outgrown books or uniforms? Send them our way!')
          : RefreshIndicator(
              onRefresh: () async => ref.invalidate(mySubmissionsProvider),
              child: ListView.separated(
                padding: const EdgeInsets.all(AppTokens.s4),
                itemCount: items.length,
                separatorBuilder: (_, _) =>
                    const SizedBox(height: AppTokens.s3),
                itemBuilder: (context, index) {
                  final request = items[index];
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(AppTokens.s3),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(request.title,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleSmall),
                              ),
                              StatusPill(request.status),
                            ],
                          ),
                          const SizedBox(height: AppTokens.s1),
                          Text(
                            [
                              request.kind == 'sell' ? 'Sell' : 'Donate',
                              conditionLabels[request.condition] ??
                                  request.condition,
                              if (request.kind == 'sell')
                                request.agreedPrice != null
                                    ? 'Agreed ${inr(request.agreedPrice)}'
                                    : 'Asked ${inr(request.expectedPrice)}',
                              formatDate(request.createdAt),
                            ].join(' · '),
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          if (request.rejectionReason != null &&
                              request.status == 'rejected')
                            Padding(
                              padding:
                                  const EdgeInsets.only(top: AppTokens.s1),
                              child: Text(
                                  'Reason: ${request.rejectionReason}',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(color: AppTokens.danger)),
                            ),
                          if (request.cancellable)
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: () async {
                                  try {
                                    await ref
                                        .read(sellbackApiProvider)
                                        .cancel(request.id);
                                    ref.invalidate(mySubmissionsProvider);
                                    if (context.mounted) {
                                      showSuccess(
                                          context, 'Request withdrawn');
                                    }
                                  } catch (err) {
                                    if (context.mounted) {
                                      showError(context, err);
                                    }
                                  }
                                },
                                child: const Text('Withdraw'),
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
    );
  }
}
