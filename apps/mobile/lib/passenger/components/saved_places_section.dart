import 'package:flutter/material.dart';
import 'package:limousineexecutive/passenger/components/location_suggestion_card.dart';
import 'package:limousineexecutive/passenger/models/saved_place.dart';

import 'package:limousineexecutive/services/location_service.dart';

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
    this.isSelected,
  });

  final List<SavedPlace> places;
  final ValueChanged<SavedPlace> onSelected;
  final bool Function(SavedPlace place)? isSelected;

  @override
  Widget build(BuildContext context) {
    if (places.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SuggestionSectionTitle('Moradas guardadas'),
        for (final place in places) _buildItem(place),
      ],
    );
  }

  Widget _buildItem(SavedPlace place) {
    final selected = isSelected?.call(place) ?? false;
    return LocationSuggestionCard(
      title: place.title,
      subtitle: place.fullName,
      customLeading: _SavedPlaceIcon(kind: place.kind),
      trailing: selected
          ? const Icon(
              Icons.check_circle_rounded,
              color: Color(0xffe5a400),
              size: 24,
            )
          : null,
      onTap: selected ? null : () => onSelected(place),
    );
  }
}

/// Lista unificada de moradas guardadas e sugestões de locais.
/// Usada tanto na folha de recolha/destino como no modal de paragens.
class LocationSuggestionsList extends StatelessWidget {
  const LocationSuggestionsList({
    super.key,
    required this.savedPlaces,
    required this.suggestions,
    required this.onSelectPlace,
    required this.onSelectSuggestion,
    this.isPlaceSelected,
    this.isSuggestionSelected,
    this.header,
    this.padding,
    this.shrinkWrap = false,
  });

  final List<SavedPlace> savedPlaces;
  final List<Map<String, dynamic>> suggestions;
  final ValueChanged<SavedPlace> onSelectPlace;
  final ValueChanged<Map<String, dynamic>> onSelectSuggestion;
  final bool Function(SavedPlace place)? isPlaceSelected;
  final bool Function(Map<String, dynamic> suggestion)? isSuggestionSelected;
  final Widget? header;
  final EdgeInsetsGeometry? padding;
  final bool shrinkWrap;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: padding ?? EdgeInsets.zero,
      shrinkWrap: shrinkWrap,
      scrollDirection: Axis.vertical,
      children: [
        if (header != null) header!,
        if (savedPlaces.isNotEmpty) ...[
          SavedPlacesSection(
            places: savedPlaces,
            isSelected: isPlaceSelected,
            onSelected: onSelectPlace,
          ),
          const SuggestionSectionTitle('Sugestões'),
        ],
        for (final addr in suggestions) _buildSuggestionItem(addr),
      ],
    );
  }

  Widget _buildSuggestionItem(Map<String, dynamic> addr) {
    final selected = isSuggestionSelected?.call(addr) ?? false;
    return LocationSuggestionCard(
      title: addr["name"] as String,
      subtitle: addr["fullName"] as String,
      iconData: LocationService.iconForPlace(addr["type"]),
      trailing: selected
          ? const Icon(
              Icons.check_circle_rounded,
              color: Color(0xffe5a400),
              size: 24,
            )
          : null,
      onTap: selected ? null : () => onSelectSuggestion(addr),
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
