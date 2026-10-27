import 'dart:async';

import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:limousineexecutive/passenger/models/passenger_state.dart';
import 'package:limousineexecutive/passenger/models/saved_place.dart';
import 'package:limousineexecutive/passenger/models/saved_places_state.dart';
import 'package:limousineexecutive/passenger/components/saved_places_section.dart';
import 'package:limousineexecutive/passenger/components/location_suggestion_card.dart';
import 'package:provider/provider.dart';
import 'package:limousineexecutive/services/location_service.dart';

class LocationSearchSheet extends StatelessWidget {
  final VoidCallback onRouteChanged;
  final void Function(double size) onAnimateSheet;

  const LocationSearchSheet({
    super.key,
    required this.onRouteChanged,
    required this.onAnimateSheet,
  });

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<PassengerState>(context);
    final isPickup = appState.showPickupOptions;
    return _AddressSuggestions(
      key: ValueKey(isPickup ? 'pickup-search' : 'destination-search'),
      controller: isPickup
          ? appState.controllerPickup
          : appState.controllerDestination,
      emptyHeader: isPickup
          ? LocationSuggestionCard(
              title: 'Minha localização',
              subtitle: 'Usar localização atual do GPS',
              iconData: Icons.my_location_rounded,
              onTap: () {
                final location = appState.currentLocation;
                if (location == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'A localização ainda não está disponível. Ativa o GPS ou escolhe no mapa.',
                      ),
                    ),
                  );
                  return;
                }
                _select(appState, 'Minha localização', location);
              },
            )
          : null,
      onSelectPlace: (place) => _select(appState, place.name, place.location),
      onSelectSuggestion: (place) =>
          _select(appState, place['name'] as String, place['latlong']),
    );
  }

  /// Aplica a sugestão escolhida à recolha ou ao destino (o campo que estiver
  /// ativo) e fecha a lista. É usada pelos resultados da pesquisa e pelas
  /// moradas guardadas, para as duas se comportarem exatamente da mesma forma.
  void _select(PassengerState appState, String name, LatLng? location) {
    if (appState.showPickupOptions) {
      appState.fromAddress = name;
      appState.originLocation = location;
      appState.controllerPickup.text = name;
    } else if (appState.showDestinationOptions) {
      appState.toAddress = name;
      appState.destinationLocation = location;
      appState.controllerDestination.text = name;

      if (appState.selectedCarTypeindex != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          onAnimateSheet(0.9);
        });
      }
    }

    // Atualiza a rota uma única vez se ambos os endereços estiverem preenchidos
    if (appState.fromAddress.isNotEmpty && appState.toAddress.isNotEmpty) {
      onRouteChanged();
    }

    appState.focusNodePickup.unfocus();
    appState.focusNodeDestination.unfocus();
    appState.showDestinationOptions = false;
    appState.showPickupOptions = false;
  }
}

/// Each field owns its results. An empty field shows saved addresses, while
/// typing displays API results only; late responses cannot cross fields.
class _AddressSuggestions extends StatefulWidget {
  const _AddressSuggestions({
    super.key,
    required this.controller,
    required this.onSelectPlace,
    required this.onSelectSuggestion,
    this.emptyHeader,
  });

  final TextEditingController controller;
  final Widget? emptyHeader;
  final ValueChanged<SavedPlace> onSelectPlace;
  final ValueChanged<Map<String, dynamic>> onSelectSuggestion;

  @override
  State<_AddressSuggestions> createState() => _AddressSuggestionsState();
}

class _AddressSuggestionsState extends State<_AddressSuggestions> {
  Timer? _debounce;
  String? _query;
  int _requestId = 0;
  bool _loading = false;
  bool _failed = false;
  List<Map<String, dynamic>> _results = const [];

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTextChanged);
    _onTextChanged();
  }

  @override
  void didUpdateWidget(covariant _AddressSuggestions oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_onTextChanged);
      widget.controller.addListener(_onTextChanged);
      _query = null;
      _onTextChanged();
    }
  }

  void _onTextChanged() {
    final query = widget.controller.text.trim();
    if (query == _query) return;
    _debounce?.cancel();
    final requestId = ++_requestId;
    setState(() {
      _query = query;
      _results = const [];
      _failed = false;
      _loading = query.isNotEmpty;
    });
    if (query.isEmpty) return;
    _debounce = Timer(
      const Duration(milliseconds: 700),
      () => _search(query, requestId),
    );
  }

  Future<void> _search(String query, int requestId) async {
    try {
      final results = await LocationService.searchPlacesOSM(
        query,
      ).timeout(const Duration(seconds: 15));
      if (!mounted || requestId != _requestId) return;
      setState(() {
        _results = results;
        _loading = false;
      });
    } catch (_) {
      if (!mounted || requestId != _requestId) return;
      setState(() {
        _failed = true;
        _loading = false;
      });
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    widget.controller.removeListener(_onTextChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_query == null || _query!.isEmpty) {
      final savedPlaces = context.watch<SavedPlacesState>().places;
      if (savedPlaces.isEmpty && widget.emptyHeader == null) {
        return _message(
          context,
          'Ainda não tens moradas guardadas. Escreve um local para pesquisar.',
        );
      }
      return LocationSuggestionsList(
        savedPlaces: savedPlaces,
        suggestions: const [],
        header: widget.emptyHeader,
        onSelectPlace: widget.onSelectPlace,
        onSelectSuggestion: widget.onSelectSuggestion,
      );
    }
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(
          color: Color(0xFFE5A400),
          semanticsLabel: 'A pesquisar locais',
        ),
      );
    }
    if (_failed) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _message(
              context,
              'Não foi possível pesquisar. Verifica a ligação e tenta novamente.',
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  _failed = false;
                  _loading = true;
                });
                _search(_query!, ++_requestId);
              },
              child: const Text('Tentar novamente'),
            ),
          ],
        ),
      );
    }
    if (_results.isEmpty) {
      return _message(context, 'Nenhum local encontrado. Tenta outro nome.');
    }
    return LocationSuggestionsList(
      savedPlaces: const [],
      suggestions: _results,
      onSelectPlace: widget.onSelectPlace,
      onSelectSuggestion: widget.onSelectSuggestion,
    );
  }

  Widget _message(BuildContext context, String text) => Padding(
    padding: const EdgeInsets.all(24),
    child: Text(
      text,
      textAlign: TextAlign.center,
      style: Theme.of(
        context,
      ).textTheme.bodyMedium?.copyWith(color: Colors.black54),
    ),
  );
}
