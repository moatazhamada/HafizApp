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
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.material3.Switch
import androidx.compose.material3.Text
import androidx.compose.material3.lightColorScheme
import androidx.compose.material3.darkColorScheme
import androidx.compose.runtime.Composable
import androidx.compose.runtime.Immutable
import androidx.compose.runtime.MutableState
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.material3.Typography
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import kotlinx.serialization.Serializable
import kotlinx.serialization.json.Json

// Expect/actual typography per platform
internal expect fun getBrandTypography(): Typography

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
        typography = getBrandTypography(),
        content = content
    )
}

sealed class Screen {
    data object Onboarding : Screen()
    data object Home : Screen()
    data object SurahList : Screen()
    data class SurahReader(val surah: Int) : Screen()
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
                    onToggleDark = { dark = it },
                    onOpenSurahs = { current.value = Screen.SurahList }
                )
                Screen.SurahList -> SurahListScreen(
                    onBack = { current.value = Screen.Home },
                    onOpen = { s -> current.value = Screen.SurahReader(s) }
                )
                is Screen.SurahReader -> SurahReaderScreen(
                    surah = (current.value as Screen.SurahReader).surah,
                    onBack = { current.value = Screen.SurahList }
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
private fun HomeScreen(dark: Boolean, onToggleDark: (Boolean) -> Unit, onOpenSurahs: () -> Unit) {
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
                        .clickable { onOpenSurahs() }
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

// Data models and repository
@Serializable
private data class SurahJson(val chapter: List<Ayah>)

@Serializable
data class Ayah(val chapter: Int, val verse: Int, val text: String)

// Expect platform APIs
internal expect fun platformListAssetFiles(path: String): List<String>
internal expect suspend fun platformReadAsset(path: String): String

object QuranRepository {
    private val json = Json { ignoreUnknownKeys = true }

    suspend fun listSurahs(): List<Int> {
        val files = platformListAssetFiles("quran/uthmani")
        return files.mapNotNull {
            // expect filenames like surah_1.json
            val num = it.removePrefix("surah_").removeSuffix(".json")
            num.toIntOrNull()
        }.sorted()
    }

    suspend fun loadSurah(surah: Int): List<Ayah> {
        val content = platformReadAsset("quran/uthmani/surah_${'$'}surah.json")
        val parsed = json.decodeFromString<SurahJson>(content)
        return parsed.chapter
    }
}

@Composable
private fun SurahListScreen(onBack: () -> Unit, onOpen: (Int) -> Unit) {
    var surahs by remember { mutableStateOf<List<Int>>(emptyList()) }
    LaunchedEffect(Unit) {
        surahs = QuranRepository.listSurahs()
    }
    val bg = Brush.verticalGradient(listOf(hafizColors.lightBg1, hafizColors.lightBg2))
    Box(
        modifier = Modifier.fillMaxSize().background(bg).padding(16.dp)
    ) {
        Column(modifier = Modifier.fillMaxSize()) {
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Text("Surahs", style = MaterialTheme.typography.titleLarge, color = hafizColors.deepGreen)
                Text("Back", color = hafizColors.deepGreen, modifier = Modifier.clickable { onBack() })
            }
            Spacer(Modifier.height(16.dp))
            surahs.forEach { s ->
                Box(
                    modifier = Modifier
                        .fillMaxWidth()
                        .clip(RoundedCornerShape(10.dp))
                        .background(hafizColors.secondary.copy(alpha = 0.15f))
                        .clickable { onOpen(s) }
                        .padding(12.dp)
                ) {
                    Text("Surah ${'$'}s", color = hafizColors.deepGreen)
                }
                Spacer(Modifier.height(8.dp))
            }
        }
    }
}

@Composable
private fun SurahReaderScreen(surah: Int, onBack: () -> Unit) {
    var ayat by remember { mutableStateOf<List<Ayah>>(emptyList()) }
    LaunchedEffect(surah) {
        ayat = QuranRepository.loadSurah(surah)
    }
    val gradient = Brush.verticalGradient(listOf(hafizColors.primary, hafizColors.secondary))
    Box(modifier = Modifier.fillMaxSize().background(gradient).padding(16.dp)) {
        Column(modifier = Modifier.fillMaxSize()) {
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Text("Surah ${'$'}surah", color = Color.White, style = MaterialTheme.typography.titleLarge)
                Text("Back", color = Color.White, modifier = Modifier.clickable { onBack() })
            }
            Spacer(Modifier.height(12.dp))
            // Very simple reader; we will enhance spacing/typography next
            ayat.forEach { a ->
                Box(
                    modifier = Modifier
                        .fillMaxWidth()
                        .clip(RoundedCornerShape(10.dp))
                        .background(Color.White.copy(alpha = 0.15f))
                        .padding(12.dp)
                ) {
                    Text(text = a.text, color = Color.White)
                }
                Spacer(Modifier.height(8.dp))
            }
        }
    }
}
