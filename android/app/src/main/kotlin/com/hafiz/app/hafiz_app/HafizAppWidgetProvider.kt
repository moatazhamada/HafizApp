package com.hafiz.app.hafiz_app

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.widget.RemoteViews
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

    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)
        if (HomeWidgetPlugin.ACTION_UPDATE_WIDGET == intent.action) {
            val appWidgetManager = AppWidgetManager.getInstance(context)
            val appWidgetIds = intent.getIntArrayExtra(AppWidgetManager.EXTRA_APPWIDGET_IDS)
                ?: appWidgetManager.getAppWidgetIds(
                    android.content.ComponentName(context, HafizAppWidgetProvider::class.java)
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
    val englishText = prefs.getString("flutter.widget_verse_english", "") ?: ""
    val verseRef = prefs.getString("flutter.widget_verse_ref", "") ?: ""
    val chapterId = prefs.getString("flutter.widget_chapter_id", "1") ?: "1"
    val verseNumber = prefs.getString("flutter.widget_verse_number", "1") ?: "1"

    val views = RemoteViews(context.packageName, R.layout.app_widget_layout)
    views.setTextViewText(R.id.widget_verse_arabic, arabicText)
    views.setTextViewText(R.id.widget_verse_english, englishText)
    views.setTextViewText(R.id.widget_verse_ref, verseRef)

    val deepLink = Uri.parse("hafiz://verse/$chapterId/$verseNumber")
    val intent = Intent(Intent.ACTION_VIEW, deepLink).apply {
        flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
    }
    val pendingIntent = PendingIntent.getActivity(
        context,
        0,
        intent,
        PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
    )
    views.setOnClickPendingIntent(R.id.widget_verse_arabic, pendingIntent)
    views.setOnClickPendingIntent(R.id.widget_verse_english, pendingIntent)
    views.setOnClickPendingIntent(R.id.widget_verse_ref, pendingIntent)

    appWidgetManager.updateAppWidget(appWidgetId, views)
}
