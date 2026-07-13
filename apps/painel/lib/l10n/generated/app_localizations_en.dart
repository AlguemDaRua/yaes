// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class SEn extends S {
  SEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'YA Dashboard';

  @override
  String get commonSave => 'Save';

  @override
  String get commonCancel => 'Cancel';

  @override
  String get commonConfirm => 'Confirm';

  @override
  String get commonClose => 'Close';

  @override
  String get commonDelete => 'Delete';

  @override
  String get commonEdit => 'Edit';

  @override
  String get commonAdd => 'Add';

  @override
  String get commonSearch => 'Search';

  @override
  String get commonFilter => 'Filter';

  @override
  String get commonExport => 'Export';

  @override
  String get commonLoading => 'Loading...';

  @override
  String get commonNoData => 'No data';

  @override
  String get commonError => 'Error';

  @override
  String get commonRetry => 'Retry';

  @override
  String get commonAll => 'All';

  @override
  String get commonActive => 'Active';

  @override
  String get commonSuspended => 'Suspended';

  @override
  String get commonPending => 'Pending';

  @override
  String get commonStatus => 'Status';

  @override
  String get commonActions => 'Actions';

  @override
  String get commonDate => 'Date';

  @override
  String get commonAmount => 'Amount';

  @override
  String get commonName => 'Name';

  @override
  String get commonPhone => 'Phone';

  @override
  String get commonEmail => 'Email';

  @override
  String get commonPassword => 'Password';

  @override
  String get commonSignOut => 'Sign out';

  @override
  String get commonSettings => 'Settings';

  @override
  String get commonLanguage => 'Language';

  @override
  String get commonExit => 'Exit';

  @override
  String get commonBack => 'Back';

  @override
  String get commonGeneral => 'General';

  @override
  String get commonProfile => 'Profile';

  @override
  String get commonNotifications => 'Notifications';

  @override
  String get commonChangeTheme => 'Change theme';

  @override
  String get authLoginTitle => 'Sign in';

  @override
  String get authLoginSubtitle => 'Access your YA dashboard';

  @override
  String get authLoginEmailPlaceholder => 'you@email.com';

  @override
  String get authLoginPasswordLabel => 'Password';

  @override
  String get authLoginForgotPassword => 'Forgot?';

  @override
  String get authLoginButton => 'Log in';

  @override
  String get authLoginButtonLoading => 'Signing in...';

  @override
  String get authLoginNoAccount => 'No account yet? Contact your admin.';

  @override
  String get authLoginInvalidCredentials => 'Invalid credentials.';

  @override
  String get authLoginEmailRequired => 'Enter email and password.';

  @override
  String get authLoginEmailResetRequired =>
      'Enter your email to receive the link.';

  @override
  String get authLoginResetFailed => 'Could not send the link.';

  @override
  String get authVerifyEmailTitle => 'Verify your email';

  @override
  String authVerifyEmailBody(String email) {
    return 'We sent a confirmation link to $email. Click the link and then press \"I have verified\".';
  }

  @override
  String get authVerifyEmailButton => 'I have verified';

  @override
  String get authVerifyEmailButtonLoading => 'Checking...';

  @override
  String get authVerifyEmailResend => 'Resend email';

  @override
  String get authVerifyEmailNotConfirmed =>
      'You have not confirmed yet. Check your email and try again.';

  @override
  String get authVerifyEmailResent => 'Confirmation email resent.';

  @override
  String get authForgotPasswordTitle => 'Recover access';

  @override
  String get authForgotPasswordSubtitle =>
      'Enter your email to receive the reset link.';

  @override
  String get authForgotPasswordButton => 'Send link';

  @override
  String get authForgotPasswordResend => 'Resend (60s)';

  @override
  String get authBackToLogin => 'Back to login';

  @override
  String authForgotPasswordSuccess(String email) {
    return 'We sent a link to $email.';
  }

  @override
  String authResetSentInfo(String email) {
    return 'We sent a reset link to $email.';
  }

  @override
  String get adminNavDashboard => 'Dashboard';

  @override
  String get adminNavPartners => 'Partners';

  @override
  String get adminNavDrivers => 'Drivers';

  @override
  String get adminNavVehicles => 'Vehicles';

  @override
  String get adminNavTrips => 'Trips';

  @override
  String get adminNavUsers => 'Users';

  @override
  String get adminNavFinance => 'Finance';

  @override
  String get adminNavCommissions => 'Commissions';

  @override
  String get adminNavReports => 'Reports';

  @override
  String get adminNavDocuments => 'Documents';

  @override
  String get adminNavFleets => 'Fleets';

  @override
  String get adminNavAlerts => 'Alerts';

  @override
  String get adminNavAudit => 'Audit';

  @override
  String get adminNavPricing => 'Pricing';

  @override
  String get adminNavNotifications => 'Notifications';

  @override
  String get adminNavSettings => 'Settings';

  @override
  String get adminNavMap => 'Live map';

  @override
  String get adminNavManagement => 'Management';

  @override
  String get adminNavOperations => 'Operations';

  @override
  String get adminNavBusiness => 'Business';

  @override
  String get adminNavSystem => 'System';

  @override
  String get adminDashboardTitle => 'Dashboard';

  @override
  String get adminPartnersTitle => 'Partners';

  @override
  String get adminDriversTitle => 'Drivers';

  @override
  String get adminVehiclesTitle => 'Vehicles';

  @override
  String get adminTripsTitle => 'Trips';

  @override
  String get adminUsersTitle => 'Users';

  @override
  String get adminFinanceTitle => 'Finance';

  @override
  String get adminAlertsTitle => 'Alerts';

  @override
  String get adminAuditTitle => 'Audit';

  @override
  String get adminSettingsTitle => 'Settings';

  @override
  String get adminPartnerApprove => 'Approve';

  @override
  String get adminPartnerSuspend => 'Suspend';

  @override
  String get adminPartnerCreate => 'Create partner';

  @override
  String get adminDriverInvite => 'Invite driver';

  @override
  String get partnerNavDashboard => 'Dashboard';

  @override
  String get partnerNavFleet => 'Fleet';

  @override
  String get partnerNavDrivers => 'Drivers';

  @override
  String get partnerNavVehicles => 'Vehicles';

  @override
  String get partnerNavTrips => 'Trips';

  @override
  String get partnerNavEarnings => 'Earnings';

  @override
  String get partnerNavPerformance => 'Performance';

  @override
  String get partnerNavIncentives => 'Incentives';

  @override
  String get partnerNavAlerts => 'Alerts';

  @override
  String get partnerNavDocuments => 'Documents';

  @override
  String get partnerNavMessages => 'Messages';

  @override
  String get partnerNavSettings => 'Settings';

  @override
  String get partnerNavOperation => 'Operation';

  @override
  String get partnerNavFinance => 'Finance';

  @override
  String get partnerNavCommunication => 'Communication';

  @override
  String get partnerDashboardTitle => 'Dashboard';

  @override
  String get partnerFleetTitle => 'Fleet';

  @override
  String get partnerFleetDrivers => 'Drivers';

  @override
  String get partnerFleetVehicles => 'Vehicles';

  @override
  String get partnerEarningsTitle => 'Earnings';

  @override
  String get supportNavDashboard => 'Dashboard';

  @override
  String get supportNavQueue => 'Queue';

  @override
  String get supportNavTickets => 'Tickets';

  @override
  String get supportNavChat => 'Live chat';

  @override
  String get supportNavDisputes => 'Disputes';

  @override
  String get supportNavPerformance => 'Performance';

  @override
  String get supportNavActions => 'Quick actions';

  @override
  String get supportNavGeneral => 'General';

  @override
  String get supportNavService => 'Service';

  @override
  String get supportNavAnalysis => 'Analysis';

  @override
  String get supportDashboardTitle => 'Dashboard';

  @override
  String get supportTicketsTitle => 'Tickets';

  @override
  String get supportChatTitle => 'Live chat';

  @override
  String get supportQueueTitle => 'Queue';
}
