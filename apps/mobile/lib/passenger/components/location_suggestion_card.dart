import 'package:flutter/material.dart';

/// Shared location result for pickup, destination and intermediate stops.
class LocationSuggestionCard extends StatelessWidget {
  const LocationSuggestionCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.iconData = Icons.location_on_outlined,
    this.customLeading,
    this.trailing,
  });

  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final IconData iconData;
  final Widget? customLeading;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
    child: Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        enabled: onTap != null,
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        leading: customLeading ??
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFFF7F6F2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(iconData, color: const Color(0xFF202520), size: 22),
            ),
        title: Text(
          title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
        subtitle: subtitle.isEmpty
            ? null
            : Text(
                subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12),
              ),
        trailing: trailing,
      ),
    ),
  );
}
