package com.dontori.dontori

import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.glance.GlanceId
import androidx.glance.GlanceModifier
import androidx.glance.appwidget.GlanceAppWidget
import androidx.glance.appwidget.GlanceAppWidgetReceiver
import androidx.glance.appwidget.action.actionStartActivity
import androidx.glance.appwidget.provideContent
import androidx.glance.background
import androidx.glance.layout.Column
import androidx.glance.layout.fillMaxSize
import androidx.glance.layout.padding
import androidx.glance.text.Text
import androidx.glance.text.TextStyle
import androidx.glance.Button
import androidx.glance.unit.ColorProvider
import androidx.compose.ui.graphics.Color
import java.text.NumberFormat
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale
import kotlinx.coroutines.channels.awaitClose
import kotlinx.coroutines.flow.callbackFlow
import kotlinx.coroutines.flow.conflate
import kotlinx.coroutines.flow.distinctUntilChanged

class DontoriWidgetReceiver:GlanceAppWidgetReceiver(){
    override val glanceAppWidget:GlanceAppWidget=DontoriWidget()
}

private data class WidgetDisplay(
    val configured: Boolean,
    val remaining: Long,
    val hp: Float,
    val date: String,
    val expired: Boolean,
)

private fun SharedPreferences.readDisplay() = WidgetDisplay(
    configured = getBoolean("configured", false),
    remaining = getLong("remaining", 0),
    hp = getFloat("hp", 0f).coerceIn(0f, 1f),
    date = getString("date", "") ?: "",
    expired = getBoolean("expired", false),
)

private fun SharedPreferences.observeDisplay() = callbackFlow {
    val preferences = this@observeDisplay
    val listener = SharedPreferences.OnSharedPreferenceChangeListener { _, _ ->
        trySend(preferences.readDisplay())
    }
    // Subscribe before reading so a change during initial composition is not lost.
    preferences.registerOnSharedPreferenceChangeListener(listener)
    trySend(preferences.readDisplay())
    awaitClose { preferences.unregisterOnSharedPreferenceChangeListener(listener) }
}.conflate().distinctUntilChanged()

class DontoriWidget:GlanceAppWidget(){
    override suspend fun provideGlance(context:Context,id:GlanceId){
        val cache=context.getSharedPreferences("widget_display",Context.MODE_PRIVATE)
        val initial=cache.readDisplay()
        val displays=cache.observeDisplay()
        val launch=Intent(context,MainActivity::class.java).apply{
            action="com.dontori.QUICK_ENTRY"
            flags=Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP
        }
        provideContent{
            // updateAll does not restart provideGlance during an active session.
            // Observe the cache here so consecutive saves recompose immediately.
            val display by displays.collectAsState(initial=initial)
            val (configured,remaining,hp,date,expired)=display
            val today=SimpleDateFormat("yyyy-MM-dd",Locale.US).format(Date())
            val stale=date!=today
            Column(modifier=GlanceModifier.fillMaxSize().background(ColorProvider(Color(0xFFE2EEDD))).padding(14.dp)){
                Text("DTR · ${if(configured)date else "예산을 설정해 주세요"}",style=TextStyle(color=ColorProvider(Color(0xFF183E2E)),fontSize=12.sp))
                Text(when{!configured->"첫 예산 시작하기";expired->"새 예산 설정이 필요해요";stale->"앱을 열어 오늘 예산 확인";else->"${NumberFormat.getIntegerInstance(Locale.KOREA).format(remaining)}원 남음"},style=TextStyle(color=ColorProvider(Color(0xFF183E2E)),fontSize=20.sp))
                if(configured&&!stale&&!expired){
                    val filled=(hp*10).toInt()
                    Text("${"■".repeat(filled)}${"□".repeat(10-filled)}  ${(hp*100).toInt()}%",style=TextStyle(color=ColorProvider(Color(0xFF216B52)),fontSize=14.sp))
                }
                Button(text=if(configured&&!expired)"지출 입력" else "앱 열기",onClick=actionStartActivity(launch))
            }
        }
    }
}
