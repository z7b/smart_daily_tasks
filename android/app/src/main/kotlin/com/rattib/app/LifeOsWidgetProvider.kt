package com.rattib.app

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.widget.RemoteViews
import android.net.Uri
import es.antonborri.home_widget.HomeWidgetPlugin
import es.antonborri.home_widget.HomeWidgetLaunchIntent

class LifeOsWidgetProvider : AppWidgetProvider() {
    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray) {
        val widgetData = HomeWidgetPlugin.getData(context)
        for (appWidgetId in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.life_os_widget)

            val percentage = widgetData.getString("life_os_text", "0%")
            val status = widgetData.getString("life_os_status", "تكامل حياتك الذكية")
            val progressInt = widgetData.getInt("life_os_progress_int", 0)

            views.setTextViewText(R.id.widget_percentage, percentage)
            views.setTextViewText(R.id.widget_status, status)
            views.setProgressBar(R.id.widget_progress, 100, progressInt, false)

            // Deep link: open Home page (Life OS lives in the home dashboard)
            val pendingIntent = HomeWidgetLaunchIntent.getActivity(
                context,
                MainActivity::class.java,
                Uri.parse("rattib://home")
            )
            views.setOnClickPendingIntent(R.id.widget_root, pendingIntent)

            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}
