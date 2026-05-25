import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/constants.dart';
import '../../core/theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/geo_provider.dart';
import '../../providers/donor_dashboard_provider.dart';
import '../../providers/listings_provider.dart';
import '../../services/listing_service.dart';
import '../../widgets/primary_button.dart';

class CreateListingScreen extends ConsumerStatefulWidget {
  const CreateListingScreen({super.key});

  @override
  ConsumerState<CreateListingScreen> createState() => _CreateListingScreenState();
}

class _CreateListingScreenState extends ConsumerState<CreateListingScreen> {
  final _title = TextEditingController();
  final _description = TextEditingController();
  final _quantity = TextEditingController(text: '10 portions');
  String _category = 'cooked_meal';
  DateTime _deadline = DateTime.now().add(const Duration(hours: 6));
  String? _imageUrl;
  bool _submitting = false;

  bool get _canSubmit =>
      _title.text.trim().length >= 3 &&
      _category.isNotEmpty &&
      ref.read(geoProvider).hasCoords;

  Future<void> _pickImage() async {
    final file = await ImagePicker().pickImage(source: ImageSource.gallery, maxWidth: 1200, imageQuality: 85);
    if (file == null) return;
    setState(() => _submitting = true);
    try {
      final url = await ref.read(listingServiceProvider).uploadImage(file.path);
      setState(() => _imageUrl = url);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _pickDeadline() async {
    final date = await showDatePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 7)),
      initialDate: _deadline,
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(_deadline));
    if (time == null) return;
    setState(() {
      _deadline = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    });
  }

  Future<void> _submit() async {
    if (!_canSubmit) return;
    final geo = ref.read(geoProvider);
    setState(() => _submitting = true);
    try {
      final user = ref.read(authProvider).user;
      final locationLabel = geo.label ?? user?.locationLabel;
      final created = await ref.read(listingServiceProvider).create({
        'title': _title.text.trim(),
        'description': _description.text.trim().isEmpty ? null : _description.text.trim(),
        'quantity': _quantity.text.trim(),
        'category': _category,
        'pickup_deadline': _deadline.toUtc().toIso8601String(),
        'latitude': geo.latitude,
        'longitude': geo.longitude,
        if (locationLabel != null && locationLabel.isNotEmpty)
          'pickup_location_label': locationLabel,
        if (_imageUrl != null && _imageUrl!.startsWith('http')) 'image_url': _imageUrl,
      });
      ref.invalidate(myListingsProvider);
      ref.invalidate(nearbyListingsProvider);
      ref.invalidate(donorDashboardProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Food posted')));
        context.pop();
        context.push('/donor/listing/${created.id}');
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackground,
      appBar: AppBar(
        title: const Text('Post food'),
        leading: IconButton(icon: const Icon(Icons.close), onPressed: () => context.pop()),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                height: 140,
                decoration: BoxDecoration(
                  color: kSurface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: kBorder, width: 1.5, style: BorderStyle.solid),
                ),
                child: _imageUrl != null && _imageUrl!.startsWith('http')
                    ? Image.network(_imageUrl!, fit: BoxFit.cover, width: double.infinity)
                    : _imageUrl != null
                        ? const Center(child: Text('Photo ready'))
                    : const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.camera_alt_outlined, color: kTextDisabled),
                          SizedBox(height: 8),
                          Text('Tap to upload', style: TextStyle(color: kTextDisabled)),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _title,
              decoration: const InputDecoration(labelText: 'What food is this?'),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),
            const Text('Category', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: kTextSecondary)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: categoryOptions.skip(1).map((opt) {
                final selected = _category == opt.apiValue;
                return ChoiceChip(
                  label: Text(opt.label),
                  selected: selected,
                  onSelected: (_) => setState(() => _category = opt.apiValue!),
                  selectedColor: green100,
                  labelStyle: TextStyle(color: selected ? green500 : kTextSecondary),
                );
              }).toList(),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _quantity,
              decoration: const InputDecoration(labelText: 'How many portions?'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _description,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Any details? (optional)'),
            ),
            const SizedBox(height: 12),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Available until'),
              subtitle: Text(_deadline.toLocal().toString()),
              trailing: const Icon(Icons.chevron_right),
              onTap: _pickDeadline,
            ),
            const SizedBox(height: 24),
            PrimaryButton(
              label: 'Post food now',
              isLoading: _submitting,
              enabled: _canSubmit,
              onPressed: _submit,
            ),
          ],
        ),
      ),
    );
  }
}
