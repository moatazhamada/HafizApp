package com.hafiz.kmp.composeapp

import androidx.compose.runtime.Composable
import androidx.compose.runtime.Immutable
import androidx.compose.runtime.staticCompositionLocalOf

enum class Lang { EN, AR }

@Immutable
data class Strings(
    val lang: Lang,
    val appName: String,
    val learnQuranTitle: String,
    val learnQuranSubtitle: String,
    val getStarted: String,
    val lastRead: String,
    val continueLbl: String,
    val surah: String,
    val surahs: String,
    val bookmarks: String,
    val ayah: String,
    val assalamu: String,
    val home: String,
    val back: String,
    val dark: String,
    val light: String,
    // About strings
    val aboutTitle: String = "",
    val aboutIntro: String = "",
    val aboutAckHeading: String = "",
    val aboutAckIdeaBy: String = "",
    val aboutRepoPrefix: String = "",
    val aboutMaintainerNote: String = "",
    val aboutIntegrityHeading: String = "",
    val aboutIntegrityBody: String = "",
    val aboutSourcesTitle: String = "",
    val aboutSourceQuranApi: String = "",
    val aboutSourceTanzil: String = "",
)

val LocalStrings = staticCompositionLocalOf {
    Strings(
        Lang.EN,
        "Hafiz",
        "Learn Quran and\nRecite everyday",
        "",
        "Get Started",
        "Last Read",
        "Continue",
        "Surah",
        "Surahs",
        "Bookmarks",
        "Ayah",
        "Assalamu Alaikum",
        "Home",
        "Back",
        "Dark",
        "Light"
    )
}

val strings: Strings @Composable get() = LocalStrings.current
fun stringsFor(lang: Lang) = stringsFrom(lang)

object SettingsManager {
    private const val KEY_DARK = "pref_dark"
    private const val KEY_LANG = "pref_lang"
    private const val KEY_LAST_S = "last_surah"
    private const val KEY_LAST_V = "last_verse"

    fun isDark(): Boolean? = getBooleanOrNull(KEY_DARK)
    fun setDark(value: Boolean) { putBoolean(KEY_DARK, value) }

    fun lang(): Lang? = getStringOrNull(KEY_LANG)?.let { if (it == "ar") Lang.AR else Lang.EN }
    fun setLang(value: Lang) { putString(KEY_LANG, if (value == Lang.AR) "ar" else "en") }

    fun setLastRead(surah: Int, verse: Int) {
        putInt(KEY_LAST_S, surah)
        putInt(KEY_LAST_V, verse)
    }
    fun lastRead(): LastRead? {
        val s = getIntOrNull(KEY_LAST_S) ?: return null
        val v = getIntOrNull(KEY_LAST_V) ?: return null
        return LastRead(s, v)
    }
}

// expect/actual simple key-value storage
expect fun getBooleanOrNull(key: String): Boolean?
expect fun putBoolean(key: String, value: Boolean)
expect fun getStringOrNull(key: String): String?
expect fun putString(key: String, value: String)
expect fun getIntOrNull(key: String): Int?
expect fun putInt(key: String, value: Int)

data class LastRead(val surah: Int, val verse: Int) {
    fun surahName(lang: Lang): String {
        val idx = QuranIndex.index.firstOrNull { it.id == surah }
        return idx?.name(lang) ?: surah.toString()
    }
}
