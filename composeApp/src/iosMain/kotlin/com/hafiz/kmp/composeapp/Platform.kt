package com.hafiz.kmp.composeapp

// TODO: Bundle Quran JSON for iOS and implement real file listing/reading.

internal actual fun platformListAssetFiles(path: String): List<String> = emptyList()

internal actual suspend fun platformReadAsset(path: String): String = "{}"

