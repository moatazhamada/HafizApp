package com.hafiz.app.hafiz_app

import android.content.ComponentName
import android.content.pm.PackageManager
import android.os.Build
import android.os.Bundle
import android.view.WindowManager.LayoutParams
import androidx.core.view.WindowCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.hafiz.app/app_icon"

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        
        // Enable edge-to-edge display for Android 15+ (API 35+) compliance
        // Uses the non-deprecated approach with layout params
        WindowCompat.setDecorFitsSystemWindows(window, false)
        
        // For Android 15+, additionally set the edge-to-edge enforcement
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            window.attributes.layoutInDisplayCutoutMode = 
                LayoutParams.LAYOUT_IN_DISPLAY_CUTOUT_MODE_ALWAYS
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "setIconName" -> {
                    val iconName = call.argument<String>("iconName")
                    val success = setAppIcon(iconName)
                    if (success) {
                        result.success(null)
                    } else {
                        result.error("ICON_ERROR", "Failed to set icon", null)
                    }
                }
                "getIconName" -> {
                    val currentIcon = getCurrentIconName()
                    result.success(currentIcon)
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun setAppIcon(iconName: String?): Boolean {
        return try {
            val packageName = packageName
            
            // Disable all icons first
            packageManager.setComponentEnabledSetting(
                ComponentName(packageName, "$packageName.DefaultIcon"),
                PackageManager.COMPONENT_ENABLED_STATE_DISABLED,
                PackageManager.DONT_KILL_APP
            )
            packageManager.setComponentEnabledSetting(
                ComponentName(packageName, "$packageName.RamadanIcon"),
                PackageManager.COMPONENT_ENABLED_STATE_DISABLED,
                PackageManager.DONT_KILL_APP
            )

            // Enable the requested icon
            val componentToEnable = when (iconName) {
                "RamadanIcon" -> "$packageName.RamadanIcon"
                else -> "$packageName.DefaultIcon"
            }
            
            packageManager.setComponentEnabledSetting(
                ComponentName(packageName, componentToEnable),
                PackageManager.COMPONENT_ENABLED_STATE_ENABLED,
                PackageManager.DONT_KILL_APP
            )
            
            true
        } catch (e: Exception) {
            e.printStackTrace()
            false
        }
    }

    private fun getCurrentIconName(): String? {
        return try {
            val packageName = packageName
            
            val defaultEnabled = packageManager.getComponentEnabledSetting(
                ComponentName(packageName, "$packageName.DefaultIcon")
            )
            val ramadanEnabled = packageManager.getComponentEnabledSetting(
                ComponentName(packageName, "$packageName.RamadanIcon")
            )

            when {
                ramadanEnabled == PackageManager.COMPONENT_ENABLED_STATE_ENABLED -> "RamadanIcon"
                defaultEnabled == PackageManager.COMPONENT_ENABLED_STATE_ENABLED -> "DefaultIcon"
                else -> "DefaultIcon" // Default fallback
            }
        } catch (e: Exception) {
            null
        }
    }
}
