import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/models/models.dart';
import '../../core/theme/app_tokens.dart';
import '../../shared/widgets/common.dart';
import '../../state/auth_state.dart';
import '../../state/providers.dart';

final _profileProvider = FutureProvider.autoDispose<MeProfile>(
    (ref) => ref.watch(profileApiProvider).me());

class ProfileEditScreen extends ConsumerStatefulWidget {
  const ProfileEditScreen({super.key});

  @override
  ConsumerState<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends ConsumerState<ProfileEditScreen> {
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _city = TextEditingController();
  final _address = TextEditingController();
  final _bio = TextEditingController();
  bool _seeded = false;
  bool _busy = false;
  bool _avatarBusy = false;

  @override
  void dispose() {
    for (final c in [_name, _phone, _city, _address, _bio]) {
      c.dispose();
    }
    super.dispose();
  }

  void _seed(MeProfile profile) {
    if (_seeded) return;
    _seeded = true;
    _name.text = profile.user.name;
    _phone.text = profile.profile?.phone ?? profile.phone ?? '';
    _city.text = profile.profile?.city ?? '';
    _address.text = profile.profile?.address ?? '';
    _bio.text = profile.profile?.bio ?? '';
  }

  Future<void> _save(MeProfile current) async {
    setState(() => _busy = true);
    try {
      final api = ref.read(profileApiProvider);
      if (_name.text.trim().isNotEmpty &&
          _name.text.trim() != current.user.name) {
        await api.updateInfo(name: _name.text.trim());
      }
      await api.update({
        'phone': _phone.text.trim().isEmpty ? null : _phone.text.trim(),
        'city': _city.text.trim().isEmpty ? null : _city.text.trim(),
        'address': _address.text.trim().isEmpty ? null : _address.text.trim(),
        'bio': _bio.text.trim().isEmpty ? null : _bio.text.trim(),
      });
      await ref.read(authControllerProvider.notifier).refreshUser();
      ref.invalidate(_profileProvider);
      if (mounted) showSuccess(context, 'Profile saved');
    } catch (err) {
      if (mounted) showError(context, err);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _changeAvatar() async {
    final picked =
        await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked == null) return;
    setState(() => _avatarBusy = true);
    try {
      await ref.read(profileApiProvider).uploadAvatar(picked);
      await ref.read(authControllerProvider.notifier).refreshUser();
      ref.invalidate(_profileProvider);
      if (mounted) showSuccess(context, 'Avatar updated');
    } catch (err) {
      if (mounted) showError(context, err);
    } finally {
      if (mounted) setState(() => _avatarBusy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(_profileProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Edit profile')),
      body: profileAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => EmptyState(
            emoji: '😵', title: "Couldn't load profile", body: err.toString()),
        data: (profile) {
          _seed(profile);
          return ListView(
            padding: const EdgeInsets.all(AppTokens.s4),
            children: [
              Center(
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 44 * AppTokens.scale,
                      backgroundColor: AppTokens.primary,
                      foregroundImage: profile.profile?.avatar != null
                          ? NetworkImage(profile.profile!.avatar!)
                          : (profile.user.avatar != null
                              ? NetworkImage(profile.user.avatar!)
                              : null),
                      child: Text(
                        profile.user.name.isNotEmpty
                            ? profile.user.name[0].toUpperCase()
                            : 'G',
                        style: const TextStyle(
                            fontSize: 30,
                            color: Colors.white,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                    TextButton(
                      onPressed: _avatarBusy ? null : _changeAvatar,
                      child:
                          Text(_avatarBusy ? 'Uploading…' : 'Change photo'),
                    ),
                  ],
                ),
              ),
              TextField(
                  controller: _name,
                  decoration: const InputDecoration(labelText: 'Name')),
              const SizedBox(height: AppTokens.s3),
              TextField(
                  controller: _phone,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(labelText: 'Phone')),
              const SizedBox(height: AppTokens.s3),
              TextField(
                  controller: _city,
                  decoration: const InputDecoration(labelText: 'City')),
              const SizedBox(height: AppTokens.s3),
              TextField(
                  controller: _address,
                  decoration: const InputDecoration(labelText: 'Address')),
              const SizedBox(height: AppTokens.s3),
              TextField(
                  controller: _bio,
                  maxLines: 3,
                  decoration:
                      const InputDecoration(labelText: 'About you (optional)')),
              const SizedBox(height: AppTokens.s4),
              FilledButton(
                onPressed: _busy ? null : () => _save(profile),
                child: Text(_busy ? 'Saving…' : 'Save profile'),
              ),
            ],
          );
        },
      ),
    );
  }
}
