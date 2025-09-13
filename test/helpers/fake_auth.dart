import 'package:mocktail/mocktail.dart';
import 'package:vitrine/src/core/biometrics/biometric_service.dart';
import 'package:vitrine/src/core/network/api_exception.dart';
import 'package:vitrine/src/features/auth/domain/auth_repository.dart';
import 'package:vitrine/src/features/auth/domain/user.dart';

class MockBiometrics extends Mock implements BiometricService {}

const emily = User(id: 1, username: 'emilys', email: 'emily@x.test', firstName: 'Emily', lastName: 'Johnson');

class FakeAuthRepository implements AuthRepository {
  int refreshCalls = 0;
  bool refreshFails = false;

  @override
  Future<(User, AuthTokens)> login(String username, String password) async {
    if (username != 'emilys' || password != 'emilyspass') {
      throw const ApiException(ApiErrorKind.invalidCredentials, statusCode: 400);
    }
    return (emily, const AuthTokens(accessToken: 'access-1', refreshToken: 'refresh-1'));
  }

  @override
  Future<AuthTokens> refresh(String refreshToken) async {
    refreshCalls++;
    if (refreshFails) throw const ApiException(ApiErrorKind.unauthorized, statusCode: 401);
    return const AuthTokens(accessToken: 'access-2', refreshToken: 'refresh-2');
  }

  @override
  Future<User> currentUser() async => emily;

  @override
  Future<int> signUp(SignUpRequest request) async => 209;

  @override
  Future<void> sendPasswordReset(String email) async {}
}
