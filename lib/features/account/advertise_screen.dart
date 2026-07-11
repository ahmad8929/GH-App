import 'package:cached_network_image/cached_network_image.dart';
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

final _plansProvider =
    FutureProvider.autoDispose<List<AdPlan>>((ref) => ref.watch(advertiseApiProvider).plans());

final _mySubscriptionsProvider =
    FutureProvider.autoDispose<List<AdSubscription>>((ref) async {
  final auth = ref.watch(authControllerProvider);
  if (!auth.isSignedIn) return const [];
  return ref.watch(advertiseApiProvider).mySubscriptions();
});

const _steps = ['Payment', 'Ad submitted', 'Under review', 'Live'];

int _stepIndex(AdSubmission? ad) {
  if (ad == null) return 1; // paid, waiting on a creative
  if (ad.status == 'approved') return 4;
  return 3; // pending or rejected both sit at "under review" on the happy path
}

/// Advertiser opt-in, ad plan purchase, and ad-creative submission — mirrors
/// the Website's `/advertise` page against the same backend contract.
class AdvertiseScreen extends ConsumerWidget {
  const AdvertiseScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authControllerProvider);

    if (!auth.isSignedIn) {
      return Scaffold(
        appBar: AppBar(title: const Text('Advertise with us')),
        body: EmptyState(
          emoji: '📣',
          title: 'Reach thousands of school families',
          body: 'Log in with your regular Gyaan Hub account to buy an ad plan and submit your creative.',
          ctaLabel: 'Login',
          onCta: () => context.push('/login?next=/advertise'),
        ),
      );
    }

    return const _AdvertiseBody();
  }
}

class _AdvertiseBody extends ConsumerWidget {
  const _AdvertiseBody();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final plans = ref.watch(_plansProvider);
    final subscriptions = ref.watch(_mySubscriptionsProvider);
    final ownedPlanIds =
        (subscriptions.asData?.value ?? const <AdSubscription>[]).map((s) => s.planId).toSet();

    return Scaffold(
      appBar: AppBar(title: const Text('Advertise with us')),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(_plansProvider);
          ref.invalidate(_mySubscriptionsProvider);
        },
        child: ListView(
          padding: const EdgeInsets.all(AppTokens.s4),
          children: [
            Text('Reach thousands of school families 📣', style: theme.textTheme.headlineSmall),
            const SizedBox(height: AppTokens.s2),
            Text(
              'Advertise your coaching classes, bookstore, or school services right where parents and students already shop — using your regular Gyaan Hub account.',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: AppTokens.s5),
            Text('Pick a plan', style: theme.textTheme.titleLarge),
            const SizedBox(height: AppTokens.s3),
            plans.when(
              loading: () => const Padding(
                  padding: EdgeInsets.all(AppTokens.s5),
                  child: Center(child: CircularProgressIndicator())),
              error: (err, _) =>
                  EmptyState(emoji: '😵', title: "Couldn't load plans", body: err.toString()),
              data: (items) => items.isEmpty
                  ? const EmptyState(
                      emoji: '🚀', title: 'No plans available yet', body: 'Check back soon.')
                  : Column(
                      children: items
                          .map((plan) => Padding(
                                padding: const EdgeInsets.only(bottom: AppTokens.s3),
                                child: _PlanCard(
                                  plan: plan,
                                  owned: ownedPlanIds.contains(plan.id),
                                  onSubscribed: () => ref.invalidate(_mySubscriptionsProvider),
                                ),
                              ))
                          .toList(),
                    ),
            ),
            const SizedBox(height: AppTokens.s5),
            Text('Your ads', style: theme.textTheme.titleLarge),
            const SizedBox(height: AppTokens.s3),
            subscriptions.when(
              loading: () => const Padding(
                  padding: EdgeInsets.all(AppTokens.s5),
                  child: Center(child: CircularProgressIndicator())),
              error: (err, _) =>
                  EmptyState(emoji: '😵', title: "Couldn't load your ads", body: err.toString()),
              data: (items) => items.isEmpty
                  ? const EmptyState(
                      emoji: '🗂️',
                      title: 'No plans purchased yet',
                      body: 'Choose a plan above to get started.')
                  : Column(
                      children: items
                          .map((sub) => Padding(
                                padding: const EdgeInsets.only(bottom: AppTokens.s3),
                                child: _SubscriptionCard(
                                  subscription: sub,
                                  onChanged: () => ref.invalidate(_mySubscriptionsProvider),
                                ),
                              ))
                          .toList(),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlanCard extends ConsumerStatefulWidget {
  final AdPlan plan;
  final bool owned;
  final VoidCallback onSubscribed;
  const _PlanCard({required this.plan, required this.owned, required this.onSubscribed});

  @override
  ConsumerState<_PlanCard> createState() => _PlanCardState();
}

class _PlanCardState extends ConsumerState<_PlanCard> {
  bool _busy = false;

  Future<void> _confirmAndSubscribe() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm purchase'),
        content: Text(
            'Buy "${widget.plan.name}" for ${inr(widget.plan.price)}?\n\n(Simulated payment — no real charge.)'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(context, true), child: const Text('Confirm & pay')),
        ],
      ),
    );
    if (confirmed != true) return;
    setState(() => _busy = true);
    try {
      await ref.read(advertiseApiProvider).optIn();
      await ref.read(advertiseApiProvider).subscribe(widget.plan.id);
      widget.onSubscribed();
      if (mounted) showSuccess(context, 'Plan purchased! Now submit your ad below.');
    } catch (err) {
      if (mounted) showError(context, err);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final plan = widget.plan;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppTokens.s4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: Text(plan.name, style: theme.textTheme.titleMedium)),
                AppPill(label: '${plan.durationDays} days'),
              ],
            ),
            const SizedBox(height: AppTokens.s1),
            Text(inr(plan.price), style: theme.textTheme.headlineSmall),
            if (plan.description != null && plan.description!.isNotEmpty) ...[
              const SizedBox(height: AppTokens.s1),
              Text(plan.description!, style: theme.textTheme.bodySmall),
            ],
            const SizedBox(height: AppTokens.s3),
            SizedBox(
              width: double.infinity,
              child: widget.owned
                  ? const OutlinedButton(onPressed: null, child: Text('Already purchased'))
                  : FilledButton(
                      onPressed: _busy ? null : _confirmAndSubscribe,
                      child: _busy
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Text('Choose plan'),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AdStepper extends StatelessWidget {
  final AdSubmission? ad;
  const _AdStepper({required this.ad});

  @override
  Widget build(BuildContext context) {
    final current = _stepIndex(ad);
    final rejected = ad?.status == 'rejected';
    final theme = Theme.of(context);
    return Row(
      children: List.generate(_steps.length, (i) {
        final step = i + 1;
        final done = step < current || (step == current && !rejected);
        final isCurrent = step == current;
        final color = isCurrent && rejected
            ? AppTokens.danger
            : done
                ? AppTokens.success
                : theme.colorScheme.outlineVariant;
        return Expanded(
          child: Column(
            children: [
              Container(
                  width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
              const SizedBox(height: 4),
              Text(
                isCurrent && rejected ? 'Rejected' : _steps[i],
                style: theme.textTheme.labelSmall?.copyWith(color: color),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      }),
    );
  }
}

class _ProgressBar extends StatelessWidget {
  final DateTime? startsAt;
  final DateTime? endsAt;
  const _ProgressBar({this.startsAt, this.endsAt});

  @override
  Widget build(BuildContext context) {
    final start = startsAt;
    final end = endsAt;
    if (start == null || end == null) return const SizedBox.shrink();
    final startMs = start.millisecondsSinceEpoch;
    final endMs = end.millisecondsSinceEpoch;
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    final pct = endMs > startMs ? ((nowMs - startMs) / (endMs - startMs)).clamp(0.0, 1.0) : 1.0;
    final daysLeft = ((endMs - nowMs) / (1000 * 60 * 60 * 24)).ceil();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: AppTokens.brSm,
          child: LinearProgressIndicator(value: pct, minHeight: 6),
        ),
        const SizedBox(height: 4),
        Text(daysLeft > 0 ? '$daysLeft day${daysLeft == 1 ? '' : 's'} left' : 'Ended',
            style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

class _SubscriptionCard extends ConsumerStatefulWidget {
  final AdSubscription subscription;
  final VoidCallback onChanged;
  const _SubscriptionCard({required this.subscription, required this.onChanged});

  @override
  ConsumerState<_SubscriptionCard> createState() => _SubscriptionCardState();
}

class _SubscriptionCardState extends ConsumerState<_SubscriptionCard> {
  bool _formOpen = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sub = widget.subscription;
    final ad = sub.ad;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppTokens.s3),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(sub.plan?.name ?? 'Ad plan', style: theme.textTheme.titleSmall),
                      if (sub.amountPaid != null)
                        Text('${inr(sub.amountPaid)} paid', style: theme.textTheme.bodySmall),
                    ],
                  ),
                ),
                StatusPill(
                  ad?.status ?? 'pending',
                  label: ad == null
                      ? 'Needs a creative'
                      : ad.status == 'approved'
                          ? 'Live'
                          : ad.status == 'rejected'
                              ? 'Rejected'
                              : 'Under review',
                ),
              ],
            ),
            const SizedBox(height: AppTokens.s3),
            _AdStepper(ad: ad),
            const SizedBox(height: AppTokens.s2),
            _ProgressBar(startsAt: sub.startsAt, endsAt: sub.endsAt),
            if (ad != null) ...[
              const SizedBox(height: AppTokens.s3),
              InkWell(
                onTap: () => _showAdDetails(context, sub),
                borderRadius: AppTokens.brSm,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: AppTokens.brSm,
                      child: CachedNetworkImage(
                        imageUrl: ad.image,
                        width: 80,
                        height: 60,
                        fit: BoxFit.cover,
                        errorWidget: (_, _, _) => Container(
                            width: 80, height: 60, color: AppTokens.tint),
                      ),
                    ),
                    const SizedBox(width: AppTokens.s3),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(ad.title,
                              style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                          if (ad.businessName != null && ad.businessName!.isNotEmpty)
                            Text(ad.businessName!, style: theme.textTheme.bodySmall),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              if (ad.status == 'rejected' && ad.rejectionReason != null)
                Padding(
                  padding: const EdgeInsets.only(top: AppTokens.s2),
                  child: Text('Reason: ${ad.rejectionReason}',
                      style: theme.textTheme.bodySmall?.copyWith(color: AppTokens.danger)),
                ),
            ],
            const SizedBox(height: AppTokens.s3),
            if (ad == null || ad.status == 'rejected')
              _formOpen
                  ? _AdForm(
                      subscription: sub,
                      onDone: () {
                        setState(() => _formOpen = false);
                        widget.onChanged();
                      },
                    )
                  : SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: () => setState(() => _formOpen = true),
                        child: Text(ad == null ? 'Create your ad' : 'Edit & resubmit'),
                      ),
                    )
            else if (ad.status == 'approved')
              Text('Your ad is live. Contact us if you need changes.',
                  style: theme.textTheme.bodySmall)
            else
              Text("Your ad is under review — we'll notify you once it's approved.",
                  style: theme.textTheme.bodySmall),
          ],
        ),
      ),
    );
  }

  void _showAdDetails(BuildContext context, AdSubscription sub) {
    final ad = sub.ad!;
    final rows = <List<String>>[
      ['Title', ad.title],
      ['Business / brand', ad.businessName ?? '—'],
      ['Description', ad.description ?? '—'],
      ['Target URL', ad.link ?? '—'],
      ['Contact phone', ad.contactPhone ?? '—'],
      ['Contact email', ad.contactEmail ?? '—'],
      ['Status', ad.status],
      if (ad.status == 'rejected') ['Rejection reason', ad.rejectionReason ?? '—'],
      ['Submitted', formatDate(ad.createdAt)],
      ['Plan', sub.plan?.name ?? '—'],
      ['Amount paid', inr(sub.amountPaid)],
    ];
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.6,
        builder: (context, controller) => SingleChildScrollView(
          controller: controller,
          padding: const EdgeInsets.all(AppTokens.s4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: AppTokens.brMd,
                child: CachedNetworkImage(
                  imageUrl: ad.image,
                  width: double.infinity,
                  height: 160,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(height: AppTokens.s3),
              ...rows.map((row) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(row[0], style: Theme.of(context).textTheme.bodySmall),
                        const SizedBox(width: AppTokens.s3),
                        Flexible(child: Text(row[1], textAlign: TextAlign.end)),
                      ],
                    ),
                  )),
            ],
          ),
        ),
      ),
    );
  }
}

class _AdForm extends ConsumerStatefulWidget {
  final AdSubscription subscription;
  final VoidCallback onDone;
  const _AdForm({required this.subscription, required this.onDone});

  @override
  ConsumerState<_AdForm> createState() => _AdFormState();
}

class _AdFormState extends ConsumerState<_AdForm> {
  final _formKey = GlobalKey<FormState>();
  final _businessName = TextEditingController();
  final _title = TextEditingController();
  final _description = TextEditingController();
  final _targetUrl = TextEditingController();
  final _contactPhone = TextEditingController();
  final _contactEmail = TextEditingController();
  XFile? _image;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    for (final c in [
      _businessName,
      _title,
      _description,
      _targetUrl,
      _contactPhone,
      _contactEmail,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (picked != null) setState(() => _image = picked);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final existing = widget.subscription.ad;
    if (existing == null && _image == null) {
      setState(() => _error = 'Please add a creative image.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(advertiseApiProvider).createAd(
            subscriptionId: widget.subscription.id,
            title: _title.text.trim(),
            businessName: _businessName.text.trim(),
            description: _description.text.trim(),
            targetUrl: _targetUrl.text.trim(),
            contactPhone: _contactPhone.text.trim(),
            contactEmail: _contactEmail.text.trim(),
            image: _image,
          );
      if (mounted) {
        showSuccess(context, "Ad submitted for review — we'll notify you once it's live.");
      }
      widget.onDone();
    } catch (err) {
      setState(() => _error = err.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final existing = widget.subscription.ad;
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_error != null) ...[
            Container(
              padding: const EdgeInsets.all(AppTokens.s3),
              decoration:
                  BoxDecoration(color: AppTokens.danger.withValues(alpha: 0.1), borderRadius: AppTokens.brSm),
              child: Text(_error!, style: const TextStyle(color: AppTokens.danger)),
            ),
            const SizedBox(height: AppTokens.s3),
          ],
          TextFormField(
            controller: _businessName,
            decoration: const InputDecoration(labelText: 'Business / brand name'),
          ),
          const SizedBox(height: AppTokens.s3),
          TextFormField(
            controller: _title,
            decoration: const InputDecoration(labelText: 'Ad title *'),
            validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
          ),
          const SizedBox(height: AppTokens.s3),
          TextFormField(
            controller: _description,
            maxLines: 3,
            decoration: const InputDecoration(labelText: 'Description'),
          ),
          const SizedBox(height: AppTokens.s3),
          TextFormField(
            controller: _targetUrl,
            decoration: const InputDecoration(labelText: 'Where should a click go?'),
          ),
          const SizedBox(height: AppTokens.s3),
          TextFormField(
            controller: _contactPhone,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(labelText: 'Contact phone'),
          ),
          const SizedBox(height: AppTokens.s3),
          TextFormField(
            controller: _contactEmail,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(labelText: 'Contact email'),
          ),
          const SizedBox(height: AppTokens.s3),
          OutlinedButton.icon(
            onPressed: _pickImage,
            icon: const Icon(Icons.photo_outlined),
            label: Text(_image == null ? 'Add creative image' : 'Image selected'),
          ),
          if (existing != null)
            Padding(
              padding: const EdgeInsets.only(top: AppTokens.s1),
              child: Text('Leave blank to keep your current image.',
                  style: Theme.of(context).textTheme.bodySmall),
            ),
          const SizedBox(height: AppTokens.s4),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _busy ? null : _submit,
              child: _busy
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : Text(existing == null ? 'Submit ad for review' : 'Resubmit for review'),
            ),
          ),
        ],
      ),
    );
  }
}
