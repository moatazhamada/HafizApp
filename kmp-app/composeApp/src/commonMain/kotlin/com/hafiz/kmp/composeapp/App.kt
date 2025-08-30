package com.hafiz.kmp.composeapp

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.material3.Switch
import androidx.compose.material3.Text
import androidx.compose.material3.lightColorScheme
import androidx.compose.material3.darkColorScheme
import androidx.compose.runtime.Composable
import androidx.compose.runtime.Immutable
import androidx.compose.runtime.MutableState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.font.FontWeight
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
fun HafizTheme(dark: Boolean, content: @Composable () -> Unit) {
    val light = lightColorScheme(
        primary = hafizColors.primary,
        secondary = hafizColors.secondary,
        onPrimary = Color.White,
        onSecondary = Color(0xFF00231B),
        primaryContainer = hafizColors.secondary.copy(alpha = 0.2f),
        secondaryContainer = hafizColors.primary.copy(alpha = 0.2f),
        background = hafizColors.lightBg1,
        surface = Color.White
    )
    val darkCs = darkColorScheme(
        primary = hafizColors.secondary,
        secondary = hafizColors.primary,
        background = hafizColors.darkBg1,
        surface = hafizColors.darkBg2,
        onPrimary = Color(0xFF00231B),
        onSecondary = Color.White
    )
    MaterialTheme(
        colorScheme = if (dark) darkCs else light,
        typography = MaterialTheme.typography.copy(
            bodyLarge = MaterialTheme.typography.bodyLarge.copy(fontFamily = FontFamily.SansSerif),
            titleLarge = MaterialTheme.typography.titleLarge.copy(fontFamily = FontFamily.Serif),
        ),
        content = content
    )
}

sealed class Screen {
    data object Onboarding : Screen()
    data object Home : Screen()
}

@Composable
fun App() {
    var dark by remember { mutableStateOf(isSystemInDarkTheme()) }
    val current: MutableState<Screen> = remember { mutableStateOf(Screen.Onboarding) }
    HafizTheme(dark = dark) {
        Surface(modifier = Modifier.fillMaxSize()) {
            when (current.value) {
                Screen.Onboarding -> OnboardingScreen(
                    onContinue = { current.value = Screen.Home },
                    dark = dark,
                    onToggleDark = { dark = it }
                )
                Screen.Home -> HomeScreen(
                    dark = dark,
                    onToggleDark = { dark = it }
                )
            }
        }
    }
}

@Composable
private fun OnboardingScreen(onContinue: () -> Unit, dark: Boolean, onToggleDark: (Boolean) -> Unit) {
    val bg = if (dark) Brush.verticalGradient(listOf(hafizColors.darkBg1, hafizColors.darkBg2))
             else Brush.verticalGradient(listOf(hafizColors.lightBg1, hafizColors.lightBg2))
    val badgeGradient = Brush.horizontalGradient(listOf(hafizColors.primary, hafizColors.secondary))
    Box(
        modifier = Modifier
            .fillMaxSize()
            .background(bg)
            .padding(24.dp)
    ) {
        Column(
            modifier = Modifier.fillMaxSize(),
            verticalArrangement = Arrangement.SpaceBetween
        ) {
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Text(
                    text = "Hafiz",
                    color = if (dark) Color.White else hafizColors.deepGreen,
                    style = MaterialTheme.typography.titleLarge,
                    fontWeight = FontWeight.SemiBold
                )
                Row(verticalAlignment = Alignment.CenterVertically) {
                    Text(
                        text = if (dark) "Dark" else "Light",
                        color = if (dark) Color.White else hafizColors.deepGreen
                    )
                    Spacer(Modifier.padding(horizontal = 8.dp))
                    Switch(checked = dark, onCheckedChange = onToggleDark)
                }
            }

            Column(horizontalAlignment = Alignment.CenterHorizontally) {
                Box(
                    modifier = Modifier
                        .clip(RoundedCornerShape(16.dp))
                        .background(badgeGradient)
                        .padding(horizontal = 16.dp, vertical = 8.dp)
                ) {
                    Text("Assalamu Alaikum", color = Color.White)
                }
                Spacer(Modifier.height(16.dp))
                Text(
                    text = "Welcome to Hafiz",
                    color = if (dark) Color.White else hafizColors.deepGreen,
                    style = MaterialTheme.typography.titleLarge,
                    fontWeight = FontWeight.Bold
                )
                Spacer(Modifier.height(8.dp))
                Text(
                    text = "Learn and read the Quran with ease",
                    color = if (dark) Color(0xFFD9D8D8) else Color(0xFF004B40)
                )
            }

            Button(
                onClick = onContinue,
                modifier = Modifier.fillMaxWidth(),
                colors = ButtonDefaults.buttonColors(containerColor = hafizColors.primary)
            ) {
                Text("Get Started", color = Color.White)
            }
        }
    }
}

@Composable
private fun HomeScreen(dark: Boolean, onToggleDark: (Boolean) -> Unit) {
    val gradient = Brush.verticalGradient(listOf(hafizColors.primary, hafizColors.secondary))
    Box(
        modifier = Modifier
            .fillMaxSize()
            .background(gradient)
            .padding(24.dp)
    ) {
        Column(
            modifier = Modifier.fillMaxSize(),
            verticalArrangement = Arrangement.SpaceBetween
        ) {
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Text("Hafiz", color = Color.White, style = MaterialTheme.typography.titleLarge, fontWeight = FontWeight.SemiBold)
                Row(verticalAlignment = Alignment.CenterVertically) {
                    Text(text = if (dark) "Dark" else "Light", color = Color.White)
                    Spacer(Modifier.padding(horizontal = 8.dp))
                    Switch(checked = dark, onCheckedChange = onToggleDark)
                }
            }

            Column(horizontalAlignment = Alignment.CenterHorizontally) {
                Text("Home", color = Color.White, style = MaterialTheme.typography.titleLarge)
                Spacer(Modifier.height(8.dp))
                Text("Surah list and reader coming next", color = Color.White)
            }

            Row(modifier = Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceBetween) {
                Box(
                    modifier = Modifier
                        .clip(RoundedCornerShape(12.dp))
                        .background(Color.White.copy(alpha = 0.15f))
                        .padding(16.dp)
                        .weight(1f)
                        .clickable { /* TODO: navigate to Surah */ }
                ) { Text("Surahs", color = Color.White) }
                Spacer(Modifier.padding(horizontal = 8.dp))
                Box(
                    modifier = Modifier
                        .clip(RoundedCornerShape(12.dp))
                        .background(Color.White.copy(alpha = 0.15f))
                        .padding(16.dp)
                        .weight(1f)
                        .clickable { /* TODO: navigate to Bookmarks/Settings */ }
                ) { Text("Bookmarks", color = Color.White) }
            }
        }
    }
}
