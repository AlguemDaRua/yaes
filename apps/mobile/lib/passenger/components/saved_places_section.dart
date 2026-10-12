import 'package:flutter/material.dart';
import 'package:limousineexecutive/passenger/components/location_suggestion_card.dart';
import 'package:limousineexecutive/passenger/models/saved_place.dart';

/// Título de um bloco da lista de sugestões (ex.: "Moradas guardadas").
class SuggestionSectionTitle extends StatelessWidget {
  const SuggestionSectionTitle(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
    child: Text(
      text,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: Colors.black54,
      ),
    ),
  );
}

/// Moradas guardadas do utilizador, mostradas antes das outras sugestões.
/// Usa o mesmo cartão das restantes sugestões; não mostra nada sem moradas.
class SavedPlacesSection extends StatelessWidget {
  const SavedPlacesSection({
    super.key,
    required this.places,
    required this.onSelected,
  });

  final List<SavedPlace> places;
  final ValueChanged<SavedPlace> onSelected;

  @override
  Widget build(BuildContext context) {
    if (places.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SuggestionSectionTitle('Moradas guardadas'),
        for (final place in places)
          LocationSuggestionCard(
            title: place.title,
            subtitle: place.fullName,
            customLeading: _SavedPlaceIcon(kind: place.kind),
            onTap: () => onSelected(place),
          ),
      ],
    );
  }
}

/// Mesmos ícones e cores do ecrã "Moradas Guardadas".
class _SavedPlaceIcon extends StatelessWidget {
  const _SavedPlaceIcon({required this.kind});

  final SavedPlaceKind kind;

  IconData get _icon => switch (kind) {
    SavedPlaceKind.home => Icons.home_rounded,
    SavedPlaceKind.work => Icons.work_rounded,
    SavedPlaceKind.other => Icons.place_outlined,
  };

  Color get _color => switch (kind) {
    SavedPlaceKind.home => Colors.blue,
    SavedPlaceKind.work => Colors.deepPurple,
    SavedPlaceKind.other => Colors.teal,
  };

  @override
  Widget build(BuildContext context) => Container(
    width: 40,
    height: 40,
    decoration: BoxDecoration(
      color: _color.withAlpha(25),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Icon(_icon, color: _color, size: 22),
  );
}
