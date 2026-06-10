package com.rattib.app

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.view.View
import android.widget.RemoteViews
import android.net.Uri
import es.antonborri.home_widget.HomeWidgetPlugin
import es.antonborri.home_widget.HomeWidgetLaunchIntent

class TasksWidgetProvider : AppWidgetProvider() {
    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray) {
        val widgetData = HomeWidgetPlugin.getData(context)
        for (appWidgetId in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.tasks_widget)

            val count = widgetData.getInt("tasks_count", 0)
            val completedCount = widgetData.getInt("tasks_completed", 0)
            val totalCount = widgetData.getInt("tasks_total", 0)

            if (count > 0) {
                views.setViewVisibility(R.id.tasks_empty_state, View.GONE)
                views.setViewVisibility(R.id.tasks_progress_bar_container, View.VISIBLE)
                views.setTextViewText(R.id.tasks_badge, "$count متبقية")

                val progressPct = if (totalCount > 0) ((completedCount.toFloat() / totalCount) * 100).toInt() else 0
                views.setProgressBar(R.id.tasks_progress, 100, progressPct, false)
                views.setTextViewText(R.id.tasks_count, "$completedCount/$totalCount")

                val task1 = widgetData.getString("task_1_title", "")
                if (!task1.isNullOrEmpty()) {
                    views.setViewVisibility(R.id.task_item_1, View.VISIBLE)
                    views.setTextViewText(R.id.task_title_1, task1)
                } else {
                    views.setViewVisibility(R.id.task_item_1, View.GONE)
                }

                val task2 = widgetData.getString("task_2_title", "")
                if (!task2.isNullOrEmpty()) {
                    views.setViewVisibility(R.id.task_item_2, View.VISIBLE)
                    views.setTextViewText(R.id.task_title_2, task2)
                } else {
                    views.setViewVisibility(R.id.task_item_2, View.GONE)
                }

                val task3 = widgetData.getString("task_3_title", "")
                if (!task3.isNullOrEmpty()) {
                    views.setViewVisibility(R.id.task_item_3, View.VISIBLE)
                    views.setTextViewText(R.id.task_title_3, task3)
                } else {
                    views.setViewVisibility(R.id.task_item_3, View.GONE)
                }

            } else {
                views.setViewVisibility(R.id.tasks_empty_state, View.VISIBLE)
                views.setViewVisibility(R.id.tasks_progress_bar_container, View.GONE)
                views.setViewVisibility(R.id.task_item_1, View.GONE)
                views.setViewVisibility(R.id.task_item_2, View.GONE)
                views.setViewVisibility(R.id.task_item_3, View.GONE)
                views.setTextViewText(R.id.tasks_badge, "مكتملة ✓")
            }

            // Deep link: open Tasks page directly
            val pendingIntent = HomeWidgetLaunchIntent.getActivity(
                context,
                MainActivity::class.java,
                Uri.parse("rattib://tasks")
            )
            views.setOnClickPendingIntent(R.id.widget_root, pendingIntent)

            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}
