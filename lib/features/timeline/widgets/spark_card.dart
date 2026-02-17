import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../data/models/entry.dart';

class SparkCard extends StatelessWidget {
  final Entry entry;

  const SparkCard({super.key, required this.entry});

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM d');

    return Container(
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.amber.shade300,
          width: 1,
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lightbulb, color: Colors.amber.shade700, size: 16),
              const SizedBox(width: 8),
              Text(
                'Spark',
                style: TextStyle(
                  color: Colors.amber.shade700,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Text(
                dateFormat.format(entry.createdAt),
                style: TextStyle(
                  color: Colors.amber.shade700.withOpacity(0.6),
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            entry.content,
            style: TextStyle(
              color: Colors.amber.shade900,
              fontSize: 16,
              fontWeight: FontWeight.w500,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
