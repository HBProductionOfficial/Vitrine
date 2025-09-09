abstract final class Routes {
  static const splash = '/splash';
  static const login = '/login';
  static const signUp = '/signup';
  static const forgotPassword = '/forgot-password';

  static const shop = '/shop';
  static const devices = '/devices';
  static const cart = '/cart';
  static const profile = '/profile';

  static const signedOutOnly = {login, signUp, forgotPassword};
}
