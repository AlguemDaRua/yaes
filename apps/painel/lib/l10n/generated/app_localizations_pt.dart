// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Portuguese (`pt`).
class SPt extends S {
  SPt([String locale = 'pt']) : super(locale);

  @override
  String get appTitle => 'YA Painel';

  @override
  String get commonSave => 'Guardar';

  @override
  String get commonCancel => 'Cancelar';

  @override
  String get commonConfirm => 'Confirmar';

  @override
  String get commonClose => 'Fechar';

  @override
  String get commonDelete => 'Eliminar';

  @override
  String get commonEdit => 'Editar';

  @override
  String get commonAdd => 'Adicionar';

  @override
  String get commonSearch => 'Pesquisar';

  @override
  String get commonFilter => 'Filtrar';

  @override
  String get commonExport => 'Exportar';

  @override
  String get commonLoading => 'A carregar...';

  @override
  String get commonNoData => 'Sem dados';

  @override
  String get commonError => 'Erro';

  @override
  String get commonRetry => 'Tentar novamente';

  @override
  String get commonAll => 'Todos';

  @override
  String get commonActive => 'Activo';

  @override
  String get commonSuspended => 'Suspenso';

  @override
  String get commonPending => 'Pendente';

  @override
  String get commonStatus => 'Estado';

  @override
  String get commonActions => 'Acções';

  @override
  String get commonDate => 'Data';

  @override
  String get commonAmount => 'Valor';

  @override
  String get commonName => 'Nome';

  @override
  String get commonPhone => 'Telefone';

  @override
  String get commonEmail => 'Email';

  @override
  String get commonPassword => 'Palavra-passe';

  @override
  String get commonSignOut => 'Terminar sessão';

  @override
  String get commonSettings => 'Configurações';

  @override
  String get commonLanguage => 'Idioma';

  @override
  String get commonExit => 'Sair';

  @override
  String get commonBack => 'Voltar';

  @override
  String get commonGeneral => 'Geral';

  @override
  String get commonProfile => 'Perfil';

  @override
  String get commonNotifications => 'Notificações';

  @override
  String get commonChangeTheme => 'Mudar tema';

  @override
  String get authLoginTitle => 'Iniciar sessão';

  @override
  String get authLoginSubtitle => 'Acede ao teu painel YA';

  @override
  String get authLoginEmailPlaceholder => 'teu@email.com';

  @override
  String get authLoginPasswordLabel => 'Palavra-passe';

  @override
  String get authLoginForgotPassword => 'Esqueci-me?';

  @override
  String get authLoginButton => 'Entrar';

  @override
  String get authLoginButtonLoading => 'A entrar...';

  @override
  String get authLoginNoAccount =>
      'Ainda não tens conta? Contacta o teu admin.';

  @override
  String get authLoginInvalidCredentials => 'Credenciais inválidas.';

  @override
  String get authLoginEmailRequired => 'Introduz email e palavra-passe.';

  @override
  String get authLoginEmailResetRequired =>
      'Introduz o email para receber o link.';

  @override
  String get authLoginResetFailed => 'Não foi possível enviar.';

  @override
  String get authVerifyEmailTitle => 'Verifica o teu email';

  @override
  String authVerifyEmailBody(String email) {
    return 'Enviamos um link de confirmação para $email. Clica no link e depois carrega em \"Já verifiquei\".';
  }

  @override
  String get authVerifyEmailButton => 'Já verifiquei';

  @override
  String get authVerifyEmailButtonLoading => 'A verificar...';

  @override
  String get authVerifyEmailResend => 'Reenviar email';

  @override
  String get authVerifyEmailNotConfirmed =>
      'Ainda não confirmaste. Verifica o email e tenta de novo.';

  @override
  String get authVerifyEmailResent => 'Email de confirmação reenviado.';

  @override
  String get authForgotPasswordTitle => 'Recuperar acesso';

  @override
  String get authForgotPasswordSubtitle =>
      'Introduz o teu email para receber o link de reset.';

  @override
  String get authForgotPasswordButton => 'Enviar link';

  @override
  String get authForgotPasswordResend => 'Reenviar (60s)';

  @override
  String get authBackToLogin => 'Voltar ao login';

  @override
  String authForgotPasswordSuccess(String email) {
    return 'Enviámos um link para $email.';
  }

  @override
  String authResetSentInfo(String email) {
    return 'Enviamos um link de reset para $email.';
  }

  @override
  String get adminNavDashboard => 'Dashboard';

  @override
  String get adminNavPartners => 'Partners';

  @override
  String get adminNavDrivers => 'Drivers';

  @override
  String get adminNavVehicles => 'Veículos';

  @override
  String get adminNavTrips => 'Corridas';

  @override
  String get adminNavUsers => 'Utilizadores';

  @override
  String get adminNavFinance => 'Finanças';

  @override
  String get adminNavCommissions => 'Comissões';

  @override
  String get adminNavReports => 'Relatórios';

  @override
  String get adminNavDocuments => 'Documentos';

  @override
  String get adminNavFleets => 'Frotas';

  @override
  String get adminNavAlerts => 'Alertas';

  @override
  String get adminNavAudit => 'Auditoria';

  @override
  String get adminNavPricing => 'Preços';

  @override
  String get adminNavNotifications => 'Notificações';

  @override
  String get adminNavSettings => 'Configurações';

  @override
  String get adminNavMap => 'Mapa live';

  @override
  String get adminNavManagement => 'Gestão';

  @override
  String get adminNavOperations => 'Operações';

  @override
  String get adminNavBusiness => 'Negócio';

  @override
  String get adminNavSystem => 'Sistema';

  @override
  String get adminDashboardTitle => 'Dashboard';

  @override
  String get adminPartnersTitle => 'Partners';

  @override
  String get adminDriversTitle => 'Drivers';

  @override
  String get adminVehiclesTitle => 'Veículos';

  @override
  String get adminTripsTitle => 'Corridas';

  @override
  String get adminUsersTitle => 'Utilizadores';

  @override
  String get adminFinanceTitle => 'Finanças';

  @override
  String get adminAlertsTitle => 'Alertas';

  @override
  String get adminAuditTitle => 'Auditoria';

  @override
  String get adminSettingsTitle => 'Configurações';

  @override
  String get adminPartnerApprove => 'Aprovar';

  @override
  String get adminPartnerSuspend => 'Suspender';

  @override
  String get adminPartnerCreate => 'Criar partner';

  @override
  String get adminDriverInvite => 'Convidar driver';

  @override
  String get partnerNavDashboard => 'Dashboard';

  @override
  String get partnerNavFleet => 'Frota';

  @override
  String get partnerNavDrivers => 'Motoristas';

  @override
  String get partnerNavVehicles => 'Veículos';

  @override
  String get partnerNavTrips => 'Corridas';

  @override
  String get partnerNavEarnings => 'Ganhos';

  @override
  String get partnerNavPerformance => 'Desempenho';

  @override
  String get partnerNavIncentives => 'Incentivos';

  @override
  String get partnerNavAlerts => 'Alertas';

  @override
  String get partnerNavDocuments => 'Documentos';

  @override
  String get partnerNavMessages => 'Mensagens';

  @override
  String get partnerNavSettings => 'Configurações';

  @override
  String get partnerNavOperation => 'Operação';

  @override
  String get partnerNavFinance => 'Financeiro';

  @override
  String get partnerNavCommunication => 'Comunicação';

  @override
  String get partnerDashboardTitle => 'Dashboard';

  @override
  String get partnerFleetTitle => 'Frota';

  @override
  String get partnerFleetDrivers => 'Drivers';

  @override
  String get partnerFleetVehicles => 'Veículos';

  @override
  String get partnerEarningsTitle => 'Ganhos';

  @override
  String get supportNavDashboard => 'Dashboard';

  @override
  String get supportNavQueue => 'Fila';

  @override
  String get supportNavTickets => 'Tickets';

  @override
  String get supportNavChat => 'Chat ao vivo';

  @override
  String get supportNavDisputes => 'Disputas';

  @override
  String get supportNavPerformance => 'Desempenho';

  @override
  String get supportNavActions => 'Acções rápidas';

  @override
  String get supportNavGeneral => 'Geral';

  @override
  String get supportNavService => 'Atendimento';

  @override
  String get supportNavAnalysis => 'Análise';

  @override
  String get supportDashboardTitle => 'Dashboard';

  @override
  String get supportTicketsTitle => 'Tickets';

  @override
  String get supportChatTitle => 'Chat ao vivo';

  @override
  String get supportQueueTitle => 'Fila de espera';
}
