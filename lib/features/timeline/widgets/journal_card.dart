import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../../data/models/entry.dart';
import '../../../../core/theme/app_theme.dart';

class JournalCard extends StatelessWidget {
  final Entry entry;

  const JournalCard({super.key, required this.entry});

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM d, yyyy');

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFFFDF5),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.brown.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.book, color: AppTheme.primaryColor, size: 16),
              const SizedBox(width: 8),
              Text(
                'Journal',
                style: GoogleFonts.lora(
                  color: AppTheme.primaryColor,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Text(
                dateFormat.format(entry.createdAt),
                style: GoogleFonts.lora(
                  color: AppTheme.onSurfaceColor.withOpacity(0.5),
                  fontSize: 12,
                ),
              ),
            ],
          ),
          if (entry.title != null && entry.title!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              entry.title!,
              style: GoogleFonts.lora(
                color: AppTheme.onSurfaceColor,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
          const SizedBox(height: 8),
          Text(
            entry.content,
            style: GoogleFonts.lora(
              color: AppTheme.onSurfaceColor.withOpacity(0.8),
              fontSize: 14,
              height: 1.6,
            ),
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
