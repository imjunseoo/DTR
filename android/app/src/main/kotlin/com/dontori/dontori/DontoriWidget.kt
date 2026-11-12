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
    val limit = (widthDp - 24).coerceIn(0, 120)
    val rng = kotlin.random.Random(display.hashCode())
    var x = limit / 2
    var target = rng.nextInt(limit + 1)
    var pause = 0
    val stage = when {
        display.points >= 20 -> R.drawable.dori_bloom
        display.points >= 5 -> R.drawable.dori_sprout
        else -> R.drawable.dori_seed
    }
    repeat(20) { tick ->
        val resting = x == target
        val pose = when {
            tick == 0 -> stage
            resting && display.logged -> R.drawable.dori_record
            resting && display.hp >= 0.5f -> R.drawable.dori_save
            resting -> R.drawable.dori_rest
            tick % 2 == 0 -> R.drawable.dori_inhale
            else -> R.drawable.dori_idle
        }
        val frame = android.widget.RemoteViews(context.packageName, R.layout.dori_step)
        val density = context.resources.displayMetrics.density
        frame.setViewPadding(R.id.pet_step, (x * density).roundToInt(),
            if (resting || tick % 2 == 0) 0 else (2 * density).roundToInt(), 0, 0)
        frame.setImageViewResource(R.id.pet_sprite, pose)
        scene.addView(R.id.pet_walk, frame)
        if (resting && ++pause >= 2) {
            target = rng.nextInt(limit + 1)
            pause = 0
        }
        x += (target - x).coerceIn(-9, 9)
    }
    return scene
}
@Composable
private fun BudgetWidget(context: Context, display: WidgetDisplay, open: Action) {
    val size = LocalSize.current
    val padding = if (size.width >= 175.dp && size.height >= 165.dp) 14.dp else 6.dp
    val contentWidth = (size.width - padding * 2).value.coerceAtLeast(1f)
    val fontScale = context.resources.configuration.fontScale.coerceAtLeast(1f)
    val detailHeight = (size.height.value - 2 * padding.value - 48f) / fontScale
    val spacious = detailHeight >= 112 && contentWidth / fontScale >= 134
    val showHeading = detailHeight >= 68
    val today = SimpleDateFormat("yyyy-MM-dd", Locale.US).format(Date())
    val active = display.configured && !display.expired && display.date == today
    val date = display.date.replace('-', '.')
    val hpColor = if (display.hp < 0.25f) Warning else HpFill

    Column(
        modifier = GlanceModifier.fillMaxSize().background(Surface).cornerRadius(20.dp).padding(padding)
    ) {
        if (showHeading) {
            val heading = when {
                !display.configured -> "DTR"
                contentWidth / fontScale >= 144 -> "DTR · $date"
                else -> date
            }
            Text(heading, style = TextStyle(color = MutedInk, fontWeight = FontWeight.Medium, fontSize = 13.sp), maxLines = 1)
        }
        // Keep the action's 48dp row available even when the launcher offers a short cell.
        Column(modifier = GlanceModifier.fillMaxWidth().defaultWeight(), verticalAlignment = Alignment.CenterVertically) {
            if (active) {
                if (spacious) {
                    Text("오늘 남은 예산", style = TextStyle(color = MutedInk, fontSize = 14.sp))
                    Spacer(GlanceModifier.height(2.dp))
                }
                val startSize = if (spacious) 28 else 20
                val (amount, amountSize) = fitWon(context, display.remaining, contentWidth, startSize)
                Text(amount, style = TextStyle(color = Ink, fontSize = amountSize.sp, fontWeight = FontWeight.Bold), maxLines = 1)
                if (detailHeight >= 42) {
                    val percent = (display.hp * 100).roundToInt()
                    val status = when {
                        display.remaining < 0 -> " · 초과"
                        display.hp < 0.25f -> " · 주의"
                        else -> ""
                    }
                    val hpLabel = when {
                        spacious -> "생활비 HP $percent%$status"
                        showHeading -> "HP $percent%"
                        else -> "${date.takeLast(5)} · $percent%"
                    }
                    if (spacious) Spacer(GlanceModifier.height(8.dp))
                    Text(hpLabel, style = TextStyle(color = hpColor, fontSize = if (spacious) 16.sp else 13.sp, fontWeight = FontWeight.Medium), maxLines = 1)
                    if (spacious) {
                        Spacer(GlanceModifier.height(4.dp))
                        LinearProgressIndicator(display.hp, GlanceModifier.fillMaxWidth().height(6.dp), hpColor, HpTrack)
                    }
                }
            } else {
                val message = when {
                    !display.configured -> "첫 예산 설정"
                    display.expired -> "새 예산 설정"
                    else -> "오늘 예산 갱신"
                }
                Text(message, style = TextStyle(color = Ink, fontSize = if (spacious) 22.sp else 15.sp, fontWeight = FontWeight.Bold), maxLines = 2)
            }
        }
        if (active && detailHeight >= 190 && contentWidth >= 56) {
            androidx.glance.layout.Row(verticalAlignment = Alignment.CenterVertically) {
                androidx.glance.appwidget.AndroidRemoteViews(
                    petWalk(context, display, (contentWidth - if (contentWidth / fontScale >= 145) 90 else 0).toInt())
                )
                if (contentWidth / fontScale >= 145) Text(if (display.logged) "기록했어요!" else if (display.hp < 0.25f) "천천히 살펴봐요." else "오늘도 한 알씩.",
                    style = TextStyle(color = MutedInk, fontSize = 13.sp), maxLines = 1)
            }
        }
        Button(
            text = when {
                !display.configured || display.expired -> "앱 열기"
                contentWidth / fontScale < 80 -> "입력"
                else -> "지출 입력"
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
