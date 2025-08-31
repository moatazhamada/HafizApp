package com.hafiz.kmp.composeapp

import androidx.compose.foundation.background
import androidx.compose.foundation.Image
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
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
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
import androidx.compose.runtime.snapshotFlow
import androidx.compose.foundation.lazy.rememberLazyListState
import kotlinx.coroutines.flow.distinctUntilChanged
import kotlinx.coroutines.flow.map
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.Info
import androidx.compose.material.icons.outlined.Public
import androidx.compose.material.icons.outlined.WbSunny
import androidx.compose.material.icons.outlined.NightsStay
import androidx.compose.material.icons.outlined.ArrowForward
import androidx.compose.material3.Icon
import androidx.compose.runtime.CompositionLocalProvider
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
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextDirection
import androidx.compose.ui.unit.dp
import androidx.compose.ui.platform.LocalLayoutDirection
import androidx.compose.ui.unit.LayoutDirection
import kotlinx.serialization.Serializable
import kotlinx.serialization.json.Json

// Expect/actual typography per platform
internal expect fun getBrandTypography(): Typography
// Asset image helper (Android actual provided)
@Composable
internal expect fun AssetImage(path: String, modifier: Modifier = Modifier)

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
    data class SurahReader(val surah: Int, val initialVerse: Int? = null) : Screen()
    data object About : Screen()
}

@Composable
fun App() {
    val systemDark = isSystemInDarkTheme()
    var dark by remember { mutableStateOf(SettingsManager.isDark() ?: systemDark) }
    var lang by remember { mutableStateOf(SettingsManager.lang() ?: Lang.EN) }
    val current: MutableState<Screen> = remember { mutableStateOf(Screen.Onboarding) }
    CompositionLocalProvider(LocalStrings provides stringsFor(lang), LocalLayoutDirection provides (if (lang == Lang.AR) LayoutDirection.Rtl else LayoutDirection.Ltr)) {
      HafizTheme(dark = dark) {
        Surface(modifier = Modifier.fillMaxSize()) {
            when (current.value) {
                Screen.Onboarding -> OnboardingScreen(
                    onContinue = { current.value = Screen.Home },
                    dark = dark,
                    onToggleDark = { dark = it; SettingsManager.setDark(it) },
                    lang = lang,
                    onToggleLang = { l -> lang = l; SettingsManager.setLang(l) }
                )
                Screen.Home -> HomeScreen(
                    dark = dark,
                    onToggleDark = { dark = it; SettingsManager.setDark(it) },
                    onOpenSurahs = { current.value = Screen.SurahList },
                    lang = lang,
                    onToggleLang = { l -> lang = l; SettingsManager.setLang(l) },
                    onOpenAbout = { current.value = Screen.About },
                    onContinueLast = {
                        SettingsManager.lastRead()?.let { lr ->
                            current.value = Screen.SurahReader(lr.surah, lr.verse)
                        }
                    }
                )
                Screen.SurahList -> SurahListScreen(
                    onBack = { current.value = Screen.Home },
                    onOpen = { s -> current.value = Screen.SurahReader(s) }
                )
                is Screen.SurahReader -> {
                    val sr = current.value as Screen.SurahReader
                    SurahReaderScreen(
                        surah = sr.surah,
                        initialVerse = sr.initialVerse,
                        onBack = { current.value = Screen.SurahList }
                    )
                }
                Screen.About -> AboutScreen(onBack = { current.value = Screen.Home })
            }
        }
      }
    }
}

@Composable
private fun OnboardingScreen(onContinue: () -> Unit, dark: Boolean, onToggleDark: (Boolean) -> Unit, lang: Lang, onToggleLang: (Lang) -> Unit) {
    val badgeGradient = Brush.horizontalGradient(listOf(hafizColors.primary, hafizColors.secondary))
    Box(
        modifier = Modifier
            .fillMaxSize()
            .background(Color(0xFF004B40))
            .padding(24.dp)
    ) {
        Column(
            modifier = Modifier.fillMaxSize(),
            verticalArrangement = Arrangement.SpaceBetween
        ) {
            Row(modifier = Modifier.fillMaxWidth()) {
                AssetImage("assets/images/group_circles.svg", modifier = Modifier.height(40.dp))
                Spacer(Modifier.weight(1f))
                Text(text = if (dark) strings.dark else strings.light, color = Color.White)
                Spacer(Modifier.padding(horizontal = 8.dp))
                Switch(checked = dark, onCheckedChange = onToggleDark)
                Spacer(Modifier.padding(horizontal = 12.dp))
                Text(text = if (lang == Lang.AR) "AR" else "EN", color = Color.White, modifier = Modifier.clickable { onToggleLang(if (lang == Lang.AR) Lang.EN else Lang.AR) })
            }

            Column(horizontalAlignment = Alignment.CenterHorizontally) {
                Box(
                    modifier = Modifier
                        .clip(RoundedCornerShape(16.dp))
                        .background(Color(0xFF186351))
                        .padding(16.dp)
                ) {
                    AssetImage("assets/images/quran_onboarding.svg", modifier = Modifier.height(280.dp))
                }
                Spacer(Modifier.height(22.dp))
                Text(text = strings.appName, color = Color(0xFF87D1A4), fontWeight = FontWeight.Bold, style = MaterialTheme.typography.titleLarge)
                Spacer(Modifier.height(16.dp))
                Text(text = strings.learnQuranTitle, color = Color.White)
            }

            Button(
                onClick = onContinue,
                modifier = Modifier.fillMaxWidth(),
                colors = ButtonDefaults.buttonColors(containerColor = Color(0xFFFAF6EB))
            ) {
                Text(strings.getStarted, color = Color.Black)
            }
        }
    }
}

@Composable
private fun HomeScreen(
    dark: Boolean,
    onToggleDark: (Boolean) -> Unit,
    onOpenSurahs: () -> Unit,
    lang: Lang,
    onToggleLang: (Lang) -> Unit,
    onOpenAbout: () -> Unit,
    onContinueLast: () -> Unit
) {
    val bg = Color(if (dark) 0xFF000000.toInt() else 0xFFFFFFFF.toInt())
    Column(modifier = Modifier.fillMaxSize().background(bg)) {
        // App bar mimicking master
        Row(
            modifier = Modifier.fillMaxWidth().padding(horizontal = 12.dp, vertical = 8.dp),
            horizontalArrangement = Arrangement.SpaceBetween,
            verticalAlignment = Alignment.CenterVertically
        ) {
            Row(verticalAlignment = Alignment.CenterVertically) {
                Icon(Icons.Outlined.WbSunny, contentDescription = null, tint = if (dark) Color.Gray else Color(0xFFFFC107))
                Switch(checked = dark, onCheckedChange = onToggleDark)
                Icon(Icons.Outlined.NightsStay, contentDescription = null, tint = if (dark) Color(0xFF2196F3) else Color.Gray)
            }
            Text(
                strings.appName,
                color = Color(if (dark) 0xFFFFFFFF.toInt() else 0xFF004B40.toInt()),
                fontWeight = FontWeight.Bold,
                style = MaterialTheme.typography.titleLarge
            )
            Row(verticalAlignment = Alignment.CenterVertically) {
                Icon(Icons.Outlined.Public, contentDescription = null, tint = Color(if (dark) 0xFFFFFFFF.toInt() else 0xFF004B40.toInt()), modifier = Modifier.clickable { onToggleLang(if (lang == Lang.AR) Lang.EN else Lang.AR) })
                Spacer(Modifier.padding(horizontal = 8.dp))
                Icon(Icons.Outlined.Info, contentDescription = null, tint = Color(if (dark) 0xFFFFFFFF.toInt() else 0xFF004B40.toInt()), modifier = Modifier.clickable { onOpenAbout() })
            }
        }

        // Body
        LazyColumn(modifier = Modifier.fillMaxSize()) {
            item { LastReadCard(lang = lang, onContinue = onContinueLast) }
            items(QuranIndex.index) { s ->
                SurahListItem(
                    dark = dark,
                    surahId = s.id,
                    nameEnglish = s.nameEnglish,
                    nameArabic = s.nameArabic,
                    onClick = {
                        SettingsManager.setLastRead(s.id, 1)
                        onOpenSurahs()
                    }
                )
            }
        }
    }
}

@Composable
private fun LastReadCard(lang: Lang, onContinue: () -> Unit) {
    val last = SettingsManager.lastRead() ?: return
    val gradient = Brush.horizontalGradient(colors = listOf(Color(0xFF006754), Color(0xFF87D1A4)))
    Box(modifier = Modifier.padding(horizontal = 16.dp, vertical = 12.dp)) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .clip(RoundedCornerShape(20.dp))
                .background(gradient)
                .padding(12.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            Column(modifier = Modifier.weight(1f)) {
                Text(strings.lastRead, color = Color(0xFFFAF6EB))
                Spacer(Modifier.height(8.dp))
                Row(verticalAlignment = Alignment.CenterVertically) {
                    Text(last.surahName(lang), color = Color.White, fontWeight = FontWeight.Bold, style = MaterialTheme.typography.titleLarge)
                    Spacer(Modifier.padding(horizontal = 6.dp))
                    Box(modifier = Modifier.clip(RoundedCornerShape(16.dp)).background(Color(0xFFFAF6EB)).padding(horizontal = 10.dp, vertical = 6.dp)) {
                        Text("${strings.ayah} ${last.verse}", color = Color(0xFF004B40))
                    }
                }
                Spacer(Modifier.height(8.dp))
                Button(onClick = onContinue, shape = RoundedCornerShape(200.dp), colors = ButtonDefaults.buttonColors(containerColor = Color(0xFFFAF6EB))) {
                    Text(strings.continueLbl, color = Color.Black)
                    Spacer(Modifier.padding(horizontal = 6.dp))
                    Icon(Icons.Outlined.ArrowForward, contentDescription = null, tint = Color(0xFF004B40))
                }
            }
            Spacer(Modifier.padding(horizontal = 8.dp))
            AssetImage(path = "assets/images/quran_onboarding.svg", modifier = Modifier.height(80.dp))
        }
    }
}

@Composable
private fun SurahListItem(
    dark: Boolean,
    surahId: Int,
    nameEnglish: String,
    nameArabic: String,
    onClick: () -> Unit
) {
    Column(modifier = Modifier.clickable { onClick() }.padding(horizontal = 16.dp, vertical = 12.dp)) {
        Row(modifier = Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceBetween, verticalAlignment = Alignment.CenterVertically) {
            Box(modifier = Modifier.clip(RoundedCornerShape(6.dp)).background(Color(0xFF87D1A4))) {
                Text("$surahId", color = Color.White, modifier = Modifier.padding(horizontal = 14.dp, vertical = 6.dp))
            }
            Spacer(Modifier.padding(horizontal = 8.dp))
            Text(nameEnglish, color = Color(if (dark) 0xFFFFFFFF.toInt() else 0xFF000000.toInt()), modifier = Modifier.weight(1f),
                style = MaterialTheme.typography.bodyLarge)
            Spacer(Modifier.padding(horizontal = 8.dp))
            Text(nameArabic, color = Color(if (dark) 0xFFD9D8D8.toInt() else 0xFF076C58.toInt()), maxLines = 1,
                style = MaterialTheme.typography.titleLarge, fontWeight = FontWeight.W700)
        }
        Spacer(Modifier.height(16.dp))
        if (surahId < 114) Box(modifier = Modifier.fillMaxWidth().height(1.dp).background(Color(0xFFD9D8D8)))
    }
}

@Composable
private fun AboutScreen(onBack: () -> Unit) {
    val c = Color(0xFF004B40)
    Column(modifier = Modifier.fillMaxSize().background(Color.White).padding(16.dp)) {
        Text(strings.back, color = c, modifier = Modifier.clickable { onBack() })
        Spacer(Modifier.height(12.dp))
        Text(strings.aboutTitle, fontWeight = FontWeight.Bold, style = MaterialTheme.typography.titleLarge, color = c)
        Spacer(Modifier.height(8.dp))
        Text(strings.aboutIntro)
        Spacer(Modifier.height(16.dp))
        Text(strings.aboutAckHeading, fontWeight = FontWeight.SemiBold, color = c)
        Spacer(Modifier.height(4.dp))
        Text(strings.aboutAckIdeaBy)
        Text("https://github.com/abualgait/HafizApp", color = c)
        Text(strings.aboutRepoPrefix)
        Text("https://github.com/moatazhamada/HafizApp", color = c)
        Spacer(Modifier.height(8.dp))
        Text(strings.aboutMaintainerNote)
        Spacer(Modifier.height(16.dp))
        Text(strings.aboutIntegrityHeading, fontWeight = FontWeight.SemiBold, color = c)
        Spacer(Modifier.height(4.dp))
        Text(strings.aboutIntegrityBody)
        Spacer(Modifier.height(16.dp))
        Text(strings.aboutSourcesTitle, fontWeight = FontWeight.SemiBold, color = c)
        Text(strings.aboutSourceQuranApi)
        Text(strings.aboutSourceTanzil)
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
                Text(strings.surahs, style = MaterialTheme.typography.titleLarge, color = hafizColors.deepGreen)
                Text(strings.back, color = hafizColors.deepGreen, modifier = Modifier.clickable { onBack() })
            }
            Spacer(Modifier.height(16.dp))
            LazyColumn {
                items(surahs) { s ->
                    Box(
                        modifier = Modifier
                            .fillMaxWidth()
                            .clip(RoundedCornerShape(10.dp))
                            .background(hafizColors.secondary.copy(alpha = 0.15f))
                            .clickable { onOpen(s) }
                            .padding(12.dp)
                    ) {
                        val idx = QuranIndex.index.first { it.id == s }
                        Text("${'$'}{strings.surah} ${'$'}{if (strings.lang == Lang.AR) idx.nameArabic else idx.nameEnglish}", color = hafizColors.deepGreen)
                    }
                    Spacer(Modifier.height(8.dp))
                }
            }
        }
    }
}

@Composable
private fun SurahReaderScreen(surah: Int, initialVerse: Int? = null, onBack: () -> Unit) {
    var ayat by remember { mutableStateOf<List<Ayah>>(emptyList()) }
    val listState = rememberLazyListState()
    LaunchedEffect(surah) {
        ayat = QuranRepository.loadSurah(surah)
        // jump to initial verse if provided
        val idx = (initialVerse?.minus(1)) ?: 0
        if (idx > 0) listState.scrollToItem(idx)
        SettingsManager.setLastRead(surah, (initialVerse ?: 1))
    }
    // TODO: Persist last visible verse index during scroll when snapshotFlow is available in target
    val gradient = Brush.verticalGradient(listOf(hafizColors.primary, hafizColors.secondary))
    Box(modifier = Modifier.fillMaxSize().background(gradient).padding(16.dp)) {
        Column(modifier = Modifier.fillMaxSize()) {
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                val idx = QuranIndex.index.firstOrNull { it.id == surah }
                Text("${'$'}{strings.surah} ${'$'}{idx?.name(lang = strings.lang) ?: surah}", color = Color.White, style = MaterialTheme.typography.titleLarge)
                Text(strings.back, color = Color.White, modifier = Modifier.clickable { onBack() })
            }
            Spacer(Modifier.height(12.dp))
            if (surah != 9) { // Show Bismillah image like master (except At-Tawbah)
                AssetImage(path = "assets/images/bismillah.svg", modifier = Modifier.fillMaxWidth().height(64.dp))
                Spacer(Modifier.height(8.dp))
            }
            LazyColumn(state = listState) {
                items(ayat) { a ->
                    Box(
                        modifier = Modifier
                            .fillMaxWidth()
                            .clip(RoundedCornerShape(10.dp))
                            .background(Color.White.copy(alpha = 0.15f))
                            .padding(12.dp)
                    ) {
                        Text(
                            text = a.text,
                            color = Color.White,
                            textAlign = TextAlign.Right,
                            style = MaterialTheme.typography.titleMedium,
                            softWrap = true,
                            maxLines = Int.MAX_VALUE
                        )
                    }
                    Spacer(Modifier.height(8.dp))
                }
            }
        }
    }
}
