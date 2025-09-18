import 'package:flutter/material.dart';
import 'package:vitrine/l10n/gen/app_localizations.dart';

import '../../../../core/biometrics/biometric_service.dart';

String biometricSignInLabel(BiometricKind kind, AppLocalizations l10n) {
  return switch (kind) {
    BiometricKind.face => l10n.biometricFace,
    BiometricKind.fingerprint => l10n.biometricFingerprint,
    BiometricKind.faceOrFingerprint => l10n.biometricFaceOrFingerprint,
    BiometricKind.none || BiometricKind.generic => l10n.biometricGeneric,
  };
}

/// The face, the fingerprint, or both side by side on a phone that has both.
class BiometricGlyph extends StatelessWidget {
  const BiometricGlyph({super.key, required this.kind, this.size = 20, this.color});

  final BiometricKind kind;
  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final face = Icon(Icons.face_rounded, size: size, color: color);
    final fingerprint = Icon(Icons.fingerprint_rounded, size: size, color: color);
    return switch (kind) {
      BiometricKind.face => face,
      BiometricKind.faceOrFingerprint => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          face,
          SizedBox(width: size * 0.15),
          fingerprint,
        ],
      ),
      _ => fingerprint,
    };
  }
}
