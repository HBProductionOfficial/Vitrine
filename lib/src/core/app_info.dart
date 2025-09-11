import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// The version from pubspec.yaml, so the screens never drift from the build.
final appVersionProvider = FutureProvider<String>((ref) async => (await PackageInfo.fromPlatform()).version);
