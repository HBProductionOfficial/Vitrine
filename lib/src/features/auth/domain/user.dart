import 'package:flutter/foundation.dart';

@immutable
class User {
  const User({
    required this.id,
    required this.username,
    required this.email,
    required this.firstName,
    required this.lastName,
    this.image,
    this.phone,
    this.address,
  });

  final int id;
  final String username;
  final String email;
  final String firstName;
  final String lastName;
  final String? image;
  final String? phone;
  final String? address;

  String get fullName => '$firstName $lastName'.trim();

  String get initials {
    final first = firstName.isNotEmpty ? firstName[0] : '';
    final last = lastName.isNotEmpty ? lastName[0] : '';
    return (first + last).toUpperCase();
  }

  factory User.fromJson(Map<String, dynamic> json) {
    final address = json['address'];
    return User(
      id: json['id'] as int,
      username: json['username'] as String? ?? '',
      email: json['email'] as String? ?? '',
      firstName: json['firstName'] as String? ?? '',
      lastName: json['lastName'] as String? ?? '',
      image: json['image'] as String?,
      phone: json['phone'] as String?,
      address: address is Map ? _formatAddress(address) : null,
    );
  }

  static String? _formatAddress(Map<dynamic, dynamic> a) {
    final parts = [
      a['address'],
      a['city'],
      a['state'],
      a['country'],
    ].whereType<String>().where((p) => p.isNotEmpty).toList();
    return parts.isEmpty ? null : parts.join(', ');
  }
}

@immutable
class AuthTokens {
  const AuthTokens({required this.accessToken, required this.refreshToken});

  final String accessToken;
  final String refreshToken;
}

@immutable
class SignUpRequest {
  const SignUpRequest({
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.username,
    required this.password,
  });

  final String firstName;
  final String lastName;
  final String email;
  final String username;
  final String password;

  Map<String, dynamic> toJson() => {
    'firstName': firstName,
    'lastName': lastName,
    'email': email,
    'username': username,
    'password': password,
  };
}
