package com.hafiz.kmp.composeapp

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.Immutable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.unit.dp

@Immutable
data class HafizColors(
    val primary: Color = Color(0xFF006754),
    val secondary: Color = Color(0xFF87D1A4),
    val darkBg1: Color = Color(0xFF113C35),
    val darkBg2: Color = Color(0xFF0B2D28),
    val lightBg1: Color = Color(0xFFFAF6EB),
    val lightBg2: Color = Color(0xFFEDE6D6),
    val deepGreen: Color = Color(0xFF004B40)
)

val hafizColors = HafizColors()

@Composable
fun HafizTheme(content: @Composable () -> Unit) {
    // Minimal M3 theme seeded from Flutter seed colors
    val colorScheme = androidx.compose.material3.lightColorScheme(
        primary = hafizColors.primary,
        secondary = hafizColors.secondary,
        onPrimary = Color.White,
        onSecondary = Color(0xFF00231B),
        primaryContainer = hafizColors.secondary.copy(alpha = 0.2f),
        secondaryContainer = hafizColors.primary.copy(alpha = 0.2f),
        background = hafizColors.lightBg1,
        surface = Color.White
    )
    MaterialTheme(
        colorScheme = colorScheme,
        typography = MaterialTheme.typography.copy(
            // We'll wire custom fonts on Android/iOS platform layers
            bodyLarge = MaterialTheme.typography.bodyLarge.copy(fontFamily = FontFamily.SansSerif),
            titleLarge = MaterialTheme.typography.titleLarge.copy(fontFamily = FontFamily.Serif),
        ),
        content = content
    )
}

@Composable
fun App() {
    HafizTheme {
        Surface(modifier = Modifier.fillMaxSize()) {
            // A simple hero section using brand gradient similar to Flutter
            val gradient = Brush.verticalGradient(
                colors = listOf(hafizColors.primary, hafizColors.secondary)
            )
            Box(
                modifier = Modifier
                    .fillMaxSize()
                    .background(gradient)
                    .padding(24.dp)
            ) {
                Column(
                    modifier = Modifier.fillMaxSize(),
                    verticalArrangement = Arrangement.Center,
                    horizontalAlignment = Alignment.CenterHorizontally
                ) {
                    Text(
                        text = "Hafiz",
                        color = Color.White,
                        style = MaterialTheme.typography.titleLarge
                    )
                    Text(
                        text = "Assalamu Alaikum",
                        color = Color.White,
                        style = MaterialTheme.typography.bodyLarge
                    )
                }
            }
        }
    }
}

