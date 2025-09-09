import 'dart:convert';

import 'package:flutter/foundation.dart';

@immutable
class Device {
  const Device({required this.id, required this.name, this.data = const {}, this.createdByUser = false});

  final String id;
  final String name;

  /// Free-form attributes; every product type on restful-api.dev has its own.
  final Map<String, Object?> data;

  /// The public API only lets you change objects you created yourself.
  final bool createdByUser;

  factory Device.fromJson(Map<String, dynamic> json, {bool createdByUser = false}) {
    final data = json['data'];
    return Device(
      id: json['id'].toString(),
      name: json['name'] as String? ?? '',
      data: data is Map ? Map<String, Object?>.from(data) : const {},
      createdByUser: createdByUser,
    );
  }

  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'data': data, 'createdByUser': createdByUser};

  /// Readable form of an attribute value for the details panel.
  static String formatValue(Object? value) {
    if (value == null) return '-';
    if (value is Map || value is List) return jsonEncode(value);
    if (value is double && value == value.roundToDouble()) return value.toInt().toString();
    return value.toString();
  }
}
