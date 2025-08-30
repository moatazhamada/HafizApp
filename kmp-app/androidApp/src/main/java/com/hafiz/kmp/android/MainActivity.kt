package com.hafiz.kmp.android

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import com.hafiz.kmp.composeapp.App
import com.hafiz.kmp.composeapp.initPlatform

class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        initPlatform(applicationContext)
        setContent { App() }
    }
}
