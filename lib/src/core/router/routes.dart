abstract final class Routes {
  static const splash = '/splash';
  static const login = '/login';
  static const signUp = '/signup';
  static const forgotPassword = '/forgot-password';

  static const shop = '/shop';
  static const devices = '/devices';
  static const cart = '/cart';
  static const profile = '/profile';

  static const saved = '$shop/saved';

  /// The product page is reachable from several tabs and stays inside the one it was opened from.
  static String product(int id, {String from = shop}) => '$from/product/$id';

  static const signedOutOnly = {login, signUp, forgotPassword};
}
