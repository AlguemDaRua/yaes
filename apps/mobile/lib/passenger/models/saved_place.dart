import 'package:latlong2/latlong.dart';

/// Tipo de morada guardada. "Casa" e "Trabalho" têm chave fixa em
/// `users/{uid}/savedLocations`; as outras ("Outros locais") têm chave livre.
enum SavedPlaceKind { home, work, other }

/// Uma morada guardada pelo utilizador em `users/{uid}/savedLocations`.
///
/// Formato guardado: `{name, fullName, lat, lng}` e, opcionalmente, `label`
/// (o nome que o utilizador escolheu, ex.: "Igreja"). As moradas guardadas
/// antes de existir `label` continuam a ser lidas, sem migração.
class SavedPlace {
  const SavedPlace({
    required this.id,
    required this.kind,
    required this.name,
    required this.fullName,
    required this.location,
    this.label,
  });

  /// Chave no Firebase: `home`, `work` ou um identificador livre.
  final String id;

  final SavedPlaceKind kind;

  /// Nome do local. É o que vai para o campo "Para" e para o pedido de viagem.
  final String name;

  /// Endereço completo, mostrado por baixo do nome. Pode estar vazio.
  final String fullName;

  final LatLng location;

  /// Nome escolhido pelo utilizador (ex.: "Igreja"). Nulo nas moradas antigas.
  final String? label;

  /// Nome a mostrar nas listas: o escolhido pelo utilizador; senão "Casa" ou
  /// "Trabalho"; senão o nome do local.
  String get title {
    final chosen = label;
    if (chosen != null) return chosen;
    return switch (kind) {
      SavedPlaceKind.home => 'Casa',
      SavedPlaceKind.work => 'Trabalho',
      SavedPlaceKind.other => name,
    };
  }

  /// Converte para o formato de local/paragem usado nas viagens:
  /// `{name, fullName, type, latlong}`.
  Map<String, dynamic> toPlaceMap() => {
    'name': name,
    'fullName': fullName,
    'type': kind.name,
    'latlong': location,
  };

  /// Tamanho máximo do nome que o utilizador escolhe para uma morada.
  static const maxLabelLength = 30;

  /// O que se guarda em `savedLocations/<chave>`: o local escolhido
  /// (`{name, fullName, lat, lng}`) e, se houver, o nome que o utilizador lhe
  /// deu (`label`, sem espaços nas pontas). É o inverso de [parseAll].
  static Map<String, dynamic> toStored(
    Map<String, dynamic> place, {
    String? label,
  }) {
    final chosen = _text(label);
    return {...place, if (chosen != null) 'label': chosen};
  }

  /// Lê o nó `savedLocations`. É tolerante: ignora entradas inválidas em vez de
  /// falhar. Ordem: Casa, Trabalho e depois as outras, da mais antiga (chave
  /// = hora de criação) para a mais nova.
  static List<SavedPlace> parseAll(Object? raw) {
    if (raw is! Map) return const [];
    final places = <SavedPlace>[];
    raw.forEach((key, value) {
      final place = _parse(key.toString(), value);
      if (place != null) places.add(place);
    });
    places.sort(_compare);
    return List.unmodifiable(places);
  }

  static SavedPlace? _parse(String id, Object? raw) {
    if (raw is! Map) return null;

    final lat = _toDouble(raw['lat']);
    final lng = _toDouble(raw['lng']);
    if (lat == null || lng == null) return null;
    if (!lat.isFinite || !lng.isFinite) return null;
    if (lat < -90 || lat > 90 || lng < -180 || lng > 180) return null;

    final fullName = _text(raw['fullName']);
    final name = _text(raw['name']) ?? fullName;
    if (name == null) return null;

    return SavedPlace(
      id: id,
      kind: _kindOf(id),
      name: name,
      fullName: fullName ?? '',
      location: LatLng(lat, lng),
      label: _text(raw['label']),
    );
  }

  static SavedPlaceKind _kindOf(String id) {
    if (id == 'home') return SavedPlaceKind.home;
    if (id == 'work') return SavedPlaceKind.work;
    return SavedPlaceKind.other;
  }

  static int _compare(SavedPlace a, SavedPlace b) {
    final byKind = a.kind.index.compareTo(b.kind.index);
    if (byKind != 0) return byKind;
    final aTime = int.tryParse(a.id);
    final bTime = int.tryParse(b.id);
    if (aTime != null && bTime != null) return aTime.compareTo(bTime);
    return a.id.compareTo(b.id);
  }

  static String? _text(Object? value) {
    final text = value?.toString().trim();
    return (text == null || text.isEmpty) ? null : text;
  }

  static double? _toDouble(Object? value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '');
  }

  @override
  bool operator ==(Object other) =>
      other is SavedPlace &&
      other.id == id &&
      other.kind == kind &&
      other.name == name &&
      other.fullName == fullName &&
      other.location == location &&
      other.label == label;

  @override
  int get hashCode => Object.hash(id, kind, name, fullName, location, label);
}
