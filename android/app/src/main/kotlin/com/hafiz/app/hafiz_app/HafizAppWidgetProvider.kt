package com.hafiz.app.hafiz_app

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.net.Uri
import android.view.View
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetPlugin

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
        // Handle the home_widget plugin broadcast.
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
    // Try the home_widget plugin's data store first (preferred),
    // then fall back to FlutterSharedPreferences.
    val widgetData = HomeWidgetPlugin.getData(context)
    val flutterPrefs = context.getSharedPreferences(
        "FlutterSharedPreferences",
        Context.MODE_PRIVATE
    )

    val arabicText = widgetData.getString("widget_verse_arabic", null)
        ?: flutterPrefs.getString("flutter.widget_verse_arabic", "")
        ?: ""

    val displayText = widgetData.getString("widget_verse_text", null)
        ?: flutterPrefs.getString("flutter.widget_verse_text", "")
        ?: ""

    val verseRef = widgetData.getString("widget_verse_ref", null)
        ?: flutterPrefs.getString("flutter.widget_verse_ref", "")
        ?: "— 1:1"

    val chapterId = widgetData.getString("widget_chapter_id", null)
        ?: flutterPrefs.getString("flutter.widget_chapter_id", "1")
        ?: "1"

    val verseNumber = widgetData.getString("widget_verse_number", null)
        ?: flutterPrefs.getString("flutter.widget_verse_number", "1")
        ?: "1"

    // Use display text if available, otherwise fall back to Arabic.
    val finalText = if (displayText.isNotBlank()) displayText else arabicText

    val views = RemoteViews(context.packageName, R.layout.app_widget_layout)

    // RTL / LTR based on content.
    val isArabic = containsArabic(finalText)
    views.setInt(
        R.id.widget_verse_text,
        "setTextDirection",
        if (isArabic) View.TEXT_DIRECTION_RTL else View.TEXT_DIRECTION_LTR
    )

    views.setTextViewText(
        R.id.widget_verse_text,
        if (finalText.isNotBlank()) finalText else context.getString(R.string.app_widget_placeholder_text)
    )
    views.setTextViewText(
        R.id.widget_verse_ref,
        if (verseRef.isNotBlank()) verseRef else "— 1:1"
    )

    // Deep link into the app when tapped.
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

private fun containsArabic(text: String): Boolean {
    return text.any { it in '\u0600'..'\u06FF' }
}
