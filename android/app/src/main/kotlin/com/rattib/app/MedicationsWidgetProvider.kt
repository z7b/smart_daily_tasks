package com.rattib.app

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.view.View
import android.widget.RemoteViews
import android.net.Uri
import es.antonborri.home_widget.HomeWidgetPlugin
import es.antonborri.home_widget.HomeWidgetLaunchIntent

class MedicationsWidgetProvider : AppWidgetProvider() {
    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray) {
        val widgetData = HomeWidgetPlugin.getData(context)
        for (appWidgetId in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.medications_widget)

            val completed = widgetData.getInt("meds_completed", 0)
            val total = widgetData.getInt("meds_total", 0)
            val nextTitle = widgetData.getString("next_med_title", "")
            val nextTime = widgetData.getString("next_med_time", "")
            val remaining = total - completed

            views.setTextViewText(R.id.meds_badge, "$completed/$total")

            if (total > 0) {
                views.setViewVisibility(R.id.meds_progress_bar, View.VISIBLE)
                views.setViewVisibility(R.id.meds_stats_row, View.VISIBLE)

                val progressPct = ((completed.toFloat() / total) * 100).toInt()
                views.setProgressBar(R.id.meds_progress_bar, 100, progressPct, false)

                views.setTextViewText(R.id.meds_taken_count, completed.toString())
                views.setTextViewText(R.id.meds_remaining_count, remaining.toString())
                views.setTextViewText(
                    R.id.meds_status,
                    if (completed == total) "تم تناول جميع الأدوية 🎉"
                    else "تم تناول $completed من $total جرعة"
                )

                if (!nextTitle.isNullOrEmpty()) {
                    views.setViewVisibility(R.id.meds_next_section, View.VISIBLE)
                    views.setTextViewText(R.id.meds_next_title, nextTitle)
                    views.setTextViewText(R.id.meds_next_time, nextTime ?: "")
                } else {
                    views.setViewVisibility(R.id.meds_next_section, View.GONE)
                }

            } else {
                views.setViewVisibility(R.id.meds_progress_bar, View.GONE)
                views.setViewVisibility(R.id.meds_stats_row, View.GONE)
                views.setViewVisibility(R.id.meds_next_section, View.GONE)
                views.setTextViewText(R.id.meds_status, "لا توجد علاجات مجدولة اليوم")
            }

            // Deep link: open Medication page directly
            val pendingIntent = HomeWidgetLaunchIntent.getActivity(
                context,
                MainActivity::class.java,
                Uri.parse("rattib://medication")
            )
            views.setOnClickPendingIntent(R.id.widget_root, pendingIntent)

            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}
