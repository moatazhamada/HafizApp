package com.hafiz.app.hafiz_app

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.net.Uri
import android.view.View
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent

class HafizAppWidgetProvider : AppWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        for (appWidgetId in appWidgetIds) {
            updateAppWidget(context, appWidgetManager, appWidgetId)
        }
    }

    override fun onReceive(context: Context, intent: android.content.Intent) {
        super.onReceive(context, intent)
        // Only handle the home_widget plugin broadcast here;
        // super.onReceive() already dispatches ACTION_APPWIDGET_UPDATE → onUpdate().
        if (intent.action == "es.antonborri.home_widget.UPDATE_WIDGET") {
            val appWidgetManager = AppWidgetManager.getInstance(context)
            val appWidgetIds = intent.getIntArrayExtra(AppWidgetManager.EXTRA_APPWIDGET_IDS)
                ?: appWidgetManager.getAppWidgetIds(
                    ComponentName(context, HafizAppWidgetProvider::class.java)
                )
            onUpdate(context, appWidgetManager, appWidgetIds)
        }
    }
}

private fun updateAppWidget(
    context: Context,
    appWidgetManager: AppWidgetManager,
    appWidgetId: Int
) {
    val prefs = context.getSharedPreferences(
        "FlutterSharedPreferences",
        Context.MODE_PRIVATE
    )

    val arabicText = prefs.getString("flutter.widget_verse_arabic", "") ?: ""
    val displayText = prefs.getString("flutter.widget_verse_text", "") ?: ""
    val verseRef = prefs.getString("flutter.widget_verse_ref", "") ?: ""
    val chapterId = prefs.getString("flutter.widget_chapter_id", "1") ?: "1"
    val verseNumber = prefs.getString("flutter.widget_verse_number", "1") ?: "1"

    // Use arabic text as fallback if display text is empty
    val finalText = if (displayText.isNotEmpty()) displayText else arabicText

    val views = RemoteViews(context.packageName, R.layout.app_widget_layout)

    // Choose text direction: RTL for Arabic, LTR for English
    val isArabic = containsArabic(finalText)
    if (isArabic) {
        views.setInt(R.id.widget_verse_text, "setTextDirection", View.TEXT_DIRECTION_RTL)
    } else {
        views.setInt(R.id.widget_verse_text, "setTextDirection", View.TEXT_DIRECTION_LTR)
    }

    if (finalText.isNotEmpty()) {
        views.setTextViewText(R.id.widget_verse_text, finalText)
    }
    if (verseRef.isNotEmpty()) {
        views.setTextViewText(R.id.widget_verse_ref, verseRef)
    }

    // Use HomeWidgetLaunchIntent so clicks are routed through
    // HomeWidget.widgetClicked on the Dart side (DeepLinkHandler).
    val deepLink = Uri.parse("hafiz://verse/$chapterId/$verseNumber")
    val pendingIntent = HomeWidgetLaunchIntent.getActivity(
        context,
        MainActivity::class.java,
        deepLink
    )
    views.setOnClickPendingIntent(R.id.widget_verse_text, pendingIntent)
    views.setOnClickPendingIntent(R.id.widget_verse_ref, pendingIntent)

    appWidgetManager.updateAppWidget(appWidgetId, views)
}

/**
 * Quick check for Arabic script: if the text contains any character in the
 * Arabic Unicode block (U+0600–U+06FF), treat it as Arabic.
 */
private fun containsArabic(text: String): Boolean {
    return text.any { it in '\u0600'..'\u06FF' }
}
