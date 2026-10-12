import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';

/// Pesquisa de locais por texto. Cada resultado traz `name`, `fullName`,
/// `type` e `latlong`, o formato de `LocationService.searchPlacesOSM`.
typedef PlaceSearch = Future<List<Map<String, dynamic>>> Function(String query);

/// O que a pesquisa de um local mostra: as [suggestions] enquanto não se
/// pesquisa e, depois, o resultado da última pesquisa.
///
/// Uma resposta atrasada de uma pesquisa antiga nunca substitui a mais
/// recente, e uma pesquisa que não responde desiste ao fim de [timeout].
class PlaceSearchState extends ChangeNotifier {
  PlaceSearchState({
    required this.suggestions,
    required this.search,
    this.timeout = const Duration(seconds: 15),
  });

  final List<Map<String, dynamic>> suggestions;
  final PlaceSearch search;
  final Duration timeout;

  List<Map<String, dynamic>>? _results;
  bool _failed = false;
  bool _disposed = false;

  // Cada pesquisa leva um número e só a última pode mostrar resultados.
  int _requestId = 0;

  /// O que listar: o resultado da última pesquisa ou, antes de haver uma (ou
  /// com o campo vazio), as sugestões.
  List<Map<String, dynamic>> get places => _results ?? suggestions;

  /// A última pesquisa não encontrou nada ou falhou (ver [failed]).
  bool get noResults => _results?.isEmpty ?? false;

  /// A última pesquisa falhou: sem rede, erro do serviço ou sem resposta.
  bool get failed => _failed;

  /// Pesquisa [text] já. Com o texto vazio volta às sugestões.
  Future<void> searchNow(String text) async {
    final query = text.trim();
    final requestId = ++_requestId;
    if (query.isEmpty) {
      _show(null);
      return;
    }

    List<Map<String, dynamic>> results;
    try {
      results = await search(query).timeout(timeout);
    } catch (error) {
      if (requestId != _requestId) return;
      developer.log('Pesquisa falhou: $error', name: 'PlaceSearchState');
      _show(const [], failed: true);
      return;
    }
    if (requestId == _requestId) _show(results);
  }

  void _show(List<Map<String, dynamic>>? results, {bool failed = false}) {
    if (_disposed) return;
    _results = results;
    _failed = failed;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  /// O local escolhido no mesmo formato do seletor do mapa, para o ecrã das
  /// moradas guardar igual: `{name, fullName, lat, lng}`.
  static Map<String, dynamic> savedShape(Map<String, dynamic> place) {
    final location = place['latlong'] as LatLng;
    return {
      'name': place['name'] ?? place['fullName'],
      'fullName': place['fullName'],
      'lat': location.latitude,
      'lng': location.longitude,
    };
  }
}
