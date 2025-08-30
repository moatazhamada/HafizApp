package com.hafiz.kmp.composeapp

import android.content.Context
import androidx.compose.runtime.staticCompositionLocalOf

internal val LocalAppContext = staticCompositionLocalOf<Context> {
    error("Android Context not provided")
}

private var appContext: Context? = null

fun initPlatform(context: Context) {
    appContext = context.applicationContext
}

internal actual fun platformListAssetFiles(path: String): List<String> {
    val ctx = appContext ?: error("Context not initialized")
    return ctx.assets.list(path)?.toList() ?: emptyList()
}

internal actual suspend fun platformReadAsset(path: String): String {
    val ctx = appContext ?: error("Context not initialized")
    return ctx.assets.open(path).bufferedReader(Charsets.UTF_8).use { it.readText() }
}

