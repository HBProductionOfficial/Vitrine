import 'user.dart';

abstract class AuthRepository {
  Future<(User, AuthTokens)> login(String username, String password);

  Future<AuthTokens> refresh(String refreshToken);

  /// Full profile of the signed-in user, including phone and address.
  Future<User> currentUser();

  /// Returns the id the server assigned to the new account.
  Future<int> signUp(SignUpRequest request);

  Future<void> sendPasswordReset(String email);
}
