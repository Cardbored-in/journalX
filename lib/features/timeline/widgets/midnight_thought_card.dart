import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../../data/models/entry.dart';
import '../../../../core/theme/app_theme.dart';

class MidnightThoughtCard extends StatelessWidget {
  final Entry entry;

  const MidnightThoughtCard({super.key, required this.entry});

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM d, h:mm a');

    return Container(
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.green.shade700.withOpacity(0.5),
          width: 1,
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.terminal,
                color: Colors.green.shade700,
                size: 16,
              ),
              const SizedBox(width: 8),
              Text(
                'MIDNIGHT THOUGHT',
                style: GoogleFonts.firaCode(
                  color: Colors.green.shade700,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
              const Spacer(),
              Text(
                dateFormat.format(entry.createdAt),
                style: GoogleFonts.firaCode(
                  color: Colors.green.shade700.withOpacity(0.6),
                  fontSize: 10,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            entry.content,
            style: GoogleFonts.firaCode(
              color: Colors.green.shade400,
              fontSize: 14,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
