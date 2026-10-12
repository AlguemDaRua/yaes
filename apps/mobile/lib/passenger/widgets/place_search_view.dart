import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:limousineexecutive/passenger/components/location_suggestion_card.dart';
import 'package:limousineexecutive/services/location_service.dart';

/// Pesquisa de locais por texto. Cada resultado traz `name`, `fullName`,
/// `type` e `latlong`, o formato de `LocationService.searchPlacesOSM`.
typedef PlaceSearch = Future<List<Map<String, dynamic>>> Function(String query);

/// Campo de pesquisa, resultados e "Escolher no mapa", para escolher o local
/// de uma morada guardada.
///
/// Só pesquisa quando o utilizador carrega em pesquisar (e não a cada letra),
/// porque o Nominatim não permite pesquisa automática enquanto se escreve.
/// Entrega o local escolhido no mesmo formato do seletor do mapa:
/// `{name, fullName, lat, lng}`.
class PlaceSearchView extends StatefulWidget {
  const PlaceSearchView({
    super.key,
    this.search = LocationService.searchPlacesOSM,
    required this.onSelected,
    required this.onPickOnMap,
  });

  final PlaceSearch search;
  final ValueChanged<Map<String, dynamic>> onSelected;
  final VoidCallback onPickOnMap;

  @override
  State<PlaceSearchView> createState() => _PlaceSearchViewState();
}

enum _Status { idle, loading, done, error }

class _PlaceSearchViewState extends State<PlaceSearchView> {
  static const _accent = Color(0xffe5a400);
  static const _minLetters = 3;
  static const _timeout = Duration(seconds: 15);

  final _controller = TextEditingController();
  var _status = _Status.idle;
  var _results = <Map<String, dynamic>>[];
  var _query = '';

  // Cada pesquisa leva um número e só a última pode mostrar resultados.
  var _requestId = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    final query = _controller.text.trim();
    final requestId = ++_requestId;
    if (query.length < _minLetters) {
      setState(() {
        _status = _Status.idle;
        _results = [];
      });
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() {
      _query = query;
      _status = _Status.loading;
    });
    try {
      final results = await widget.search(query).timeout(_timeout);
      if (!mounted || requestId != _requestId) return;
      setState(() {
        _results = results;
        _status = _Status.done;
      });
    } catch (error) {
      if (!mounted || requestId != _requestId) return;
      developer.log('Pesquisa falhou: $error', name: 'PlaceSearchView');
      setState(() {
        _results = [];
        _status = _Status.error;
      });
    }
  }

  /// Mesmo formato do seletor do mapa, para o ecrã das moradas guardar igual.
  static Map<String, dynamic> _toSavedShape(Map<String, dynamic> place) {
    final location = place['latlong'] as LatLng;
    return {
      'name': place['name'] ?? place['fullName'],
      'fullName': place['fullName'],
      'lat': location.latitude,
      'lng': location.longitude,
    };
  }

  @override
  Widget build(BuildContext context) {
    OutlineInputBorder border(Color color) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(18),
      borderSide: BorderSide(color: color, width: 1.5),
    );

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: TextField(
            controller: _controller,
            autofocus: true,
            textInputAction: TextInputAction.search,
            onSubmitted: (_) => _search(),
            style: const TextStyle(fontSize: 14, color: Colors.black87),
            decoration: InputDecoration(
              hintText: 'Pesquisar morada ou local',
              hintStyle: TextStyle(fontSize: 14, color: Colors.grey.shade400),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 18,
                vertical: 14,
              ),
              suffixIcon: IconButton(
                tooltip: 'Pesquisar',
                icon: const Icon(Icons.search_rounded, color: _accent),
                onPressed: _search,
              ),
              border: border(_accent.withAlpha(60)),
              focusedBorder: border(_accent),
            ),
          ),
        ),
        LocationSuggestionCard(
          title: 'Escolher no mapa',
          subtitle: 'Marca o local no mapa',
          iconData: Icons.map_outlined,
          onTap: widget.onPickOnMap,
        ),
        Expanded(child: _buildBody()),
      ],
    );
  }

  Widget _buildBody() {
    return switch (_status) {
      _Status.idle => const _Message(
        'Escreve pelo menos 3 letras e carrega em pesquisar.',
      ),
      _Status.loading => const Center(child: CircularProgressIndicator()),
      _Status.error => _Message(
        'Não foi possível pesquisar. Verifica a ligação e tenta de novo.',
        action: TextButton(
          onPressed: _search,
          child: const Text('Tentar de novo'),
        ),
      ),
      _Status.done =>
        _results.isEmpty
            ? _Message(
                'Sem resultados para “$_query”. '
                'Tenta outro nome ou escolhe no mapa.',
              )
            : _buildResults(),
    };
  }

  Widget _buildResults() {
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 16),
      itemCount: _results.length,
      itemBuilder: (context, index) {
        final place = _results[index];
        return LocationSuggestionCard(
          title: '${place['name'] ?? place['fullName']}',
          subtitle: '${place['fullName'] ?? ''}',
          iconData: LocationService.iconForPlace('${place['type']}'),
          onTap: () => widget.onSelected(_toSavedShape(place)),
        );
      },
    );
  }
}

/// Mensagem curta (ex.: "Sem resultados"), com uma ação opcional.
class _Message extends StatelessWidget {
  const _Message(this.text, {this.action});

  final String text;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final action = this.action;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            text,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13, color: Colors.black54),
          ),
          if (action != null) action,
        ],
      ),
    );
  }
}
