import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:limousineexecutive/passenger/components/location_suggestion_card.dart';
import 'package:limousineexecutive/passenger/models/passenger_state.dart';
import 'package:limousineexecutive/passenger/models/place_search_state.dart';
import 'package:limousineexecutive/passenger/pages/pick_location_on_map.dart';
import 'package:limousineexecutive/services/location_service.dart';
import 'package:provider/provider.dart';

/// Conteúdo da folha para escolher o local de uma morada guardada.
///
/// É a mesma pesquisa e o mesmo desenho do modal de paragens
/// (`modal_stops.dart`): pesquisa enquanto se escreve, "Mapa" ao lado do campo
/// e as mesmas sugestões antes de se escrever.
class SearchPlaceModal extends StatefulWidget {
  const SearchPlaceModal({
    super.key,
    required this.title,
    required this.suggestions,
  });

  /// "Casa", "Trabalho" ou "Novo local".
  final String title;

  /// O que se vê antes de escrever (as sugestões das outras pesquisas).
  final List<Map<String, dynamic>> suggestions;

  @override
  State<SearchPlaceModal> createState() => _SearchPlaceModalState();
}

class _SearchPlaceModalState extends State<SearchPlaceModal> {
  late final PlaceSearchState _search = PlaceSearchState(
    suggestions: widget.suggestions,
    search: LocationService.searchPlacesOSM,
  );
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    super.dispose();
  }

  // Pesquisa 700 ms depois da última tecla, como nas outras pesquisas.
  void _onChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(
      const Duration(milliseconds: 700),
      () => _search.searchNow(value),
    );
  }

  void _onSubmitted(String value) {
    _debounce?.cancel();
    _search.searchNow(value);
    FocusScope.of(context).unfocus();
  }

  Future<void> _pickOnMap() async {
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (context) =>
            PickLocationOnMap(text: widget.title, returnResult: true),
      ),
    );
    if (!mounted) return;
    if (result == null) {
      // Remove o foco de todos os campos
      FocusScope.of(context).unfocus();
      return;
    }
    Navigator.pop(context, result);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ── Handle bar ──
        SizedBox(height: 12.sp),
        Container(
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: Colors.black.withAlpha(40),
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        SizedBox(height: 18.sp),

        // ── Title row with icon badge ──
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.sp),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(8.sp),
                decoration: BoxDecoration(
                  color: const Color(0xffe5a400).withAlpha(25),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.pin_drop_rounded,
                  color: const Color(0xffe5a400),
                  size: 20.sp,
                ),
              ),
              SizedBox(width: 12.sp),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.title,
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w700,
                        fontSize: 18.sp,
                        color: Colors.black,
                      ),
                    ),
                    Text(
                      'Pesquisar ou escolher no mapa',
                      style: GoogleFonts.poppins(
                        fontSize: 12.sp,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 16.sp),

        // ── Search field ──
        Container(
          margin: EdgeInsets.symmetric(horizontal: 18.sp),
          padding: EdgeInsets.symmetric(horizontal: 4.sp),
          decoration: BoxDecoration(
            color: Colors.grey.withAlpha(12),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: const Color(0xffe5a400).withAlpha(40),
              width: 1.5,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                flex: 8,
                child: TextField(
                  autofocus: true, // Auto-focus when the modal opens
                  textInputAction:
                      TextInputAction.search, // force search button on keyboard
                  style: GoogleFonts.poppins(
                    fontSize: 14.sp,
                    color: Colors.black87,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Introduza uma morada',
                    hintStyle: GoogleFonts.poppins(
                      fontSize: 13.sp,
                      color: Colors.grey.shade400,
                    ),
                    prefixIcon: Icon(
                      Icons.search_rounded,
                      color: const Color(0xffe5a400),
                      size: 20.sp,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.transparent,
                    contentPadding: EdgeInsets.symmetric(vertical: 15.sp),
                  ),
                  onChanged: _onChanged,
                  onSubmitted: _onSubmitted,
                ),
              ),

              // Escolher no mapa
              Expanded(
                flex: 3,
                child: GestureDetector(
                  onTap: _pickOnMap,
                  child: Container(
                    margin: EdgeInsets.only(right: 6.sp),
                    height: 34.sp,
                    decoration: BoxDecoration(
                      color: const Color(0xffe5a400),
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xffe5a400).withAlpha(50),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        'Mapa',
                        style: GoogleFonts.poppins(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        // SPACE FOR RESULTS LIST
        Expanded(
          child: ListenableBuilder(
            listenable: _search,
            builder: (context, _) => _listViewSuggestions(),
          ),
        ),
      ],
    );
  }

  Widget _listViewSuggestions() {
    if (_search.noResults) {
      return Center(
        child: Text(
          _search.failed
              ? 'Não foi possível pesquisar. Verifica a ligação.'
              : 'Sem resultados',
          style: GoogleFonts.poppins(fontSize: 13.sp, color: Colors.grey),
        ),
      );
    }
    return ListView(
      scrollDirection: Axis.vertical,
      padding: EdgeInsets.symmetric(horizontal: 4.sp, vertical: 6.sp),
      children: [
        for (final addr in _search.places)
          LocationSuggestionCard(
            title: addr["name"] as String,
            subtitle: addr["fullName"] as String,
            iconData: LocationService.iconForPlace(addr["type"]),
            onTap: () =>
                Navigator.pop(context, PlaceSearchState.savedShape(addr)),
          ),
      ],
    );
  }
}

/// Abre a folha de pesquisa e devolve `{name, fullName, lat, lng}` do local
/// escolhido (pesquisando ou no mapa), ou `null` se for fechada.
Future<Map<String, dynamic>?> showSearchPlaceModal(
  BuildContext context, {
  required String title,
}) {
  final suggestions = Provider.of<PassengerState>(
    context,
    listen: false,
  ).address;
  // Calculate 70% of the total screen height
  final double screenHeight = MediaQuery.of(context).size.height;
  final double modalHeight = screenHeight * 0.7;

  return showModalBottomSheet<Map<String, dynamic>>(
    context: context,
    isScrollControlled:
        true, // Allows the modal to occupy more than half the screen
    backgroundColor: Colors.transparent, // Required for rounded border
    builder: (context) {
      return Container(
        height: modalHeight, // Apply the calculated height
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SearchPlaceModal(title: title, suggestions: suggestions),
      );
    },
  );
}
