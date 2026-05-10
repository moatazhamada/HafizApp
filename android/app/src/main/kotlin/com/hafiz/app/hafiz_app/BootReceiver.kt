package com.hafiz.app.hafiz_app

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.FlutterEngineCache
import io.flutter.plugin.common.MethodChannel

/**
 * Reschedules the daily verse notification after a device reboot.
 *
 * Flutter local notifications are wiped on reboot. This receiver triggers
 * the Dart-side reschedule via a MethodChannel when the device finishes
 * booting. The FlutterEngine cache must be available (it is set up by
 * MainActivity during normal app launch). If the cache is empty (app was
 * force-stopped), the next app launch will handle rescheduling via
 * app_initializer.dart.
 */
class BootReceiver : BroadcastReceiver() {
    companion object {
        private const val CHANNEL = "com.hafiz.app.hafiz_app/notifications"
    }

    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action != Intent.ACTION_BOOT_COMPLETED &&
            intent.action != "android.intent.action.QUICKBOOT_POWERON"
        ) {
            return
        }

        // Attempt to use a cached Flutter engine; if unavailable the
        // next cold start of the app will handle rescheduling.
        val engine: FlutterEngine? =
            FlutterEngineCache.getInstance().get(ENGINE_ID)
        if (engine != null) {
            MethodChannel(engine.dartExecutor.binaryMessenger, CHANNEL)
                .invokeMethod("rescheduleDailyVerse", null)
        }
    }

    private val ENGINE_ID = "hafiz_app_engine_id"
}
