/// Constantes do produto YA — foundations §10.
///
/// Valores que **não** devem aparecer em magic numbers espalhados pelo código.
abstract class YaConstants {
  // === Negócio ===
  static const double defaultCommissionRate = 12; // %
  static const double lowRatingThreshold = 4.0;
  static const int minRatingsForLowFlag = 5;
  static const int expiringSoonDays = 30;

  // === Uploads ===
  static const int maxVehiclePhotoMb = 5;
  static const int maxDocFileMb = 5;
  static const List<String> acceptedDocFormats = [
    '.pdf',
    '.png',
    '.jpg',
    '.jpeg',
  ];

  // === Localização ===
  static const String currencySuffix = 'MTn';
  static const String countryCode = '+258';
  static const int nuitLength = 9;
  static const int phoneLengthAfterCc = 9;

  // === Surge multipliers ===
  static const Map<String, double> surgeLevels = {
    'normal': 1.0,
    'moderate': 1.3,
    'high': 1.7,
    'extreme': 2.2,
    'maximum': 3.0,
  };

  // === Enums (string-based, alinhados com Firestore) ===
  static const List<String> vehicleTypes = [
    'economico',
    'sedan',
    'limousine',
    'bus',
    'caravan',
    'classico',
    'suv',
    'helicoptero',
  ];

  static const List<String> tripTypes = [
    'regular',
    'scheduled',
    'airport',
    'event',
  ];

  static const List<String> paymentMethods = [
    'mpesa',
    'emola',
    'cartao',
    'cash',
  ];

  static const List<String> roles = ['admin', 'partner', 'support'];

  // === Cidades de Moçambique (para selects) ===
  static const List<String> mozambiqueCities = [
    'Maputo',
    'Matola',
    'Beira',
    'Nampula',
    'Chimoio',
    'Nacala',
    'Quelimane',
    'Tete',
    'Pemba',
    'Inhambane',
    'Xai-Xai',
    'Lichinga',
  ];

  // === Limites de UI ===
  static const int defaultTablePageSize = 20;
  static const int maxDialogsAtOnce = 1;
  static const int maxToastsVisible = 4;
  static const Duration searchDebounce = Duration(milliseconds: 300);
  static const Duration tooltipDelay = Duration(milliseconds: 600);
  static const Duration toastSuccessDuration = Duration(seconds: 4);
  static const Duration toastInfoDuration = Duration(seconds: 5);
  // Erros e warnings: sem auto-dismiss

  // === Auto-refresh ===
  static const Duration dashboardAutoRefresh = Duration(seconds: 60);

  // === Mapa ===
  /// Centro de Maputo — default zoom inicial em mapas live
  static const double maputoLat = -25.9692;
  static const double maputoLng = 32.5732;
  static const double defaultMapZoom = 12;
}
