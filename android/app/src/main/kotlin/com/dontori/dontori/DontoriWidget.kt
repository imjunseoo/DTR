package com.dontori.dontori

import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.graphics.Paint
import android.graphics.Typeface
import android.util.TypedValue
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.glance.ButtonDefaults
import androidx.glance.LocalSize
import androidx.glance.action.Action
import androidx.glance.GlanceId
import androidx.glance.GlanceModifier
import androidx.glance.appwidget.GlanceAppWidget
import androidx.glance.appwidget.GlanceAppWidgetReceiver
import androidx.glance.appwidget.LinearProgressIndicator
import androidx.glance.appwidget.SizeMode
import androidx.glance.appwidget.cornerRadius
import androidx.glance.appwidget.action.actionStartActivity
import androidx.glance.appwidget.provideContent
import androidx.glance.background
import androidx.glance.layout.Column
import androidx.glance.layout.Alignment
import androidx.glance.layout.Spacer
import androidx.glance.layout.fillMaxSize
import androidx.glance.layout.fillMaxWidth
import androidx.glance.layout.height
import androidx.glance.layout.padding
import androidx.glance.text.Text
import androidx.glance.text.FontWeight
import androidx.glance.text.TextStyle
import androidx.glance.Button
import androidx.glance.unit.ColorProvider
import androidx.compose.ui.graphics.Color
import java.text.NumberFormat
import java.math.BigDecimal
import java.math.RoundingMode
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale
import kotlin.math.roundToInt
import kotlinx.coroutines.channels.awaitClose
import kotlinx.coroutines.flow.callbackFlow
import kotlinx.coroutines.flow.conflate
import kotlinx.coroutines.flow.distinctUntilChanged

class DontoriWidgetReceiver:GlanceAppWidgetReceiver(){
    override val glanceAppWidget:GlanceAppWidget=DontoriWidget()
}

private data class WidgetDisplay(
    val points: Int,
    val logged: Boolean,
    val configured: Boolean,
    val remaining: Long,
    val hp: Float,
    val date: String,
    val expired: Boolean,
)

private fun SharedPreferences.readDisplay() = WidgetDisplay(
    points = getInt("petPoints", 0),
    logged = getBoolean("loggedToday", false),
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

private val Surface = ColorProvider(Color(0xFFFFDBAD))
private val Ink = ColorProvider(Color(0xFF37251C))
private val MutedInk = ColorProvider(Color(0xFF685044))
private val HpFill = ColorProvider(Color(0xFF9D390E))
private val HpTrack = ColorProvider(Color(0xFFD9AC80))
private val Warning = ColorProvider(Color(0xFF922E2A))
private val ActionInk = ColorProvider(Color(0xFF983C17))
private val ActionSurface = ColorProvider(Color(0xFFFFFDF8))

class DontoriWidget : GlanceAppWidget() {
    override val sizeMode = SizeMode.Exact

    override suspend fun provideGlance(context: Context, id: GlanceId) {
        val cache = context.getSharedPreferences("widget_display", Context.MODE_PRIVATE)
        val initial = cache.readDisplay()
        val displays = cache.observeDisplay()
        val launch = Intent(context, MainActivity::class.java).apply {
            action = "com.dontori.QUICK_ENTRY"
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP
        }
        provideContent {
            val display by displays.collectAsState(initial = initial)
            BudgetWidget(context, display, actionStartActivity(launch))
        }
    }
}

private fun petWalk(context: Context, display: WidgetDisplay, widthDp: Int): android.widget.RemoteViews {
    val scene = android.widget.RemoteViews(context.packageName, R.layout.dori_idle)
    scene.removeAllViews(R.id.pet_walk)
    val limit = (widthDp - 48 - 16).coerceAtLeast(0)
    val stage = when {
        display.points >= 20 -> "bloom"
        display.points >= 5 -> "sprout"
        else -> "seed"
    }
    val clips = petClips.getValue(stage)
    val density = context.resources.displayMetrics.density
    val stride = minOf(4, limit / 8)
    var x = (limit - stride * 8) / 2
    var elapsedMs = 0
    var ticks = 0
    fun play(name: String, direction: Int = 0) {
        val clip = clips.getValue(name)
        for (i in clip.frames.indices) {
            elapsedMs += clip.durations[i]
            val nextTick = maxOf(ticks + 1, (elapsedMs / 125f).roundToInt())
            repeat(nextTick - ticks) {
                val frame = android.widget.RemoteViews(context.packageName, R.layout.dori_step)
                frame.setViewPadding(R.id.pet_step, ((x + 8) * density).roundToInt(), 0, 0, 0)
                frame.setImageViewResource(R.id.pet_sprite, clip.frames[i])
                scene.addView(R.id.pet_walk, frame)
            }
            ticks = nextTick
            x += direction * stride
        }
    }
    play("idle")
    repeat(2) { play("walk_right", 1) }
    play("stop")
    play("rest")
    repeat(2) { play("walk_left", -1) }
    play("stop")
    play(if (display.logged) "record" else if (display.hp >= 0.5f) "save" else "rest")
    return scene
}
@Composable
private fun BudgetWidget(context: Context, display: WidgetDisplay, open: Action) {
    val size = LocalSize.current
    val padding = if (size.width >= 175.dp && size.height >= 165.dp) 12.dp else 6.dp
    val contentWidth = (size.width - padding * 2).value.coerceAtLeast(1f)
    val fontScale = context.resources.configuration.fontScale.coerceAtLeast(1f)
    val available = size.height.value - 2 * padding.value - 48f
    val compact = available < 76f * fontScale
    val spacious = available >= 160f * fontScale && contentWidth / fontScale >= 134
    // Reserve the monetary summary before assigning any height to scenery.
    val summaryHeight = if (compact) available else (if (spacious) 112f else 88f) * fontScale
    val freeHeight = available - summaryHeight
    val showHeading = freeHeight >= 32f * fontScale + 54f
    val yardHeight = freeHeight - (if (showHeading) 28f * fontScale else 0f) - 4f
    val today = SimpleDateFormat("yyyy-MM-dd", Locale.US).format(Date())
    val active = display.configured && !display.expired && display.date == today
    val date = display.date
    val hpColor = if (display.hp < 0.25f) Warning else HpFill

    Column(
        modifier = GlanceModifier.fillMaxSize().background(Surface).cornerRadius(20.dp).padding(padding)
    ) {
        if (active) {
            if (showHeading) {
                Text("돈토리 · $date", style = TextStyle(color = MutedInk, fontSize = 13.sp), maxLines = 1)
            }
            if (yardHeight >= 54 && contentWidth >= 72) {
                androidx.glance.appwidget.AndroidRemoteViews(
                    petWalk(context, display, contentWidth.toInt()),
                    modifier = GlanceModifier.fillMaxWidth().height(yardHeight.dp)
                )
            }
            if (!compact) {
                Text("오늘 남은 예산", style = TextStyle(color = MutedInk, fontSize = 13.sp), maxLines = 1)
            }
            val amountSp = if (compact) minOf(18f, available * 0.34f / fontScale).toInt().coerceAtLeast(10) else if (spacious) 28 else 20
            val (amount, fittedSize) = fitWon(context, display.remaining, contentWidth, amountSp)
            Text(amount, style = TextStyle(color = Ink, fontSize = minOf(amountSp, fittedSize).sp, fontWeight = FontWeight.Bold), maxLines = 1)
            val hpSp = if (compact) minOf(13f, available * 0.25f / fontScale) else 15f
            val percent = (display.hp * 100).roundToInt()
            val hpLabel = if (compact) "HP $percent%" else "생활비 HP $percent%" + if (display.remaining < 0) " · 초과" else ""
            Text(hpLabel, style = TextStyle(color = hpColor, fontSize = hpSp.sp, fontWeight = FontWeight.Medium), maxLines = 1)
            LinearProgressIndicator(display.hp, GlanceModifier.fillMaxWidth().height(if (compact) 4.dp else 8.dp), hpColor, HpTrack)
        } else {
            Text(when {
                !display.configured -> "첫 예산 설정"
                display.expired -> "새 예산 설정"
                else -> "오늘 예산 갱신"
            }, style = TextStyle(color = Ink, fontSize = 15.sp), maxLines = 1)
        }
        Spacer(GlanceModifier.defaultWeight())
        Button(
            text = when {
                !display.configured || display.expired -> "앱 열기"
                contentWidth / fontScale < 80 -> "입력"
                else -> if (contentWidth / fontScale >= 130) "간편 지출 입력" else "지출 입력"
            },
            onClick = open,
            modifier = GlanceModifier.fillMaxWidth().height(48.dp),
            style = TextStyle(fontSize = if (spacious) 16.sp else 14.sp, fontWeight = FontWeight.Medium),
            colors = ButtonDefaults.buttonColors(backgroundColor = ActionSurface, contentColor = ActionInk),
            maxLines = 1,
        )
    }
}

// Prefer exact won values. Only compact when even the smallest legible size won't fit.
private fun fitWon(context: Context, won: Long, widthDp: Float, preferredSp: Int): Pair<String, Int> {
    val metrics = context.resources.displayMetrics
    val widthPx = (widthDp - 2).coerceAtLeast(1f) * metrics.density
    val paint = Paint(Paint.ANTI_ALIAS_FLAG).apply { typeface = Typeface.DEFAULT_BOLD }
    val exact = "${NumberFormat.getIntegerInstance(Locale.KOREA).format(won)}원"
    for (size in preferredSp downTo 14) {
        paint.textSize = TypedValue.applyDimension(TypedValue.COMPLEX_UNIT_SP, size.toFloat(), metrics)
        if (paint.measureText(exact) <= widthPx) return exact to size
    }
    val value = BigDecimal.valueOf(won)
    for ((places, unit) in listOf(16 to "경", 12 to "조", 8 to "억", 4 to "만")) {
        if (value.abs() >= BigDecimal.TEN.pow(places)) {
            val compact = value.movePointLeft(places).setScale(1, RoundingMode.DOWN).stripTrailingZeros()
            val prefix = if (compact.movePointRight(places).compareTo(value) == 0) "" else "약 "
            return "$prefix${compact.toPlainString()}${unit}원" to 14
        }
    }
    return exact to 14
}
