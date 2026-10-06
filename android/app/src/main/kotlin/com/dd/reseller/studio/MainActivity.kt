package com.dd.reseller.studio

import android.Manifest
import android.app.NotificationManager
import android.content.ActivityNotFoundException
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/**
 * Hosts the `system_permissions` channel, the Android half of
 * `ios/Runner/SystemPermissionsPlugin.swift`.
 *
 * Android asks again after a first refusal, so "blocked" means the system
 * will no longer show the dialog: not granted, and no rationale to show.
 * That reading is only true once the app has asked, so Dart calls it after
 * a refusal and never before one.
 */
class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "isBlocked" -> result.success(isBlocked(call.argument<String>("permission")))
                    "openAppSettings" -> result.success(openAppSettings())
                    else -> result.notImplemented()
                }
            }
    }

    private fun isBlocked(permission: String?): Boolean = when (permission) {
        "camera" -> isRefusedForGood(Manifest.permission.CAMERA)
        "notifications" -> !areNotificationsEnabled() &&
            (Build.VERSION.SDK_INT < Build.VERSION_CODES.TIRAMISU ||
                isRefusedForGood(Manifest.permission.POST_NOTIFICATIONS))
        // The system photo picker needs no permission, so there is nothing to block.
        else -> false
    }

    private fun isRefusedForGood(permission: String): Boolean =
        Build.VERSION.SDK_INT >= Build.VERSION_CODES.M &&
            checkSelfPermission(permission) != PackageManager.PERMISSION_GRANTED &&
            !shouldShowRequestPermissionRationale(permission)

    // Below Android 13 notifications are on unless switched off in Settings.
    private fun areNotificationsEnabled(): Boolean =
        Build.VERSION.SDK_INT < Build.VERSION_CODES.N ||
            getSystemService(NotificationManager::class.java).areNotificationsEnabled()

    private fun openAppSettings(): Boolean = try {
        startActivity(
            Intent(
                Settings.ACTION_APPLICATION_DETAILS_SETTINGS,
                Uri.fromParts("package", packageName, null),
            ).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK),
        )
        true
    } catch (error: ActivityNotFoundException) {
        // Answered as false; the Dart side logs the refusal.
        false
    }

    private companion object {
        const val CHANNEL = "app.dd.reseller.studio/system_permissions"
    }
}
