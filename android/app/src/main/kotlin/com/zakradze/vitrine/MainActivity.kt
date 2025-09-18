package com.zakradze.vitrine

import android.content.pm.PackageManager
import android.os.Build
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

// local_auth shows the system biometric prompt as a fragment, so the
// activity has to be a FragmentActivity.
class MainActivity : FlutterFragmentActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        // local_auth only says how strong the biometrics are, not whether
        // they're a face or a fingerprint, so the app asks for the sensors.
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "vitrine/biometric_hardware")
            .setMethodCallHandler { call, result ->
                if (call.method == "sensors") result.success(sensors()) else result.notImplemented()
            }
    }

    private fun sensors(): List<String> = buildList {
        if (packageManager.hasSystemFeature(PackageManager.FEATURE_FINGERPRINT)) add("fingerprint")
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            if (packageManager.hasSystemFeature(PackageManager.FEATURE_FACE)) add("face")
            if (packageManager.hasSystemFeature(PackageManager.FEATURE_IRIS)) add("iris")
        }
    }
}
