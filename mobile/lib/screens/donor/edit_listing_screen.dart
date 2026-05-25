import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/constants.dart';
import '../../core/theme.dart';
import '../../models/listing.dart';
import '../../providers/donor_dashboard_provider.dart';
import '../../providers/listings_provider.dart';
import '../../services/listing_service.dart';
import '../../widgets/primary_button.dart';

class EditListingScreen extends ConsumerStatefulWidget {
  const EditListingScreen({super.key, required this.listing});

  final ListingModel listing;

  @override
  ConsumerState<EditListingScreen> createState() => _EditListingScreenState();
}

class _EditListingScreenState extends ConsumerState<EditListingScreen> {
  late final TextEditingController _title;
  late final TextEditingController _description;
  late final TextEditingController _quantity;
  late String _category;
  late DateTime _deadline;
  String? _imageUrl;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    final l = widget.listing;
    _title = TextEditingController(text: l.title);
    _description = TextEditingController(text: l.description ?? '');
    _quantity = TextEditingController(text: l.quantity);
    _category = l.category;
    _deadline = l.pickupDeadline.toLocal();
    _imageUrl = l.imageUrl;
  }

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

  Future<void> _save() async {
    setState(() => _submitting = true);
    try {
      await ref.read(listingServiceProvider).update(widget.listing.id, {
        'title': _title.text.trim(),
        'description': _description.text.trim().isEmpty ? null : _description.text.trim(),
        'quantity': _quantity.text.trim(),
        'category': _category,
        'pickup_deadline': _deadline.toUtc().toIso8601String(),
        if (_imageUrl != null) 'image_url': _imageUrl,
      });
      ref.invalidate(myListingsProvider);
      ref.invalidate(listingDetailProvider(widget.listing.id));
      ref.invalidate(donorDashboardProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Listing updated')));
        context.pop();
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _quantity.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackground,
      appBar: AppBar(title: const Text('Edit listing')),
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
                  border: Border.all(color: kBorder),
                ),
                child: _imageUrl != null && _imageUrl!.startsWith('http')
                    ? Image.network(_imageUrl!, fit: BoxFit.cover)
                    : _imageUrl != null
                        ? Image.file(File(_imageUrl!), fit: BoxFit.cover)
                        : const Center(child: Text('Tap to change photo')),
              ),
            ),
            const SizedBox(height: 16),
            TextField(controller: _title, decoration: const InputDecoration(labelText: 'Title')),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: categoryOptions.skip(1).map((opt) {
                final selected = _category == opt.apiValue;
                return ChoiceChip(
                  label: Text(opt.label),
                  selected: selected,
                  onSelected: (_) => setState(() => _category = opt.apiValue!),
                );
              }).toList(),
            ),
            const SizedBox(height: 12),
            TextField(controller: _quantity, decoration: const InputDecoration(labelText: 'Quantity')),
            const SizedBox(height: 12),
            TextField(controller: _description, maxLines: 3, decoration: const InputDecoration(labelText: 'Details')),
            const SizedBox(height: 12),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Pickup deadline'),
              subtitle: Text(_deadline.toString()),
              trailing: const Icon(Icons.chevron_right),
              onTap: _pickDeadline,
            ),
            const SizedBox(height: 24),
            PrimaryButton(label: 'Save changes', isLoading: _submitting, onPressed: _save),
          ],
        ),
      ),
    );
  }
}
