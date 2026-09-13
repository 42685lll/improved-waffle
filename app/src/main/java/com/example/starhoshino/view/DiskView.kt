package com.example.starhoshino.view

import android.content.Context
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.Paint
import android.util.AttributeSet
import android.view.MotionEvent
import android.view.View
import kotlin.math.cos
import kotlin.math.sin

class DiskView @JvmOverloads constructor(
    context: Context, attrs: AttributeSet? = null, defStyleAttr: Int = 0
) : View(context, attrs, defStyleAttr) {

    private val paint = Paint(Paint.ANTI_ALIAS_FLAG)
    private val wavePaint = Paint(Paint.ANTI_ALIAS_FLAG)
    private var amplitude = FloatArray(21) { 0.3f }
    private var isSpeaking = false
    private var animationPhase = 0f

    var onDoubleTap: (() -> Unit)? = null
    private var lastTapTime = 0L

    init {
        paint.color = Color.parseColor("#4A90D9")
        paint.style = Paint.Style.STROKE
        paint.strokeWidth = 4f

        wavePaint.color = Color.parseColor("#7EC8E3")
        wavePaint.style = Paint.Style.FILL
    }

    fun setWaveAmplitude(amps: FloatArray) {
        amplitude = amps.copyOf(21) { 0.3f }
        invalidate()
    }

    fun setSilentWave() {
        amplitude = FloatArray(21) { 0.15f }
        isSpeaking = false
        invalidate()
    }

    fun startSpeakingAnimation() {
        isSpeaking = true
        invalidate()
    }

    fun stopSpeakingAnimation() {
        isSpeaking = false
        setSilentWave()
    }

    override fun onDraw(canvas: Canvas) {
        super.onDraw(canvas)

        val cx = width / 2f
        val cy = height / 2f
        val baseRadius = minOf(width, height) * 0.25f

        // 外圈圆盘
        paint.color = Color.parseColor("#4A90D9")
        canvas.drawCircle(cx, cy, baseRadius, paint)

        // 内圈
        paint.color = Color.parseColor("#2E5A8C")
        canvas.drawCircle(cx, cy, baseRadius * 0.7f, paint)

        // 波形条
        if (isSpeaking || amplitude.any { it > 0.2f }) {
            animationPhase += 0.1f
            val bars = amplitude.size
            val barWidth = (baseRadius * 1.8f) / bars
            for (i in 0 until bars) {
                val angle = (i.toFloat() / bars) * Math.PI.toFloat() * 2f + animationPhase
                val amp = if (isSpeaking) {
                    0.3f + 0.4f * sin(animationPhase * 2 + i * 0.5f)
                } else {
                    amplitude[i]
                }
                val length = baseRadius * (0.9f + amp * 0.6f)
                val x1 = cx + cos(angle) * baseRadius * 0.8f
                val y1 = cy + sin(angle) * baseRadius * 0.8f
                val x2 = cx + cos(angle) * length
                val y2 = cy + sin(angle) * length

                wavePaint.alpha = (100 + 155 * amp).toInt().coerceIn(0, 255)
                canvas.drawLine(x1, y1, x2, y2, wavePaint)
            }
        }

        // 中心文字
        paint.color = Color.WHITE
        paint.textSize = baseRadius * 0.3f
        paint.textAlign = Paint.Align.CENTER
        canvas.drawText("星野", cx, cy + paint.textSize * 0.35f, paint)
    }

    override fun onTouchEvent(event: MotionEvent): Boolean {
        if (event.action == MotionEvent.ACTION_DOWN) {
            val now = System.currentTimeMillis()
            if (now - lastTapTime < 300) {
                onDoubleTap?.invoke()
                lastTapTime = 0
                return true
            }
            lastTapTime = now
        }
        return super.onTouchEvent(event)
    }
}
