package com.rattib.app

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.graphics.Color
import android.widget.RemoteViews
import android.net.Uri
import es.antonborri.home_widget.HomeWidgetPlugin
import es.antonborri.home_widget.HomeWidgetLaunchIntent

class WhiteboardWidgetProvider : AppWidgetProvider() {
    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray) {
        val widgetData = HomeWidgetPlugin.getData(context)
        for (appWidgetId in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.whiteboard_widget)

            val content = widgetData.getString("board_text", "لا توجد عناصر مثبتة في الصبورة")
            val colorHex = widgetData.getString("board_color", "")

            views.setTextViewText(R.id.board_content, content)

            if (!colorHex.isNullOrEmpty()) {
                try {
                    val colorInt = Color.parseColor(colorHex)
                    views.setInt(R.id.board_bg, "setColorFilter", colorInt)

                    val isLightColor = isColorLight(colorInt)
                    val textColor = if (isLightColor) Color.parseColor("#1F2937") else Color.parseColor("#E0E7FF")
                    val titleColor = if (isLightColor) Color.parseColor("#4F46E5") else Color.parseColor("#C7D2FE")
                    val quoteColor = if (isLightColor) Color.parseColor("#B45309") else Color.parseColor("#F59E0B")
                    val footerColor = if (isLightColor) Color.parseColor("#6B7280") else Color.parseColor("#4338CA")

                    views.setTextColor(R.id.board_content, textColor)
                    views.setTextColor(R.id.board_title, titleColor)
                    views.setTextColor(R.id.board_quote, quoteColor)
                    views.setTextColor(R.id.board_app_name, footerColor)
                } catch (e: Exception) {
                    // Fallback to defaults
                }
            } else {
                views.setTextColor(R.id.board_content, Color.parseColor("#E0E7FF"))
                views.setTextColor(R.id.board_title, Color.parseColor("#C7D2FE"))
                views.setTextColor(R.id.board_quote, Color.parseColor("#F59E0B"))
                views.setTextColor(R.id.board_app_name, Color.parseColor("#4338CA"))
                views.setInt(R.id.board_bg, "setColorFilter", Color.TRANSPARENT)
            }

            // Deep link: open Notes/Whiteboard page
            val pendingIntent = HomeWidgetLaunchIntent.getActivity(
                context,
                MainActivity::class.java,
                Uri.parse("rattib://notes")
            )
            views.setOnClickPendingIntent(R.id.widget_root, pendingIntent)

            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }

    private fun isColorLight(color: Int): Boolean {
        val darkness = 1 - (0.299 * Color.red(color) + 0.587 * Color.green(color) + 0.114 * Color.blue(color)) / 255
        return darkness < 0.5
    }
}
