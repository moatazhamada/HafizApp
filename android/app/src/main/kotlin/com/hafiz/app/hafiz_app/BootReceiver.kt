package com.hafiz.app.hafiz_app

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Handler
import android.os.Looper
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.dart.DartExecutor
import io.flutter.plugin.common.MethodChannel

/**
 * Reschedules all local notifications after a device reboot.
 *
 * Flutter local notifications are wiped on reboot. This receiver creates
 * a temporary Flutter engine, runs the default Dart entrypoint, and invokes
 * the reschedule method via a MethodChannel after a short delay to allow
 * Dart initialization to complete.
 *
 * If the engine fails to initialize or the Dart side doesn't respond,
 * notifications will be rescheduled on the next normal app launch via
 * [AppInitializer.postInitHeavyTasks].
 */
class BootReceiver : BroadcastReceiver() {
    companion object {
        private const val CHANNEL = "com.hafiz.app.hafiz_app/notifications"
        private const val STARTUP_DELAY_MS = 2000L
    }

    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action != Intent.ACTION_BOOT_COMPLETED &&
            intent.action != "android.intent.action.QUICKBOOT_POWERON"
        ) {
            return
        }

        val pendingResult = goAsync()

        try {
            val engine = FlutterEngine(context)
            engine.dartExecutor.executeDartEntrypoint(
                DartExecutor.DartEntrypoint.createDefault()
            )

            val channel = MethodChannel(
                engine.dartExecutor.binaryMessenger,
                CHANNEL
            )

            // Give Dart time to initialize before invoking the reschedule.
            Handler(Looper.getMainLooper()).postDelayed({
                try {
                    channel.invokeMethod("rescheduleNotifications", null)
                } catch (_: Exception) {
                    // Silently ignore — next app launch will reschedule.
                }
                pendingResult.finish()
            }, STARTUP_DELAY_MS)
        } catch (_: Exception) {
            pendingResult.finish()
        }
    }
}
