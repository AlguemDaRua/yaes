import 'package:flutter/material.dart' show IconData, Icons;
import 'package:limousineexecutive/utils/asset_paths.dart' show AssetPaths;

/// Decoração visual das categorias de pricing. Sem dados de veículos aqui —
/// os veículos reais vêm do painel do parceiro (espelhados pelo backend em
/// users/{driverUid}/vehicle) e são listados via
/// PassengerState.availableVehicles().
class CarData {
  /// Maps a showcase car type to the real pricing category in
  /// /config/pricing/categories (see lib/services/pricing_service.dart).
  /// The price charged by the server uses this category's multiplier.
  static String categoryFor(String carType) {
    switch (carType) {
      case "Moto":
      case "Moto (Txopela)":
        return "moto";
      case "Txopela":
        return "txopela";
      case "Econômico":
      case "Económico":
        return "economico";
      case "Sedan":
        return "sedan";
      case "Caravan":
        return "caravan";
      case "SUV":
        return "suv";
      case "Bus":
        return "bus";
      case "Clássico":
        return "classico";
      case "Limousine":
        return "limousine";
      case "Helicóptero":
        return "helicoptero";
      default:
        return "economico";
    }
  }

  /// Imagem de montra por categoria de pricing. Categorias sem asset
  /// (ex.: moto) usam [categoryIcon] no seletor.
  static const Map<String, String> categoryImages = {
    'economico': AssetPaths.vitz,
    'sedan': AssetPaths.sedan,
    'caravan': AssetPaths.caravan,
    'suv': AssetPaths.prado,
    'bus': AssetPaths.bus,
    'classico': AssetPaths.classiccar,
    'limousine': AssetPaths.limo,
    'helicoptero': AssetPaths.helicopter,
  };

  // ponytail: sem asset de moto/txopela ainda — ícone até haver imagem real.
  static IconData categoryIcon(String categoryId) {
    switch (categoryId) {
      case 'moto':
        return Icons.two_wheeler;
      case 'txopela':
        return Icons.electric_rickshaw;
      default:
        return Icons.directions_car;
    }
  }
}
