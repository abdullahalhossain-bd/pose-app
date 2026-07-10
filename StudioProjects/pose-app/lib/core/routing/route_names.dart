/// Named route identifiers.
///
/// Use [RouteNames] for `GoRouter.namedNavigate(...)` so renames of
/// paths don't break navigation calls.
class RouteNames {
  const RouteNames._();

  static const String splash = 'splash';
  static const String onboarding = 'onboarding';
  static const String login = 'login';
  static const String register = 'register';
  static const String forgotPassword = 'forgot-password';
  static const String profileSetup = 'profile-setup';
  static const String permissions = 'permissions';

  static const String home = 'home';
  static const String search = 'search';
  static const String history = 'history';
  static const String settings = 'settings';
  static const String profile = 'profile';
  static const String camera = 'camera';
}
