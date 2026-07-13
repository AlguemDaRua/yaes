import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_pt.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of S
/// returned by `S.of(context)`.
///
/// Applications need to include `S.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: S.localizationsDelegates,
///   supportedLocales: S.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the S.supportedLocales
/// property.
abstract class S {
  S(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static S of(BuildContext context) {
    return Localizations.of<S>(context, S)!;
  }

  static const LocalizationsDelegate<S> delegate = _SDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('pt')
  ];

  /// No description provided for @appTitle.
  ///
  /// In pt, this message translates to:
  /// **'YA Painel'**
  String get appTitle;

  /// No description provided for @commonSave.
  ///
  /// In pt, this message translates to:
  /// **'Guardar'**
  String get commonSave;

  /// No description provided for @commonCancel.
  ///
  /// In pt, this message translates to:
  /// **'Cancelar'**
  String get commonCancel;

  /// No description provided for @commonConfirm.
  ///
  /// In pt, this message translates to:
  /// **'Confirmar'**
  String get commonConfirm;

  /// No description provided for @commonClose.
  ///
  /// In pt, this message translates to:
  /// **'Fechar'**
  String get commonClose;

  /// No description provided for @commonDelete.
  ///
  /// In pt, this message translates to:
  /// **'Eliminar'**
  String get commonDelete;

  /// No description provided for @commonEdit.
  ///
  /// In pt, this message translates to:
  /// **'Editar'**
  String get commonEdit;

  /// No description provided for @commonAdd.
  ///
  /// In pt, this message translates to:
  /// **'Adicionar'**
  String get commonAdd;

  /// No description provided for @commonSearch.
  ///
  /// In pt, this message translates to:
  /// **'Pesquisar'**
  String get commonSearch;

  /// No description provided for @commonFilter.
  ///
  /// In pt, this message translates to:
  /// **'Filtrar'**
  String get commonFilter;

  /// No description provided for @commonExport.
  ///
  /// In pt, this message translates to:
  /// **'Exportar'**
  String get commonExport;

  /// No description provided for @commonLoading.
  ///
  /// In pt, this message translates to:
  /// **'A carregar...'**
  String get commonLoading;

  /// No description provided for @commonNoData.
  ///
  /// In pt, this message translates to:
  /// **'Sem dados'**
  String get commonNoData;

  /// No description provided for @commonError.
  ///
  /// In pt, this message translates to:
  /// **'Erro'**
  String get commonError;

  /// No description provided for @commonRetry.
  ///
  /// In pt, this message translates to:
  /// **'Tentar novamente'**
  String get commonRetry;

  /// No description provided for @commonAll.
  ///
  /// In pt, this message translates to:
  /// **'Todos'**
  String get commonAll;

  /// No description provided for @commonActive.
  ///
  /// In pt, this message translates to:
  /// **'Activo'**
  String get commonActive;

  /// No description provided for @commonSuspended.
  ///
  /// In pt, this message translates to:
  /// **'Suspenso'**
  String get commonSuspended;

  /// No description provided for @commonPending.
  ///
  /// In pt, this message translates to:
  /// **'Pendente'**
  String get commonPending;

  /// No description provided for @commonStatus.
  ///
  /// In pt, this message translates to:
  /// **'Estado'**
  String get commonStatus;

  /// No description provided for @commonActions.
  ///
  /// In pt, this message translates to:
  /// **'Acções'**
  String get commonActions;

  /// No description provided for @commonDate.
  ///
  /// In pt, this message translates to:
  /// **'Data'**
  String get commonDate;

  /// No description provided for @commonAmount.
  ///
  /// In pt, this message translates to:
  /// **'Valor'**
  String get commonAmount;

  /// No description provided for @commonName.
  ///
  /// In pt, this message translates to:
  /// **'Nome'**
  String get commonName;

  /// No description provided for @commonPhone.
  ///
  /// In pt, this message translates to:
  /// **'Telefone'**
  String get commonPhone;

  /// No description provided for @commonEmail.
  ///
  /// In pt, this message translates to:
  /// **'Email'**
  String get commonEmail;

  /// No description provided for @commonPassword.
  ///
  /// In pt, this message translates to:
  /// **'Palavra-passe'**
  String get commonPassword;

  /// No description provided for @commonSignOut.
  ///
  /// In pt, this message translates to:
  /// **'Terminar sessão'**
  String get commonSignOut;

  /// No description provided for @commonSettings.
  ///
  /// In pt, this message translates to:
  /// **'Configurações'**
  String get commonSettings;

  /// No description provided for @commonLanguage.
  ///
  /// In pt, this message translates to:
  /// **'Idioma'**
  String get commonLanguage;

  /// No description provided for @commonExit.
  ///
  /// In pt, this message translates to:
  /// **'Sair'**
  String get commonExit;

  /// No description provided for @commonBack.
  ///
  /// In pt, this message translates to:
  /// **'Voltar'**
  String get commonBack;

  /// No description provided for @commonGeneral.
  ///
  /// In pt, this message translates to:
  /// **'Geral'**
  String get commonGeneral;

  /// No description provided for @commonProfile.
  ///
  /// In pt, this message translates to:
  /// **'Perfil'**
  String get commonProfile;

  /// No description provided for @commonNotifications.
  ///
  /// In pt, this message translates to:
  /// **'Notificações'**
  String get commonNotifications;

  /// No description provided for @commonChangeTheme.
  ///
  /// In pt, this message translates to:
  /// **'Mudar tema'**
  String get commonChangeTheme;

  /// No description provided for @authLoginTitle.
  ///
  /// In pt, this message translates to:
  /// **'Iniciar sessão'**
  String get authLoginTitle;

  /// No description provided for @authLoginSubtitle.
  ///
  /// In pt, this message translates to:
  /// **'Acede ao teu painel YA'**
  String get authLoginSubtitle;

  /// No description provided for @authLoginEmailPlaceholder.
  ///
  /// In pt, this message translates to:
  /// **'teu@email.com'**
  String get authLoginEmailPlaceholder;

  /// No description provided for @authLoginPasswordLabel.
  ///
  /// In pt, this message translates to:
  /// **'Palavra-passe'**
  String get authLoginPasswordLabel;

  /// No description provided for @authLoginForgotPassword.
  ///
  /// In pt, this message translates to:
  /// **'Esqueci-me?'**
  String get authLoginForgotPassword;

  /// No description provided for @authLoginButton.
  ///
  /// In pt, this message translates to:
  /// **'Entrar'**
  String get authLoginButton;

  /// No description provided for @authLoginButtonLoading.
  ///
  /// In pt, this message translates to:
  /// **'A entrar...'**
  String get authLoginButtonLoading;

  /// No description provided for @authLoginNoAccount.
  ///
  /// In pt, this message translates to:
  /// **'Ainda não tens conta? Contacta o teu admin.'**
  String get authLoginNoAccount;

  /// No description provided for @authLoginInvalidCredentials.
  ///
  /// In pt, this message translates to:
  /// **'Credenciais inválidas.'**
  String get authLoginInvalidCredentials;

  /// No description provided for @authLoginEmailRequired.
  ///
  /// In pt, this message translates to:
  /// **'Introduz email e palavra-passe.'**
  String get authLoginEmailRequired;

  /// No description provided for @authLoginEmailResetRequired.
  ///
  /// In pt, this message translates to:
  /// **'Introduz o email para receber o link.'**
  String get authLoginEmailResetRequired;

  /// No description provided for @authLoginResetFailed.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível enviar.'**
  String get authLoginResetFailed;

  /// No description provided for @authVerifyEmailTitle.
  ///
  /// In pt, this message translates to:
  /// **'Verifica o teu email'**
  String get authVerifyEmailTitle;

  /// No description provided for @authVerifyEmailBody.
  ///
  /// In pt, this message translates to:
  /// **'Enviamos um link de confirmação para {email}. Clica no link e depois carrega em \"Já verifiquei\".'**
  String authVerifyEmailBody(String email);

  /// No description provided for @authVerifyEmailButton.
  ///
  /// In pt, this message translates to:
  /// **'Já verifiquei'**
  String get authVerifyEmailButton;

  /// No description provided for @authVerifyEmailButtonLoading.
  ///
  /// In pt, this message translates to:
  /// **'A verificar...'**
  String get authVerifyEmailButtonLoading;

  /// No description provided for @authVerifyEmailResend.
  ///
  /// In pt, this message translates to:
  /// **'Reenviar email'**
  String get authVerifyEmailResend;

  /// No description provided for @authVerifyEmailNotConfirmed.
  ///
  /// In pt, this message translates to:
  /// **'Ainda não confirmaste. Verifica o email e tenta de novo.'**
  String get authVerifyEmailNotConfirmed;

  /// No description provided for @authVerifyEmailResent.
  ///
  /// In pt, this message translates to:
  /// **'Email de confirmação reenviado.'**
  String get authVerifyEmailResent;

  /// No description provided for @authForgotPasswordTitle.
  ///
  /// In pt, this message translates to:
  /// **'Recuperar acesso'**
  String get authForgotPasswordTitle;

  /// No description provided for @authForgotPasswordSubtitle.
  ///
  /// In pt, this message translates to:
  /// **'Introduz o teu email para receber o link de reset.'**
  String get authForgotPasswordSubtitle;

  /// No description provided for @authForgotPasswordButton.
  ///
  /// In pt, this message translates to:
  /// **'Enviar link'**
  String get authForgotPasswordButton;

  /// No description provided for @authForgotPasswordResend.
  ///
  /// In pt, this message translates to:
  /// **'Reenviar (60s)'**
  String get authForgotPasswordResend;

  /// No description provided for @authBackToLogin.
  ///
  /// In pt, this message translates to:
  /// **'Voltar ao login'**
  String get authBackToLogin;

  /// No description provided for @authForgotPasswordSuccess.
  ///
  /// In pt, this message translates to:
  /// **'Enviámos um link para {email}.'**
  String authForgotPasswordSuccess(String email);

  /// No description provided for @authResetSentInfo.
  ///
  /// In pt, this message translates to:
  /// **'Enviamos um link de reset para {email}.'**
  String authResetSentInfo(String email);

  /// No description provided for @adminNavDashboard.
  ///
  /// In pt, this message translates to:
  /// **'Dashboard'**
  String get adminNavDashboard;

  /// No description provided for @adminNavPartners.
  ///
  /// In pt, this message translates to:
  /// **'Partners'**
  String get adminNavPartners;

  /// No description provided for @adminNavDrivers.
  ///
  /// In pt, this message translates to:
  /// **'Drivers'**
  String get adminNavDrivers;

  /// No description provided for @adminNavVehicles.
  ///
  /// In pt, this message translates to:
  /// **'Veículos'**
  String get adminNavVehicles;

  /// No description provided for @adminNavTrips.
  ///
  /// In pt, this message translates to:
  /// **'Corridas'**
  String get adminNavTrips;

  /// No description provided for @adminNavUsers.
  ///
  /// In pt, this message translates to:
  /// **'Utilizadores'**
  String get adminNavUsers;

  /// No description provided for @adminNavFinance.
  ///
  /// In pt, this message translates to:
  /// **'Finanças'**
  String get adminNavFinance;

  /// No description provided for @adminNavCommissions.
  ///
  /// In pt, this message translates to:
  /// **'Comissões'**
  String get adminNavCommissions;

  /// No description provided for @adminNavReports.
  ///
  /// In pt, this message translates to:
  /// **'Relatórios'**
  String get adminNavReports;

  /// No description provided for @adminNavDocuments.
  ///
  /// In pt, this message translates to:
  /// **'Documentos'**
  String get adminNavDocuments;

  /// No description provided for @adminNavFleets.
  ///
  /// In pt, this message translates to:
  /// **'Frotas'**
  String get adminNavFleets;

  /// No description provided for @adminNavAlerts.
  ///
  /// In pt, this message translates to:
  /// **'Alertas'**
  String get adminNavAlerts;

  /// No description provided for @adminNavAudit.
  ///
  /// In pt, this message translates to:
  /// **'Auditoria'**
  String get adminNavAudit;

  /// No description provided for @adminNavPricing.
  ///
  /// In pt, this message translates to:
  /// **'Preços'**
  String get adminNavPricing;

  /// No description provided for @adminNavNotifications.
  ///
  /// In pt, this message translates to:
  /// **'Notificações'**
  String get adminNavNotifications;

  /// No description provided for @adminNavSettings.
  ///
  /// In pt, this message translates to:
  /// **'Configurações'**
  String get adminNavSettings;

  /// No description provided for @adminNavMap.
  ///
  /// In pt, this message translates to:
  /// **'Mapa live'**
  String get adminNavMap;

  /// No description provided for @adminNavManagement.
  ///
  /// In pt, this message translates to:
  /// **'Gestão'**
  String get adminNavManagement;

  /// No description provided for @adminNavOperations.
  ///
  /// In pt, this message translates to:
  /// **'Operações'**
  String get adminNavOperations;

  /// No description provided for @adminNavBusiness.
  ///
  /// In pt, this message translates to:
  /// **'Negócio'**
  String get adminNavBusiness;

  /// No description provided for @adminNavSystem.
  ///
  /// In pt, this message translates to:
  /// **'Sistema'**
  String get adminNavSystem;

  /// No description provided for @adminDashboardTitle.
  ///
  /// In pt, this message translates to:
  /// **'Dashboard'**
  String get adminDashboardTitle;

  /// No description provided for @adminPartnersTitle.
  ///
  /// In pt, this message translates to:
  /// **'Partners'**
  String get adminPartnersTitle;

  /// No description provided for @adminDriversTitle.
  ///
  /// In pt, this message translates to:
  /// **'Drivers'**
  String get adminDriversTitle;

  /// No description provided for @adminVehiclesTitle.
  ///
  /// In pt, this message translates to:
  /// **'Veículos'**
  String get adminVehiclesTitle;

  /// No description provided for @adminTripsTitle.
  ///
  /// In pt, this message translates to:
  /// **'Corridas'**
  String get adminTripsTitle;

  /// No description provided for @adminUsersTitle.
  ///
  /// In pt, this message translates to:
  /// **'Utilizadores'**
  String get adminUsersTitle;

  /// No description provided for @adminFinanceTitle.
  ///
  /// In pt, this message translates to:
  /// **'Finanças'**
  String get adminFinanceTitle;

  /// No description provided for @adminAlertsTitle.
  ///
  /// In pt, this message translates to:
  /// **'Alertas'**
  String get adminAlertsTitle;

  /// No description provided for @adminAuditTitle.
  ///
  /// In pt, this message translates to:
  /// **'Auditoria'**
  String get adminAuditTitle;

  /// No description provided for @adminSettingsTitle.
  ///
  /// In pt, this message translates to:
  /// **'Configurações'**
  String get adminSettingsTitle;

  /// No description provided for @adminPartnerApprove.
  ///
  /// In pt, this message translates to:
  /// **'Aprovar'**
  String get adminPartnerApprove;

  /// No description provided for @adminPartnerSuspend.
  ///
  /// In pt, this message translates to:
  /// **'Suspender'**
  String get adminPartnerSuspend;

  /// No description provided for @adminPartnerCreate.
  ///
  /// In pt, this message translates to:
  /// **'Criar partner'**
  String get adminPartnerCreate;

  /// No description provided for @adminDriverInvite.
  ///
  /// In pt, this message translates to:
  /// **'Convidar driver'**
  String get adminDriverInvite;

  /// No description provided for @partnerNavDashboard.
  ///
  /// In pt, this message translates to:
  /// **'Dashboard'**
  String get partnerNavDashboard;

  /// No description provided for @partnerNavFleet.
  ///
  /// In pt, this message translates to:
  /// **'Frota'**
  String get partnerNavFleet;

  /// No description provided for @partnerNavDrivers.
  ///
  /// In pt, this message translates to:
  /// **'Motoristas'**
  String get partnerNavDrivers;

  /// No description provided for @partnerNavVehicles.
  ///
  /// In pt, this message translates to:
  /// **'Veículos'**
  String get partnerNavVehicles;

  /// No description provided for @partnerNavTrips.
  ///
  /// In pt, this message translates to:
  /// **'Corridas'**
  String get partnerNavTrips;

  /// No description provided for @partnerNavEarnings.
  ///
  /// In pt, this message translates to:
  /// **'Ganhos'**
  String get partnerNavEarnings;

  /// No description provided for @partnerNavPerformance.
  ///
  /// In pt, this message translates to:
  /// **'Desempenho'**
  String get partnerNavPerformance;

  /// No description provided for @partnerNavIncentives.
  ///
  /// In pt, this message translates to:
  /// **'Incentivos'**
  String get partnerNavIncentives;

  /// No description provided for @partnerNavAlerts.
  ///
  /// In pt, this message translates to:
  /// **'Alertas'**
  String get partnerNavAlerts;

  /// No description provided for @partnerNavDocuments.
  ///
  /// In pt, this message translates to:
  /// **'Documentos'**
  String get partnerNavDocuments;

  /// No description provided for @partnerNavMessages.
  ///
  /// In pt, this message translates to:
  /// **'Mensagens'**
  String get partnerNavMessages;

  /// No description provided for @partnerNavSettings.
  ///
  /// In pt, this message translates to:
  /// **'Configurações'**
  String get partnerNavSettings;

  /// No description provided for @partnerNavOperation.
  ///
  /// In pt, this message translates to:
  /// **'Operação'**
  String get partnerNavOperation;

  /// No description provided for @partnerNavFinance.
  ///
  /// In pt, this message translates to:
  /// **'Financeiro'**
  String get partnerNavFinance;

  /// No description provided for @partnerNavCommunication.
  ///
  /// In pt, this message translates to:
  /// **'Comunicação'**
  String get partnerNavCommunication;

  /// No description provided for @partnerDashboardTitle.
  ///
  /// In pt, this message translates to:
  /// **'Dashboard'**
  String get partnerDashboardTitle;

  /// No description provided for @partnerFleetTitle.
  ///
  /// In pt, this message translates to:
  /// **'Frota'**
  String get partnerFleetTitle;

  /// No description provided for @partnerFleetDrivers.
  ///
  /// In pt, this message translates to:
  /// **'Drivers'**
  String get partnerFleetDrivers;

  /// No description provided for @partnerFleetVehicles.
  ///
  /// In pt, this message translates to:
  /// **'Veículos'**
  String get partnerFleetVehicles;

  /// No description provided for @partnerEarningsTitle.
  ///
  /// In pt, this message translates to:
  /// **'Ganhos'**
  String get partnerEarningsTitle;

  /// No description provided for @supportNavDashboard.
  ///
  /// In pt, this message translates to:
  /// **'Dashboard'**
  String get supportNavDashboard;

  /// No description provided for @supportNavQueue.
  ///
  /// In pt, this message translates to:
  /// **'Fila'**
  String get supportNavQueue;

  /// No description provided for @supportNavTickets.
  ///
  /// In pt, this message translates to:
  /// **'Tickets'**
  String get supportNavTickets;

  /// No description provided for @supportNavChat.
  ///
  /// In pt, this message translates to:
  /// **'Chat ao vivo'**
  String get supportNavChat;

  /// No description provided for @supportNavDisputes.
  ///
  /// In pt, this message translates to:
  /// **'Disputas'**
  String get supportNavDisputes;

  /// No description provided for @supportNavPerformance.
  ///
  /// In pt, this message translates to:
  /// **'Desempenho'**
  String get supportNavPerformance;

  /// No description provided for @supportNavActions.
  ///
  /// In pt, this message translates to:
  /// **'Acções rápidas'**
  String get supportNavActions;

  /// No description provided for @supportNavGeneral.
  ///
  /// In pt, this message translates to:
  /// **'Geral'**
  String get supportNavGeneral;

  /// No description provided for @supportNavService.
  ///
  /// In pt, this message translates to:
  /// **'Atendimento'**
  String get supportNavService;

  /// No description provided for @supportNavAnalysis.
  ///
  /// In pt, this message translates to:
  /// **'Análise'**
  String get supportNavAnalysis;

  /// No description provided for @supportDashboardTitle.
  ///
  /// In pt, this message translates to:
  /// **'Dashboard'**
  String get supportDashboardTitle;

  /// No description provided for @supportTicketsTitle.
  ///
  /// In pt, this message translates to:
  /// **'Tickets'**
  String get supportTicketsTitle;

  /// No description provided for @supportChatTitle.
  ///
  /// In pt, this message translates to:
  /// **'Chat ao vivo'**
  String get supportChatTitle;

  /// No description provided for @supportQueueTitle.
  ///
  /// In pt, this message translates to:
  /// **'Fila de espera'**
  String get supportQueueTitle;
}

class _SDelegate extends LocalizationsDelegate<S> {
  const _SDelegate();

  @override
  Future<S> load(Locale locale) {
    return SynchronousFuture<S>(lookupS(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'pt'].contains(locale.languageCode);

  @override
  bool shouldReload(_SDelegate old) => false;
}

S lookupS(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return SEn();
    case 'pt':
      return SPt();
  }

  throw FlutterError(
      'S.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
