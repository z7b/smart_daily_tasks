package com.rattib.app

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.view.View
import android.widget.RemoteViews
import android.net.Uri
import es.antonborri.home_widget.HomeWidgetPlugin
import es.antonborri.home_widget.HomeWidgetLaunchIntent

class AppointmentsWidgetProvider : AppWidgetProvider() {
    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray) {
        val widgetData = HomeWidgetPlugin.getData(context)
        for (appWidgetId in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.appointments_widget)

            val doctor = widgetData.getString("next_appt_doctor", "")
            val time = widgetData.getString("next_appt_time", "")
            val location = widgetData.getString("next_appt_location", "")
            val countdown = widgetData.getString("next_appt_countdown", "")

            if (!doctor.isNullOrEmpty()) {
                views.setViewVisibility(R.id.appt_content, View.VISIBLE)
                views.setViewVisibility(R.id.appt_empty_state, View.GONE)
                views.setTextViewText(R.id.appt_doctor, doctor)

                val avatarText = if (doctor.startsWith("د.") || doctor.startsWith("د/")) {
                    "د"
                } else {
                    doctor.firstOrNull()?.toString() ?: "د"
                }
                views.setTextViewText(R.id.appt_avatar, avatarText)

                if (!countdown.isNullOrEmpty()) {
                    views.setViewVisibility(R.id.appt_countdown, View.VISIBLE)
                    views.setTextViewText(R.id.appt_countdown, countdown)
                } else {
                    views.setViewVisibility(R.id.appt_countdown, View.GONE)
                }

                if (!time.isNullOrEmpty()) {
                    views.setViewVisibility(R.id.appt_time_row, View.VISIBLE)
                    views.setTextViewText(R.id.appt_time, "⏰ $time")
                } else {
                    views.setViewVisibility(R.id.appt_time_row, View.GONE)
                }

                if (!location.isNullOrEmpty()) {
                    views.setViewVisibility(R.id.appt_location_row, View.VISIBLE)
                    views.setTextViewText(R.id.appt_location, "📍 $location")
                } else {
                    views.setViewVisibility(R.id.appt_location_row, View.GONE)
                }

            } else {
                views.setViewVisibility(R.id.appt_content, View.GONE)
                views.setViewVisibility(R.id.appt_empty_state, View.VISIBLE)
                views.setViewVisibility(R.id.appt_countdown, View.GONE)
            }

            // Deep link: open Appointments page directly
            val pendingIntent = HomeWidgetLaunchIntent.getActivity(
                context,
                MainActivity::class.java,
                Uri.parse("rattib://appointments")
            )
            views.setOnClickPendingIntent(R.id.widget_root, pendingIntent)

            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}
