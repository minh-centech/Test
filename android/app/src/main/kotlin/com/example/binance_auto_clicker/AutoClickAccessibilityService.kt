package com.example.binance_auto_clicker

import android.accessibilityservice.AccessibilityService
import android.accessibilityservice.GestureDescription
import android.content.Intent
import android.graphics.Path
import android.os.Handler
import android.os.Looper
import android.util.Log
import android.view.accessibility.AccessibilityEvent
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

class AutoClickAccessibilityService : AccessibilityService() {
    
    companion object {
        private const val TAG = "AutoClickService"
        private var instance: AutoClickAccessibilityService? = null
        
        fun getInstance(): AutoClickAccessibilityService? = instance
        
        fun isServiceEnabled(): Boolean = instance != null
    }

    private val handler = Handler(Looper.getMainLooper())
    private var isExecuting = false
    private var executionCount = 0
    
    override fun onCreate() {
        super.onCreate()
        instance = this
        Log.d(TAG, "Accessibility service created")
    }

    override fun onDestroy() {
        super.onDestroy()
        instance = null
        Log.d(TAG, "Accessibility service destroyed")
    }

    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        // We don't need to handle accessibility events for clicking
        // This service is purely for gesture dispatching
    }

    override fun onInterrupt() {
        Log.d(TAG, "Accessibility service interrupted")
        stopExecution()
    }

    override fun onServiceConnected() {
        super.onServiceConnected()
        Log.d(TAG, "Accessibility service connected")
    }

    /**
     * Execute rapid clicks at specified coordinates
     */
    fun executeRapidClicks(x: Float, y: Float, count: Int, intervalMs: Long, callback: ClickCallback?) {
        if (isExecuting) {
            Log.w(TAG, "Already executing clicks, ignoring request")
            return
        }

        Log.d(TAG, "Starting rapid clicks: count=$count, interval=${intervalMs}ms at ($x, $y)")
        
        isExecuting = true
        executionCount = 0
        
        executeClickSequence(x, y, count, intervalMs, callback)
    }

    /**
     * Execute a sequence of clicks with precise timing
     */
    private fun executeClickSequence(x: Float, y: Float, count: Int, intervalMs: Long, callback: ClickCallback?) {
        if (!isExecuting || executionCount >= count) {
            isExecuting = false
            callback?.onSequenceCompleted(executionCount)
            Log.d(TAG, "Click sequence completed: $executionCount clicks executed")
            return
        }

        val startTime = System.currentTimeMillis()
        
        performClick(x, y) { success ->
            if (success) {
                executionCount++
                callback?.onClickExecuted(executionCount, x, y)
                
                val elapsed = System.currentTimeMillis() - startTime
                val delay = maxOf(0, intervalMs - elapsed)
                
                handler.postDelayed({
                    executeClickSequence(x, y, count, intervalMs, callback)
                }, delay)
            } else {
                Log.e(TAG, "Click failed at ($x, $y)")
                callback?.onClickError("Click execution failed")
                isExecuting = false
            }
        }
    }

    /**
     * Perform a single click at specified coordinates
     */
    private fun performClick(x: Float, y: Float, callback: (Boolean) -> Unit) {
        val path = Path().apply {
            moveTo(x, y)
        }

        val gestureBuilder = GestureDescription.Builder()
        val strokeDescription = GestureDescription.StrokeDescription(path, 0, 50) // 50ms tap duration
        gestureBuilder.addStroke(strokeDescription)

        val gesture = gestureBuilder.build()
        
        val result = dispatchGesture(gesture, object : GestureResultCallback() {
            override fun onCompleted(gestureDescription: GestureDescription?) {
                super.onCompleted(gestureDescription)
                callback(true)
            }

            override fun onCancelled(gestureDescription: GestureDescription?) {
                super.onCancelled(gestureDescription)
                Log.w(TAG, "Gesture cancelled")
                callback(false)
            }
        }, null)

        if (!result) {
            Log.e(TAG, "Failed to dispatch gesture")
            callback(false)
        }
    }

    /**
     * Simulate a single click for testing
     */
    fun simulateClick(x: Float, y: Float, callback: ClickCallback?) {
        Log.d(TAG, "Simulating click at ($x, $y)")
        
        performClick(x, y) { success ->
            if (success) {
                callback?.onClickExecuted(1, x, y)
            } else {
                callback?.onClickError("Click simulation failed")
            }
        }
    }

    /**
     * Stop current click execution
     */
    fun stopExecution() {
        Log.d(TAG, "Stopping click execution")
        isExecuting = false
        handler.removeCallbacksAndMessages(null)
    }

    /**
     * Emergency stop - immediately halt all operations
     */
    fun emergencyStop() {
        Log.w(TAG, "EMERGENCY STOP activated")
        stopExecution()
        // Could also disable the service here if needed
    }

    /**
     * Check if service is available and ready
     */
    fun isReady(): Boolean {
        return serviceInfo != null && isExecuting.not()
    }

    /**
     * Get current execution statistics
     */
    fun getExecutionStats(): Map<String, Any> {
        return mapOf(
            "isExecuting" to isExecuting,
            "executionCount" to executionCount,
            "isReady" to isReady()
        )
    }

    interface ClickCallback {
        fun onClickExecuted(count: Int, x: Float, y: Float)
        fun onSequenceCompleted(totalClicks: Int)
        fun onClickError(error: String)
    }
}