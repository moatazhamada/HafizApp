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
    "bookmarks" to "Bookmarks",
    // About
    "about_title" to "About Hafiz App",
    "about_intro" to "This app is non-profit and intended as a good deed for us and our families. We aim to provide a respectful, reliable Quran reading experience.",
    "about_ack_heading" to "Acknowledgements",
    "about_ack_idea_by" to "Original idea and initial project by:",
    "about_repo_prefix" to "Project repo:",
    "about_maintainer_note" to "This version includes small fixes and updates by the current maintainer.",
    "about_integrity_heading" to "Quran Text Integrity",
    "about_integrity_body" to "Arabic Quran text is bundled locally from a verified source to prevent tampering and to work offline. If you find any issue, please report it so we can correct it swiftly.",
    "about_language_title" to "Language",
    "about_sources_title" to "Sources",
    "about_source_quran_api" to "Quran.com API v4 — https://api.quran.com/api/v4",
    "about_source_tanzil" to "Tanzil verified Uthmani text — https://tanzil.net/download/",
    "about_feedback_title" to "Send Feedback",
    "about_feedback_desc" to "Report an issue or suggest an improvement via email.",
    "about_feedback_hint" to "Describe your issue or suggestion...",
    "about_feedback_send" to "Send",
    "about_feedback_sent" to "Thanks for your feedback!",
    "lbl_ayah" to "Ayah"
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
    "bookmarks" to "العلامات",
    // About
    "about_title" to "عن تطبيق حافظ",
    "about_intro" to "هذا التطبيق غير ربحي ونقدمه صدقةً لنا ولأهلينا. نسعى لتقديم تجربة محترمة وموثوقة لقراءة القرآن الكريم.",
    "about_ack_heading" to "شكر وتقدير",
    "about_ack_idea_by" to "الفكرة الأصلية والمشروع الأولي من:",
    "about_repo_prefix" to "مستودع المشروع:",
    "about_maintainer_note" to "يتضمن هذا الإصدار بعض الإصلاحات والتحديثات من القائم الحالي على الصيانة.",
    "about_integrity_heading" to "سلامة نص القرآن",
    "about_integrity_body" to "يتم تضمين نص القرآن الكريم عربيًا محليًا من مصدر موثوق لمنع العبث والعمل دون اتصال. في حال وجود أي ملاحظة نرجو إبلاغنا لتصحيحها بسرعة.",
    "about_language_title" to "اللغة",
    "about_sources_title" to "المصادر",
    "about_source_quran_api" to "واجهة برمجة Quran.com الإصدار 4 — https://api.quran.com/api/v4",
    "about_source_tanzil" to "نص عثماني مُعتمد من Tanzil — https://tanzil.net/download/",
    "about_feedback_title" to "إرسال ملاحظة",
    "about_feedback_desc" to "أبلغ عن مشكلة أو اقترح تحسينًا عبر البريد الإلكتروني.",
    "about_feedback_hint" to "اكتب مشكلتك أو اقتراحك...",
    "about_feedback_send" to "إرسال",
    "about_feedback_sent" to "شكرًا لملاحظتك!",
    "lbl_ayah" to "آية"
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
        ayah = m.getValue("lbl_ayah"),
        assalamu = if (lang == Lang.AR) "السلام عليكم" else "Assalamu Alaikum",
        home = m.getValue("home"),
        back = m.getValue("back"),
        dark = m.getValue("dark"),
        light = m.getValue("light"),
        aboutTitle = m.getValue("about_title"),
        aboutIntro = m.getValue("about_intro"),
        aboutAckHeading = m.getValue("about_ack_heading"),
        aboutAckIdeaBy = m.getValue("about_ack_idea_by"),
        aboutRepoPrefix = m.getValue("about_repo_prefix"),
        aboutMaintainerNote = m.getValue("about_maintainer_note"),
        aboutIntegrityHeading = m.getValue("about_integrity_heading"),
        aboutIntegrityBody = m.getValue("about_integrity_body"),
        aboutSourcesTitle = m.getValue("about_sources_title"),
        aboutSourceQuranApi = m.getValue("about_source_quran_api"),
        aboutSourceTanzil = m.getValue("about_source_tanzil"),
    )
}
