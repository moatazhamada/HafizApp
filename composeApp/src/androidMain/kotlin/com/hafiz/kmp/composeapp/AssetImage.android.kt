package com.hafiz.kmp.composeapp

import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import coil.compose.AsyncImage
import coil.request.ImageRequest
import androidx.compose.ui.platform.LocalContext

@Composable
internal actual fun AssetImage(path: String, modifier: Modifier) {
    val ctx = LocalContext.current
    val model = ImageRequest.Builder(ctx)
        .data("file:///android_asset/${'$'}path")
        .build()
    AsyncImage(model = model, contentDescription = null, modifier = modifier)
}

