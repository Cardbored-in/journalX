import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../data/models/entry.dart';

class DreamCard extends StatelessWidget {
  final Entry entry;

  const DreamCard({super.key, required this.entry});

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM d');
    final rating = entry.rating ?? 0;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.indigo.shade900.withOpacity(0.8),
            Colors.indigo.shade700.withOpacity(0.6),
            Colors.purple.shade900.withOpacity(0.4),
          ],
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.nightlight_round,
                  color: Colors.indigo.shade200, size: 16),
              const SizedBox(width: 8),
              Text(
                'Dream',
                style: TextStyle(
                  color: Colors.indigo.shade200,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Text(
                dateFormat.format(entry.createdAt),
                style: TextStyle(
                  color: Colors.indigo.shade200.withOpacity(0.6),
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (entry.title != null && entry.title!.isNotEmpty)
            Text(
              entry.title!,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          if (entry.content.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              entry.content,
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 14,
                height: 1.4,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          if (rating > 0) ...[
            const SizedBox(height: 12),
            // Clarity rating
            Row(
              children: [
                Text(
                  'Clarity: ',
                  style: TextStyle(
                    color: Colors.indigo.shade200.withOpacity(0.7),
                    fontSize: 12,
                  ),
                ),
                ...List.generate(5, (index) {
                  return Icon(
                    index < rating ? Icons.cloud : Icons.cloud_outlined,
                    color: Colors.indigo.shade200,
                    size: 16,
                  );
                }),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
