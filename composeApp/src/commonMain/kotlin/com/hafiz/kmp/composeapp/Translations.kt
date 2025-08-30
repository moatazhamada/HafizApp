package com.hafiz.kmp.composeapp

// Minimal translation maps mirroring master keys we use now

private val enUs = mapOf(
    "app_name" to "Hafiz",
    "lbl_learn_quran" to "Learn Quran and\nRecite everyday",
    "lbl_get_started" to "Get Started",
    "lbl_last_read" to "Last Read",
    "lbl_continue" to "Continue",
    "lbl_surah" to "Surah",
    "home" to "Home",
    "back" to "Back",
    "dark" to "Dark",
    "light" to "Light",
    "bookmarks" to "Bookmarks"
)

private val arEg = mapOf(
    "app_name" to "حافظ",
    "lbl_learn_quran" to "تعلّم القرآن وتلاوته يوميًا",
    "lbl_get_started" to "ابدأ",
    "lbl_last_read" to "آخر قراءة",
    "lbl_continue" to "متابعة",
    "lbl_surah" to "سورة",
    "home" to "الرئيسية",
    "back" to "رجوع",
    "dark" to "داكن",
    "light" to "فاتح",
    "bookmarks" to "العلامات"
)

internal fun stringsFrom(lang: Lang): Strings {
    val m = if (lang == Lang.AR) arEg else enUs
    val surahsLabel = if (lang == Lang.AR) "سور" else "Surahs"
    return Strings(
        lang = lang,
        appName = m.getValue("app_name"),
        learnQuranTitle = m.getValue("lbl_learn_quran"),
        learnQuranSubtitle = "", // master doesn’t use a separate subtitle string
        getStarted = m.getValue("lbl_get_started"),
        lastRead = m.getValue("lbl_last_read"),
        continueLbl = m.getValue("lbl_continue"),
        surah = m.getValue("lbl_surah"),
        surahs = surahsLabel,
        bookmarks = m.getValue("bookmarks"),
        ayah = if (lang == Lang.AR) "آية" else "Ayah",
        assalamu = if (lang == Lang.AR) "السلام عليكم" else "Assalamu Alaikum",
        home = m.getValue("home"),
        back = m.getValue("back"),
        dark = m.getValue("dark"),
        light = m.getValue("light"),
    )
}

