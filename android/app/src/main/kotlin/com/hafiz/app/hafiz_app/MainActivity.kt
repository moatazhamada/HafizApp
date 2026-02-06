package com.hafiz.app.hafiz_app

import android.os.Build
import android.os.Bundle
import android.view.WindowManager.LayoutParams
import androidx.core.view.WindowCompat
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
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
}
