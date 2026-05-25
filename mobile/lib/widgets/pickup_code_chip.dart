import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/theme.dart';

class PickupCodeChip extends StatelessWidget {
  const PickupCodeChip({super.key, required this.code, this.label = 'Pickup code'});

  final String code;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: green50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: green100),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 11, color: kTextSecondary)),
                const SizedBox(height: 4),
                Text(
                  code,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 4,
                    color: green500,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.copy_outlined, size: 20, color: green500),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: code));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Code copied')),
              );
            },
          ),
        ],
      ),
    );
  }
}
