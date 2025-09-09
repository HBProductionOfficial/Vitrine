import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Tokens for the current session. Lives in memory only; the refresh token
/// is persisted separately by the auth controller when the user asks for it.
class TokenHolder {
  String? accessToken;
  String? refreshToken;

  bool get hasSession => accessToken != null;

  void update({required String access, required String refresh}) {
    accessToken = access;
    refreshToken = refresh;
  }

  void clear() {
    accessToken = null;
    refreshToken = null;
  }
}

final tokenHolderProvider = Provider<TokenHolder>((ref) => TokenHolder());
