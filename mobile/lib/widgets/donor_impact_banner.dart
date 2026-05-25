import 'package:flutter/material.dart';

import '../core/theme.dart';

class DonorImpactBanner extends StatelessWidget {
  const DonorImpactBanner({super.key});

  static void showHowItWorks(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: kSurface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(24, 20, 24, 24 + MediaQuery.paddingOf(ctx).bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(color: gray300, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 20),
            Text('How Zero Hunger works', style: Theme.of(ctx).textTheme.titleMedium),
            const SizedBox(height: 16),
            const _Step(number: '1', title: 'Post surplus food', body: 'List what you have, when it\'s ready, and where to pick up.'),
            const SizedBox(height: 12),
            const _Step(number: '2', title: 'Someone nearby claims', body: 'Receivers request food — you approve one claim.'),
            const SizedBox(height: 12),
            const _Step(number: '3', title: 'Pickup & done', body: 'They collect the food. Mark complete so others know it\'s gone.'),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.pop(ctx),
                style: FilledButton.styleFrom(backgroundColor: green500),
                child: const Text('Got it'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: green50,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: green100),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Make an impact',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: kTextPrimary),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Your surplus could be someone\'s blessing today.',
                  style: TextStyle(fontSize: 12, color: kTextSecondary, height: 1.35),
                ),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: () => showHowItWorks(context),
                  style: FilledButton.styleFrom(
                    backgroundColor: green500,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text(
                    'Learn how it works',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          const _ImpactIllustration(),
        ],
      ),
    );
  }
}

class _ImpactIllustration extends StatelessWidget {
  const _ImpactIllustration();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 88,
      height: 88,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 72,
            height: 56,
            decoration: BoxDecoration(
              color: const Color(0xFFE8C9A0),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFC4A574), width: 1.5),
            ),
            child: const Icon(Icons.inventory_2_outlined, color: Color(0xFF8B6914), size: 32),
          ),
          Positioned(
            top: 8,
            right: 12,
            child: Icon(Icons.favorite, size: 18, color: kError.withValues(alpha: 0.85)),
          ),
          Positioned(
            bottom: 10,
            left: 8,
            child: Icon(Icons.favorite_border, size: 14, color: green500.withValues(alpha: 0.5)),
          ),
        ],
      ),
    );
  }
}

class _Step extends StatelessWidget {
  const _Step({required this.number, required this.title, required this.body});

  final String number;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 14,
          backgroundColor: green100,
          child: Text(number, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: green500)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 2),
              Text(body, style: const TextStyle(fontSize: 13, color: kTextSecondary)),
            ],
          ),
        ),
      ],
    );
  }
}
