package com.privateagent.private_agent

import android.app.ActivityManager
import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.graphics.*
import android.hardware.camera2.CameraCharacteristics
import android.hardware.camera2.CameraManager
import android.os.BatteryManager
import android.os.Build
import android.widget.RemoteViews
import kotlin.math.abs
import kotlin.math.cos
import kotlin.math.roundToInt
import kotlin.math.sin

/**
 * Stark Mark LXXXV 3D Arc Reactor & Tactical Telemetry Home Screen Widget.
 *
 * Renders a high-DPI 6-layer 3D depth-parallax Arc Reactor + live hardware
 * telemetry console (Wattage, Voltage, Current, Core Temperature in °C/K,
 * System RAM, Harmonic Oscilloscope) directly onto the Android Home Screen,
 * with interactive hot-zones for 3D perspective tilt, Voice Command, Spoken
 * Czech Telemetry Briefing, Full-Screen 3D Console, and Hardware Torch toggle.
 */
class JarvisArcReactorWidgetProvider : AppWidgetProvider() {

    companion object {
        const val ACTION_REFRESH_TILT = "com.privateagent.private_agent.WIDGET_REFRESH_TILT"
        const val ACTION_OPEN_REACTOR_HUD = "com.privateagent.private_agent.WIDGET_OPEN_REACTOR_HUD"
        const val ACTION_VOICE_COMMAND = "com.privateagent.private_agent.WIDGET_VOICE_COMMAND"
        const val ACTION_SPEAK_TELEMETRY = "com.privateagent.private_agent.WIDGET_SPEAK_TELEMETRY"
        const val ACTION_TOGGLE_TORCH = "com.privateagent.private_agent.WIDGET_TOGGLE_TORCH"

        private const val PREFS_NAME = "jarvis_widget_prefs"
        private const val KEY_TILT_INDEX = "tilt_index"
        private const val KEY_PHASE_DEG = "phase_deg"
        private const val KEY_TORCH_ON = "torch_on"

        private val TILT_PRESETS = arrayOf(
             floatArrayOf(0.0f, 0.0f),
             floatArrayOf(0.65f, -0.45f),
             floatArrayOf(-0.65f, -0.40f),
             floatArrayOf(0.55f, 0.55f),
             floatArrayOf(-0.60f, 0.50f),
             floatArrayOf(0.0f, -0.75f)
        )

        fun updateAllWidgets(context: Context) {
            try {
                val manager = AppWidgetManager.getInstance(context)
                val component = ComponentName(context, JarvisArcReactorWidgetProvider::class.java)
                val ids = manager.getAppWidgetIds(component)
                if (ids != null && ids.isNotEmpty()) {
                    for (id in ids) {
                        updateSingleWidget(context, manager, id)
                    }
                }
            } catch (_: Exception) {}
        }

        private fun buildBroadcastPendingIntent(context: Context, action: String, reqCode: Int): PendingIntent {
            val intent = Intent(context, JarvisArcReactorWidgetProvider::class.java).apply {
                this.action = action
            }
            val flags = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            } else {
                PendingIntent.FLAG_UPDATE_CURRENT
            }
            return PendingIntent.getBroadcast(context, reqCode, intent, flags)
        }

        fun updateSingleWidget(context: Context, appWidgetManager: AppWidgetManager, appWidgetId: Int) {
            val views = RemoteViews(context.packageName, R.layout.jarvis_arc_reactor_widget)

            val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            val tiltIdx = prefs.getInt(KEY_TILT_INDEX, 1) % TILT_PRESETS.size
            val phaseDeg = prefs.getFloat(KEY_PHASE_DEG, 24f)
            val torchOn = prefs.getBoolean(KEY_TORCH_ON, false)
            val tilt = TILT_PRESETS[tiltIdx]

            val bitmap = render3DReactorWidgetBitmap(context, tilt[0], tilt[1], tiltIdx, phaseDeg, torchOn)
            views.setImageViewBitmap(R.id.widget_canvas_image, bitmap)

            views.setOnClickPendingIntent(
                R.id.btn_reactor_core,
                buildBroadcastPendingIntent(context, ACTION_OPEN_REACTOR_HUD, 101)
            )
            views.setOnClickPendingIntent(
                R.id.btn_tilt_3d,
                buildBroadcastPendingIntent(context, ACTION_REFRESH_TILT, 102)
            )
            views.setOnClickPendingIntent(
                R.id.btn_voice_cmd,
                buildBroadcastPendingIntent(context, ACTION_VOICE_COMMAND, 103)
            )
            views.setOnClickPendingIntent(
                R.id.btn_speak_status,
                buildBroadcastPendingIntent(context, ACTION_SPEAK_TELEMETRY, 104)
            )
            views.setOnClickPendingIntent(
                R.id.btn_torch,
                buildBroadcastPendingIntent(context, ACTION_TOGGLE_TORCH, 105)
            )

            appWidgetManager.updateAppWidget(appWidgetId, views)
        }

        private fun render3DReactorWidgetBitmap(
            context: Context,
            tiltX: Float,
            tiltY: Float,
            tiltIdx: Int,
            phaseDeg: Float,
            torchOn: Boolean
        ): Bitmap {
            val width = 1000
            val height = 520
            val bmp = Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888)
            val canvas = Canvas(bmp)

            // Fetch real-time hardware battery & RAM telemetry
            val bm = context.getSystemService(Context.BATTERY_SERVICE) as? BatteryManager
            val batteryIntent = context.registerReceiver(null, IntentFilter(Intent.ACTION_BATTERY_CHANGED))
            val level = (bm?.getIntProperty(BatteryManager.BATTERY_PROPERTY_CAPACITY) ?: -1).let {
                if (it in 0..100) it else {
                    val l = batteryIntent?.getIntExtra(BatteryManager.EXTRA_LEVEL, 85) ?: 85
                    val s = batteryIntent?.getIntExtra(BatteryManager.EXTRA_SCALE, 100) ?: 100
                    if (s > 0) (l * 100) / s else 85
                }
            }
            val status = batteryIntent?.getIntExtra(BatteryManager.EXTRA_STATUS, -1) ?: -1
            val isCharging = status == BatteryManager.BATTERY_STATUS_CHARGING ||
                    status == BatteryManager.BATTERY_STATUS_FULL ||
                    (if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) bm?.isCharging == true else false)
            val voltageMv = batteryIntent?.getIntExtra(BatteryManager.EXTRA_VOLTAGE, 4120) ?: 4120
            val tempRaw = batteryIntent?.getIntExtra(BatteryManager.EXTRA_TEMPERATURE, 310) ?: 310
            val tempC = if (tempRaw > 0) tempRaw / 10.0 else 31.0
            val tempK = tempC + 273.15
            val plugged = batteryIntent?.getIntExtra(BatteryManager.EXTRA_PLUGGED, -1) ?: -1
            val currentUa = bm?.getIntProperty(BatteryManager.BATTERY_PROPERTY_CURRENT_NOW) ?: 0
            val currentMa = (abs(currentUa) / 1000).let { if (it > 0) it else if (isCharging) 2450 else 380 }
            val volts = if (voltageMv > 0) voltageMv / 1000.0 else 4.1
            val wattage = ((volts * (currentMa / 1000.0)) * 10.0).roundToInt() / 10.0

            val chargeSource = when (plugged) {
                BatteryManager.BATTERY_PLUGGED_AC -> "AC TURBO"
                BatteryManager.BATTERY_PLUGGED_USB -> "USB SBĚRNICE"
                BatteryManager.BATTERY_PLUGGED_WIRELESS -> "INDUKCE"
                else -> if (isCharging) "PŘÍMÝ TOK" else "INTERNÍ JÁDRO"
            }

            val am = context.getSystemService(Context.ACTIVITY_SERVICE) as? ActivityManager
            val memInfo = ActivityManager.MemoryInfo()
            am?.getMemoryInfo(memInfo)
            val totalRamGb = if (memInfo.totalMem > 0) memInfo.totalMem / (1024.0 * 1024.0 * 1024.0) else 8.0
            val usedRamGb = if (memInfo.totalMem > 0) (memInfo.totalMem - memInfo.availMem) / (1024.0 * 1024.0 * 1024.0) else 4.2
            val ramPct = ((usedRamGb / totalRamGb) * 100.0).roundToInt().coerceIn(1, 99)

            val primaryCyan = if (isCharging) Color.parseColor("#38BDF8") else Color.parseColor("#00E5FF")
            val coreBlue = Color.parseColor("#0284C7")
            val starkGold = Color.parseColor("#F59E0B")
            val plasmaGreen = Color.parseColor("#10B981")

            // 1. Chamfered Octagonal Armor Chassis Background
            val cut = 26f
            val chassisPath = Path().apply {
                moveTo(cut, 6f)
                lineTo(width - cut, 6f)
                lineTo(width - 6f, cut)
                lineTo(width - 6f, height - cut)
                lineTo(width - cut, height - 6f)
                lineTo(cut, height - 6f)
                lineTo(6f, height - cut)
                lineTo(6f, cut)
                close()
            }

            val bgPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
                shader = LinearGradient(
                    0f, 0f, width.toFloat(), height.toFloat(),
                    intArrayOf(
                        Color.parseColor("#F2030914"),
                        Color.parseColor("#F5071326"),
                        Color.parseColor("#F202060D")
                    ),
                    floatArrayOf(0f, 0.55f, 1f),
                    Shader.TileMode.CLAMP
                )
            }
            canvas.drawPath(chassisPath, bgPaint)

            // Blueprint tactical grid inside chassis
            canvas.save()
            canvas.clipPath(chassisPath)
            val gridPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
                color = Color.argb(16, 56, 189, 248)
                strokeWidth = 1f
            }
            var gx = 40f
            while (gx < width) {
                canvas.drawLine(gx, 0f, gx, height.toFloat(), gridPaint)
                gx += 40f
            }
            var gy = 40f
            while (gy < height) {
                canvas.drawLine(0f, gy, width.toFloat(), gy, gridPaint)
                gy += 40f
            }
            canvas.restore()

            // Outer armor border + corner brackets
            val borderPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
                style = Paint.Style.STROKE
                strokeWidth = 2.5f
                shader = LinearGradient(
                    0f, 0f, width.toFloat(), height.toFloat(),
                    intArrayOf(primaryCyan, Color.parseColor("#334155"), starkGold, primaryCyan),
                    floatArrayOf(0f, 0.4f, 0.75f, 1f),
                    Shader.TileMode.CLAMP
                )
            }
            canvas.drawPath(chassisPath, borderPaint)

            // -----------------------------------------------------------------
            // 2. Left Section: 6-Layer 3D Mark LXXXV Arc Reactor (cx=218, cy=196)
            // -----------------------------------------------------------------
            val cx = 218f
            val cy = 196f
            val r = 158f
            val phaseRad = Math.toRadians(phaseDeg.toDouble()).toFloat()

            fun layerOffset(zDepth: Float): PointF {
                return PointF(cx + tiltX * zDepth * 1.45f, cy + tiltY * zDepth * 1.45f)
            }

            // Ambient volumetric glow behind reactor
            val ambientPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
                shader = RadialGradient(
                    cx, cy, r * 1.18f,
                    intArrayOf(
                        Color.argb(if (isCharging) 110 else 75, 56, 189, 248),
                        Color.argb(30, 2, 132, 199),
                        Color.TRANSPARENT
                    ),
                    floatArrayOf(0f, 0.65f, 1f),
                    Shader.TileMode.CLAMP
                )
            }
            canvas.drawCircle(cx, cy, r * 1.18f, ambientPaint)

            // LAYER -16z: Deep Reactor Pit
            val pPit = layerOffset(-16f)
            val pitPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
                shader = RadialGradient(
                    pPit.x, pPit.y, r * 0.92f,
                    intArrayOf(Color.parseColor("#01040A"), Color.parseColor("#071426"), Color.parseColor("#0F243C")),
                    floatArrayOf(0f, 0.7f, 1f),
                    Shader.TileMode.CLAMP
                )
            }
            canvas.drawCircle(pPit.x, pPit.y, r * 0.92f, pitPaint)

            // LAYER -10z: 24 Counter-Rotating Deep Turbine Blades
            val pTurbine = layerOffset(-10f)
            val bladePaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
                style = Paint.Style.FILL
                color = Color.parseColor("#1E293B")
            }
            val bladeEdgePaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
                style = Paint.Style.STROKE
                strokeWidth = 1.3f
                color = Color.argb(120, 148, 163, 184)
            }
            for (i in 0 until 24) {
                val a1 = (i * 15.0 * Math.PI / 180.0) - phaseRad * 0.6
                val a2 = a1 + 0.14
                val rIn = r * 0.40f
                val rOut = r * 0.78f
                val path = Path().apply {
                    moveTo((pTurbine.x + rIn * cos(a1)).toFloat(), (pTurbine.y + rIn * sin(a1)).toFloat())
                    lineTo((pTurbine.x + rOut * cos(a2)).toFloat(), (pTurbine.y + rOut * sin(a2)).toFloat())
                    lineTo((pTurbine.x + rOut * cos(a2 + 0.09)).toFloat(), (pTurbine.y + rOut * sin(a2 + 0.09)).toFloat())
                    lineTo((pTurbine.x + rIn * cos(a1 + 0.09)).toFloat(), (pTurbine.y + rIn * sin(a1 + 0.09)).toFloat())
                    close()
                }
                canvas.drawPath(path, bladePaint)
                canvas.drawPath(path, bladeEdgePaint)
            }

            // LAYER -4z: Volumetric Cherenkov Plasma Containment Torus
            val pPlasma = layerOffset(-4f)
            val plasmaRingPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
                style = Paint.Style.STROKE
                strokeWidth = r * 0.25f
                shader = RadialGradient(
                    pPlasma.x, pPlasma.y, r * 0.80f,
                    intArrayOf(
                        Color.TRANSPARENT,
                        Color.argb(235, 2, 132, 199),
                        Color.argb(255, 186, 230, 253),
                        Color.argb(220, 56, 189, 248),
                        Color.TRANSPARENT
                    ),
                    floatArrayOf(0.42f, 0.56f, 0.67f, 0.78f, 0.90f),
                    Shader.TileMode.CLAMP
                )
            }
            canvas.drawCircle(pPlasma.x, pPlasma.y, r * 0.66f, plasmaRingPaint)

            // LAYER 0z: Brushed Titanium Outer Chassis + 72 Vernier Graduations + 12 Hex Bolts
            val pChassis = layerOffset(0f)
            val bezelPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
                style = Paint.Style.STROKE
                strokeWidth = r * 0.14f
                shader = SweepGradient(
                    pChassis.x, pChassis.y,
                    intArrayOf(
                        Color.parseColor("#1E293B"),
                        Color.parseColor("#64748B"),
                        Color.parseColor("#0F172A"),
                        Color.parseColor("#94A3B8"),
                        Color.parseColor("#1E293B")
                    ),
                    floatArrayOf(0f, 0.25f, 0.5f, 0.78f, 1f)
                )
            }
            canvas.drawCircle(pChassis.x, pChassis.y, r * 0.90f, bezelPaint)

            val tickPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
                color = Color.argb(180, 148, 163, 184)
                strokeWidth = 1.5f
            }
            for (i in 0 until 72) {
                val ang = i * 5.0 * Math.PI / 180.0
                val major = i % 6 == 0
                val r1 = if (major) r * 0.83f else r * 0.86f
                val r2 = r * 0.95f
                tickPaint.color = if (major) primaryCyan else Color.argb(140, 148, 163, 184)
                tickPaint.strokeWidth = if (major) 2.2f else 1.1f
                canvas.drawLine(
                    (pChassis.x + r1 * cos(ang)).toFloat(),
                    (pChassis.y + r1 * sin(ang)).toFloat(),
                    (pChassis.x + r2 * cos(ang)).toFloat(),
                    (pChassis.y + r2 * sin(ang)).toFloat(),
                    tickPaint
                )
            }

            // 12 Hex bolts on titanium bezel
            val boltPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
                style = Paint.Style.FILL
                color = Color.parseColor("#0F172A")
            }
            val boltStroke = Paint(Paint.ANTI_ALIAS_FLAG).apply {
                style = Paint.Style.STROKE
                strokeWidth = 1.5f
                color = Color.parseColor("#94A3B8")
            }
            for (i in 0 until 12) {
                val ang = (i * 30.0 + 15.0) * Math.PI / 180.0
                val bx = (pChassis.x + r * 0.90f * cos(ang)).toFloat()
                val by = (pChassis.y + r * 0.90f * sin(ang)).toFloat()
                canvas.drawCircle(bx, by, 4.2f, boltPaint)
                canvas.drawCircle(bx, by, 4.2f, boltStroke)
            }

            // LAYER +6z: 10 Electromagnetic Copper/Gold Stator Coils + Electric Arcs
            val pCoils = layerOffset(6f)
            val coilBasePaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
                style = Paint.Style.FILL
                color = Color.parseColor("#1C1917")
            }
            val wirePaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
                style = Paint.Style.STROKE
                strokeWidth = 2.2f
                color = Color.parseColor("#F59E0B")
            }
            val wireHighlight = Paint(Paint.ANTI_ALIAS_FLAG).apply {
                style = Paint.Style.STROKE
                strokeWidth = 1.0f
                color = Color.parseColor("#FEF08A")
            }
            for (i in 0 until 10) {
                val ang = i * 36.0 * Math.PI / 180.0
                val rIn = r * 0.53f
                val rOut = r * 0.79f
                val spread = 0.11
                val coilPath = Path().apply {
                    moveTo((pCoils.x + rIn * cos(ang - spread)).toFloat(), (pCoils.y + rIn * sin(ang - spread)).toFloat())
                    lineTo((pCoils.x + rOut * cos(ang - spread)).toFloat(), (pCoils.y + rOut * sin(ang - spread)).toFloat())
                    lineTo((pCoils.x + rOut * cos(ang + spread)).toFloat(), (pCoils.y + rOut * sin(ang + spread)).toFloat())
                    lineTo((pCoils.x + rIn * cos(ang + spread)).toFloat(), (pCoils.y + rIn * sin(ang + spread)).toFloat())
                    close()
                }
                canvas.drawPath(coilPath, coilBasePaint)
                for (w in 1..6) {
                    val t = w / 7.0f
                    val rw = rIn + (rOut - rIn) * t
                    val x1 = (pCoils.x + rw * cos(ang - spread * 0.92)).toFloat()
                    val y1 = (pCoils.y + rw * sin(ang - spread * 0.92)).toFloat()
                    val x2 = (pCoils.x + rw * cos(ang + spread * 0.92)).toFloat()
                    val y2 = (pCoils.y + rw * sin(ang + spread * 0.92)).toFloat()
                    canvas.drawLine(x1, y1, x2, y2, wirePaint)
                    canvas.drawLine(x1, y1, x2, y2, wireHighlight)
                }
            }

            // LAYER +13z: Mark LXXXV Vibranium Triangular Core Lattice + Laser Pinch Point
            val pCore = layerOffset(13f)
            val coreRingPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
                style = Paint.Style.STROKE
                strokeWidth = 5f
                color = Color.parseColor("#E0F2FE")
            }
            canvas.drawCircle(pCore.x, pCore.y, r * 0.42f, coreRingPaint)

            val coreGlowPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
                shader = RadialGradient(
                    pCore.x, pCore.y, r * 0.42f,
                    intArrayOf(
                        Color.WHITE,
                        Color.parseColor("#BAE6FD"),
                        primaryCyan,
                        Color.argb(0, 2, 132, 199)
                    ),
                    floatArrayOf(0f, 0.35f, 0.75f, 1f),
                    Shader.TileMode.CLAMP
                )
            }
            canvas.drawCircle(pCore.x, pCore.y, r * 0.40f, coreGlowPaint)

            // 3 Heavy Triangular Struts + Vibranium Triangle Lattice
            val strutPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
                style = Paint.Style.STROKE
                strokeWidth = 4.5f
                color = Color.parseColor("#0F172A")
                strokeCap = Paint.Cap.ROUND
            }
            val triPath = Path()
            for (i in 0 until 3) {
                val a = (i * 120.0 - 90.0) * Math.PI / 180.0
                val sx = (pCore.x + r * 0.44f * cos(a)).toFloat()
                val sy = (pCore.y + r * 0.44f * sin(a)).toFloat()
                val ex = (pCore.x + r * 0.16f * cos(a)).toFloat()
                val ey = (pCore.y + r * 0.16f * sin(a)).toFloat()
                canvas.drawLine(sx, sy, ex, ey, strutPaint)
                val tx = (pCore.x + r * 0.32f * cos(a)).toFloat()
                val ty = (pCore.y + r * 0.32f * sin(a)).toFloat()
                if (i == 0) triPath.moveTo(tx, ty) else triPath.lineTo(tx, ty)
            }
            triPath.close()
            val triStroke = Paint(Paint.ANTI_ALIAS_FLAG).apply {
                style = Paint.Style.STROKE
                strokeWidth = 2.8f
                color = Color.parseColor("#0284C7")
            }
            canvas.drawPath(triPath, triStroke)

            // Center percentage badge inside the core
            val pctPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
                color = Color.parseColor("#020617")
                textSize = 28f
                typeface = Typeface.create(Typeface.MONOSPACE, Typeface.BOLD)
                textAlign = Paint.Align.CENTER
            }
            canvas.drawText("$level%", pCore.x, pCore.y + 10f, pctPaint)

            // Label under 3D reactor
            val subReactorPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
                color = Color.parseColor("#94A3B8")
                textSize = 13.5f
                typeface = Typeface.create(Typeface.MONOSPACE, Typeface.BOLD)
                textAlign = Paint.Align.CENTER
            }
            canvas.drawText("MK-LXXXV // KLEPNĚTE PRO 3D KONZOLI", cx, 382f, subReactorPaint)

            // -----------------------------------------------------------------
            // 3. Right Section: Stark Telemetry Console (x=415..972, y=22..386)
            // -----------------------------------------------------------------
            val headerPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
                color = primaryCyan
                textSize = 16f
                typeface = Typeface.create(Typeface.MONOSPACE, Typeface.BOLD)
            }
            canvas.drawText("J.A.R.V.I.S. // 3D TELEMETRIE JÁDRA", 418f, 40f, headerPaint)

            // Status / Tilt badge on top right
            val badgeRect = RectF(772f, 18f, 972f, 48f)
            val badgeBg = Paint(Paint.ANTI_ALIAS_FLAG).apply {
                color = if (isCharging) Color.argb(55, 16, 185, 129) else Color.argb(45, 56, 189, 248)
                style = Paint.Style.FILL
            }
            val badgeBorder = Paint(Paint.ANTI_ALIAS_FLAG).apply {
                color = if (isCharging) plasmaGreen else primaryCyan
                style = Paint.Style.STROKE
                strokeWidth = 1.5f
            }
            canvas.drawRoundRect(badgeRect, 8f, 8f, badgeBg)
            canvas.drawRoundRect(badgeRect, 8f, 8f, badgeBorder)

            val badgeText = Paint(Paint.ANTI_ALIAS_FLAG).apply {
                color = Color.WHITE
                textSize = 13f
                typeface = Typeface.create(Typeface.MONOSPACE, Typeface.BOLD)
                textAlign = Paint.Align.CENTER
            }
            canvas.drawText(
                if (isCharging) "⚡ NABÍJENÍ // 3D ⟳" else "3D NÁKLON [${tiltIdx + 1}/6] ⟳",
                badgeRect.centerX(),
                badgeRect.centerY() + 5f,
                badgeText
            )

            // 4 Tactical Telemetry Pods (2x2 Grid)
            fun drawPod(
                left: Float,
                top: Float,
                right: Float,
                bottom: Float,
                code: String,
                value: String,
                sub: String,
                accent: Int
            ) {
                val rect = RectF(left, top, right, bottom)
                val pBg = Paint(Paint.ANTI_ALIAS_FLAG).apply {
                    color = Color.argb(165, 8, 20, 38)
                }
                val pStroke = Paint(Paint.ANTI_ALIAS_FLAG).apply {
                    style = Paint.Style.STROKE
                    strokeWidth = 1.6f
                    color = Color.argb(130, Color.red(accent), Color.green(accent), Color.blue(accent))
                }
                canvas.drawRoundRect(rect, 10f, 10f, pBg)
                canvas.drawRoundRect(rect, 10f, 10f, pStroke)

                val codeP = Paint(Paint.ANTI_ALIAS_FLAG).apply {
                    color = accent
                    textSize = 12.5f
                    typeface = Typeface.create(Typeface.MONOSPACE, Typeface.BOLD)
                }
                canvas.drawText(code, left + 14f, top + 22f, codeP)

                val valP = Paint(Paint.ANTI_ALIAS_FLAG).apply {
                    color = Color.WHITE
                    textSize = 25f
                    typeface = Typeface.create(Typeface.MONOSPACE, Typeface.BOLD)
                }
                canvas.drawText(value, left + 14f, top + 56f, valP)

                val subP = Paint(Paint.ANTI_ALIAS_FLAG).apply {
                    color = Color.parseColor("#94A3B8")
                    textSize = 12.5f
                    typeface = Typeface.create(Typeface.MONOSPACE, Typeface.NORMAL)
                }
                canvas.drawText(sub, left + 14f, top + 78f, subP)
            }

            drawPod(
                418f, 60f, 688f, 150f,
                "PWR-01 // VÝKON",
                "${wattage} W",
                "ZDROJ: $chargeSource",
                if (isCharging) plasmaGreen else primaryCyan
            )
            drawPod(
                702f, 60f, 972f, 150f,
                "VLT-02 // NAPĚTÍ & TOK",
                "${voltageMv} mV",
                "PROUD: ${currentMa} mA (${String.format("%.2f", volts)} V)",
                primaryCyan
            )
            drawPod(
                418f, 162f, 688f, 252f,
                "THM-03 // TEPLOTA JÁDRA",
                "${String.format("%.1f", tempC)} °C",
                "TERMODYNAMIKA: ${String.format("%.1f", tempK)} K",
                if (tempC >= 39.0) starkGold else primaryCyan
            )
            drawPod(
                702f, 162f, 972f, 252f,
                "SYS-04 // MATICE RAM",
                "$ramPct %",
                "VYUŽITO: ${String.format("%.1f", usedRamGb)} / ${String.format("%.1f", totalRamGb)} GB",
                starkGold
            )

            // Live Harmonic Plasma Oscilloscope Strip (y=266..382)
            val oscRect = RectF(418f, 266f, 972f, 382f)
            val oscBg = Paint(Paint.ANTI_ALIAS_FLAG).apply {
                color = Color.argb(175, 4, 12, 24)
            }
            val oscBorder = Paint(Paint.ANTI_ALIAS_FLAG).apply {
                style = Paint.Style.STROKE
                strokeWidth = 1.4f
                color = Color.argb(110, 56, 189, 248)
            }
            canvas.drawRoundRect(oscRect, 10f, 10f, oscBg)
            canvas.drawRoundRect(oscRect, 10f, 10f, oscBorder)

            val oscLabel = Paint(Paint.ANTI_ALIAS_FLAG).apply {
                color = Color.parseColor("#7DD3FC")
                textSize = 12f
                typeface = Typeface.create(Typeface.MONOSPACE, Typeface.BOLD)
            }
            canvas.drawText("OSC-05 // HARMONICKÉ ZVLNĚNÍ PLAZMATU (50.0 Hz)", 432f, 286f, oscLabel)

            val wavePath1 = Path()
            val wavePath2 = Path()
            val wStart = 432f
            val wEnd = 958f
            val midY = 336f
            val steps = 80
            for (s in 0..steps) {
                val t = s.toFloat() / steps
                val x = wStart + (wEnd - wStart) * t
                val y1 = midY + sin(t * 14.0 + phaseRad) * 22.0 * cos(t * 3.5 - phaseRad * 0.5)
                val y2 = midY + cos(t * 10.0 - phaseRad * 1.2) * 14.0
                if (s == 0) {
                    wavePath1.moveTo(x, y1.toFloat())
                    wavePath2.moveTo(x, y2.toFloat())
                } else {
                    wavePath1.lineTo(x, y1.toFloat())
                    wavePath2.lineTo(x, y2.toFloat())
                }
            }
            val wavePaint1 = Paint(Paint.ANTI_ALIAS_FLAG).apply {
                style = Paint.Style.STROKE
                strokeWidth = 2.6f
                color = primaryCyan
            }
            val wavePaint2 = Paint(Paint.ANTI_ALIAS_FLAG).apply {
                style = Paint.Style.STROKE
                strokeWidth = 1.6f
                color = Color.argb(170, 245, 158, 11)
            }
            canvas.drawPath(wavePath2, wavePaint2)
            canvas.drawPath(wavePath1, wavePaint1)

            // -----------------------------------------------------------------
            // 4. Bottom Interactive Tactical Action Bar (y=404..498)
            // -----------------------------------------------------------------
            fun drawActionButton(
                left: Float,
                right: Float,
                title: String,
                subtitle: String,
                accentColor: Int,
                activeFill: Boolean = false
            ) {
                val rect = RectF(left, 404f, right, 496f)
                val bg = Paint(Paint.ANTI_ALIAS_FLAG).apply {
                    color = if (activeFill) {
                        Color.argb(95, Color.red(accentColor), Color.green(accentColor), Color.blue(accentColor))
                    } else {
                        Color.argb(190, 10, 25, 47)
                    }
                }
                val stroke = Paint(Paint.ANTI_ALIAS_FLAG).apply {
                    style = Paint.Style.STROKE
                    strokeWidth = if (activeFill) 2.6f else 1.8f
                    color = accentColor
                }
                canvas.drawRoundRect(rect, 12f, 12f, bg)
                canvas.drawRoundRect(rect, 12f, 12f, stroke)

                val tPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
                    color = Color.WHITE
                    textSize = 16.5f
                    typeface = Typeface.create(Typeface.MONOSPACE, Typeface.BOLD)
                    textAlign = Paint.Align.CENTER
                }
                val sPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
                    color = accentColor
                    textSize = 12f
                    typeface = Typeface.create(Typeface.MONOSPACE, Typeface.BOLD)
                    textAlign = Paint.Align.CENTER
                }
                canvas.drawText(title, rect.centerX(), rect.top + 42f, tPaint)
                canvas.drawText(subtitle, rect.centerX(), rect.top + 68f, sPaint)
            }

            drawActionButton(
                26f, 332f,
                "🎤 HLASOVÝ ROZKAZ",
                "OKAMŽITÝ POSLECH ČEŠTINY",
                primaryCyan
            )
            drawActionButton(
                346f, 652f,
                "🔊 HLÁŠENÍ STAVU",
                "ČESKÁ HLASOVÁ DIAGNOSTIKA",
                 coreBlue
            )
            drawActionButton(
                666f, 972f,
                if (torchOn) "⚡ PULZNÍ SVĚTLO: ZAP" else "⚡ PULZNÍ SVĚTLO: VYP",
                if (torchOn) "AKTIVNÍ VÝBOJ SVÍTILNY" else "PŘEPNOUT LED SVÍTILNU",
                if (torchOn) starkGold else primaryCyan,
                activeFill = torchOn
            )

            return bmp
        }

        private fun toggleHardwareTorch(context: Context): Boolean {
            val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            val nextState = !prefs.getBoolean(KEY_TORCH_ON, false)
            return try {
                val cm = context.getSystemService(Context.CAMERA_SERVICE) as? CameraManager
                val camId = cm?.cameraIdList?.firstOrNull { id ->
                    cm.getCameraCharacteristics(id).get(CameraCharacteristics.FLASH_INFO_AVAILABLE) == true
                }
                if (camId != null && Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                    cm.setTorchMode(camId, nextState)
                    prefs.edit().putBoolean(KEY_TORCH_ON, nextState).apply()
                    nextState
                } else {
                    false
                }
            } catch (_: Exception) {
                prefs.edit().putBoolean(KEY_TORCH_ON, false).apply()
                false
            }
        }
    }

    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray) {
        for (appWidgetId in appWidgetIds) {
            updateSingleWidget(context, appWidgetManager, appWidgetId)
        }
    }

    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)
        val action = intent.action ?: return
        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)

        when (action) {
            ACTION_REFRESH_TILT -> {
                val nextTilt = (prefs.getInt(KEY_TILT_INDEX, 0) + 1) % TILT_PRESETS.size
                val nextPhase = (prefs.getFloat(KEY_PHASE_DEG, 0f) + 37f) % 360f
                prefs.edit()
                    .putInt(KEY_TILT_INDEX, nextTilt)
                    .putFloat(KEY_PHASE_DEG, nextPhase)
                    .apply()
                updateAllWidgets(context)
            }
            ACTION_TOGGLE_TORCH -> {
                toggleHardwareTorch(context)
                updateAllWidgets(context)
            }
            ACTION_OPEN_REACTOR_HUD -> {
                MainActivity.wakeScreenAndLaunchAction(context, "open_charging_hud")
                updateAllWidgets(context)
            }
            ACTION_VOICE_COMMAND -> {
                MainActivity.wakeScreenAndLaunchAction(context, "widget_voice_command")
                updateAllWidgets(context)
            }
            ACTION_SPEAK_TELEMETRY -> {
                val nextPhase = (prefs.getFloat(KEY_PHASE_DEG, 0f) + 29f) % 360f
                prefs.edit().putFloat(KEY_PHASE_DEG, nextPhase).apply()
                MainActivity.wakeScreenAndLaunchAction(context, "widget_speak_telemetry")
                updateAllWidgets(context)
            }
            Intent.ACTION_POWER_CONNECTED -> {
                MainActivity.wakeScreenAndLaunchAction(context, "power_connected_lockscreen")
                updateAllWidgets(context)
            }
            Intent.ACTION_POWER_DISCONNECTED -> {
                updateAllWidgets(context)
            }
        }
    }
}
