import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/theme.dart';
import '../../models/enums.dart';
import '../../providers/auth_provider.dart';
import '../../models/user.dart';
import '../../services/profile_service.dart';
import '../../widgets/primary_button.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _org = TextEditingController();
  final _bio = TextEditingController();
  final _pickupArea = TextEditingController();
  bool _loading = false;
  bool _uploadingAvatar = false;

  @override
  void initState() {
    super.initState();
    final user = ref.read(authProvider).user;
    if (user != null) _fill(user);
    WidgetsBinding.instance.addPostFrameCallback((_) => _refreshProfile());
  }

  void _fill(UserModel user) {
    _name.text = user.name;
    _phone.text = user.phone;
    _org.text = user.organizationName ?? '';
    _bio.text = user.bio ?? '';
    _pickupArea.text = user.locationLabel ?? '';
  }

  Future<void> _refreshProfile() async {
    try {
      final profile = await ref.read(profileServiceProvider).fetchProfile();
      if (mounted) {
        ref.read(authProvider.notifier).setUser(profile);
        _fill(profile);
        setState(() {});
      }
    } catch (_) {}
  }

  Future<void> _pickAvatar() async {
    final file = await ImagePicker().pickImage(source: ImageSource.gallery, maxWidth: 800, imageQuality: 85);
    if (file == null) return;
    setState(() => _uploadingAvatar = true);
    try {
      final profile = await ref.read(profileServiceProvider).uploadAvatar(file.path);
      ref.read(authProvider.notifier).setUser(profile);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Photo updated')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => _uploadingAvatar = false);
    }
  }

  Future<void> _save() async {
    setState(() => _loading = true);
    try {
      final user = ref.read(authProvider).user!;
      final body = <String, dynamic>{
        'name': _name.text.trim(),
        'phone': _phone.text.trim(),
        if (user.role == UserRole.donor) ...{
          'organization_name': _org.text.trim().isEmpty ? null : _org.text.trim(),
          'bio': _bio.text.trim().isEmpty ? null : _bio.text.trim(),
          'location_label': _pickupArea.text.trim().isEmpty ? null : _pickupArea.text.trim(),
        },
        if (user.role == UserRole.receiver && _bio.text.trim().isNotEmpty)
          'bio': _bio.text.trim(),
      };
      final profile = await ref.read(profileServiceProvider).updateProfile(body);
      ref.read(authProvider.notifier).setUser(profile);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile saved')));
        context.pop();
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _org.dispose();
    _bio.dispose();
    _pickupArea.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;
    final isDonor = user?.role == UserRole.donor;

    return Scaffold(
      backgroundColor: kBackground,
      appBar: AppBar(title: const Text('Edit profile')),
      body: user == null
          ? const Center(child: CircularProgressIndicator(color: green500))
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Center(
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 48,
                        backgroundColor: green100,
                        backgroundImage: user.avatarUrl != null && user.avatarUrl!.isNotEmpty
                            ? CachedNetworkImageProvider(user.avatarUrl!)
                            : null,
                        child: user.avatarUrl == null || user.avatarUrl!.isEmpty
                            ? Text(
                                user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                                style: const TextStyle(fontSize: 32, color: green500, fontWeight: FontWeight.w700),
                              )
                            : null,
                      ),
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: IconButton.filled(
                          onPressed: _uploadingAvatar ? null : _pickAvatar,
                          icon: _uploadingAvatar
                              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                              : const Icon(Icons.camera_alt, size: 18),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                TextField(controller: _name, decoration: const InputDecoration(labelText: 'Name')),
                const SizedBox(height: 12),
                TextField(
                  controller: _phone,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(labelText: 'Phone number'),
                ),
                if (isDonor) ...[
                  const SizedBox(height: 12),
                  TextField(
                    controller: _org,
                    decoration: const InputDecoration(labelText: 'Business / organization name'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _pickupArea,
                    decoration: const InputDecoration(labelText: 'Pickup area label'),
                  ),
                ],
                const SizedBox(height: 12),
                TextField(
                  controller: _bio,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: isDonor ? 'Short bio' : 'Bio (optional)',
                    hintText: isDonor ? 'Tell receivers about your kitchen or store' : 'Optional — keep it brief',
                  ),
                ),
                const SizedBox(height: 24),
                PrimaryButton(label: 'Save', isLoading: _loading, onPressed: _save),
              ],
            ),
    );
  }
}
