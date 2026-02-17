import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../data/models/entry.dart';

class MediaCard extends StatelessWidget {
  final Entry entry;

  const MediaCard({super.key, required this.entry});

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM d, yyyy');
    final rating = entry.rating ?? 0;

    return Container(
      decoration: BoxDecoration(
        color: Colors.purple.shade900.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.purple.withOpacity(0.5),
          width: 1,
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.movie, color: Colors.purple.shade300, size: 16),
              const SizedBox(width: 8),
              Text(
                'Media',
                style: TextStyle(
                  color: Colors.purple.shade300,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Text(
                dateFormat.format(entry.createdAt),
                style: TextStyle(
                  color: Colors.purple.shade300.withOpacity(0.6),
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
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          const SizedBox(height: 12),
          // Star Rating
          Row(
            children: List.generate(5, (index) {
              return Icon(
                index < rating ? Icons.star : Icons.star_border,
                color: Colors.amber,
                size: 20,
              );
            }),
          ),
        ],
      ),
    );
  }
}
