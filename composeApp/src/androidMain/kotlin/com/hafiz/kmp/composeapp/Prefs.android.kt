package com.hafiz.kmp.composeapp

import android.content.Context
import android.content.SharedPreferences

private fun prefs(): SharedPreferences {
    val ctx: Context = appContext ?: error("Context not initialized")
    return ctx.getSharedPreferences("hafiz_prefs", Context.MODE_PRIVATE)
}

actual fun getBooleanOrNull(key: String): Boolean? =
    if (prefs().contains(key)) prefs().getBoolean(key, false) else null

actual fun putBoolean(key: String, value: Boolean) {
    prefs().edit().putBoolean(key, value).apply()
}

actual fun getStringOrNull(key: String): String? =
    if (prefs().contains(key)) prefs().getString(key, null) else null

actual fun putString(key: String, value: String) {
    prefs().edit().putString(key, value).apply()
}

actual fun getIntOrNull(key: String): Int? =
    if (prefs().contains(key)) prefs().getInt(key, 0) else null

actual fun putInt(key: String, value: Int) {
    prefs().edit().putInt(key, value).apply()
}

