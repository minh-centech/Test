package com.example.binance_auto_clicker

import android.content.Context
import android.content.Intent
import android.provider.Settings
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.util.Log

class MainActivity: FlutterActivity() {
    private val CHANNEL = "binance_auto_clicker/clicks"
    private val TAG = "MainActivity"

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "isAvailable" -> {
                    result.success(AutoClickAccessibilityService.isServiceEnabled())
                }
                
                "executeRapidClicks" -> {
                    val x = call.argument<Double>("x")?.toFloat() ?: 0f
                    val y = call.argument<Double>("y")?.toFloat() ?: 0f
                    val count = call.argument<Int>("count") ?: 1
                    val intervalMs = call.argument<Int>("intervalMs")?.toLong() ?: 10L

                    executeRapidClicks(x, y, count, intervalMs, result)
                }
                
                "simulateClick" -> {
                    val x = call.argument<Double>("x")?.toFloat() ?: 0f
                    val y = call.argument<Double>("y")?.toFloat() ?: 0f

                    simulateClick(x, y, result)
                }
                
                "stopExecution" -> {
                    stopExecution(result)
                }
                
                "emergencyStop" -> {
                    emergencyStop(result)
                }
                
                "getExecutionStats" -> {
                    getExecutionStats(result)
                }
                
                "openAccessibilitySettings" -> {
                    openAccessibilitySettings(result)
                }
                
                "startTimerService" -> {
                    val targetTime = call.argument<Long>("targetTime") ?: 0L
                    val description = call.argument<String>("description") ?: "Countdown Active"
                    
                    startTimerService(targetTime, description, result)
                }
                
                "stopTimerService" -> {
                    stopTimerService(result)
                }
                
                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    private fun executeRapidClicks(x: Float, y: Float, count: Int, intervalMs: Long, result: MethodChannel.Result) {
        val service = AutoClickAccessibilityService.getInstance()
        
        if (service == null) {
            result.error("SERVICE_NOT_AVAILABLE", "Accessibility service is not running", null)
            return
        }

        if (!service.isReady()) {
            result.error("SERVICE_BUSY", "Service is busy or not ready", null)
            return
        }

        try {
            service.executeRapidClicks(x, y, count, intervalMs, object : AutoClickAccessibilityService.ClickCallback {
                override fun onClickExecuted(count: Int, x: Float, y: Float) {
                    // Notify Flutter about click execution
                    MethodChannel(flutterEngine?.dartExecutor?.binaryMessenger, CHANNEL)
                        .invokeMethod("clickExecuted", mapOf(
                            "count" to count,
                            "x" to x,
                            "y" to y
                        ))
                }

                override fun onSequenceCompleted(totalClicks: Int) {
                    // Notify Flutter about sequence completion
                    MethodChannel(flutterEngine?.dartExecutor?.binaryMessenger, CHANNEL)
                        .invokeMethod("sequenceCompleted", mapOf(
                            "totalClicks" to totalClicks
                        ))
                }

                override fun onClickError(error: String) {
                    // Notify Flutter about error
                    MethodChannel(flutterEngine?.dartExecutor?.binaryMessenger, CHANNEL)
                        .invokeMethod("clickError", error)
                }
            })

            result.success("Rapid clicks started")
            
        } catch (e: Exception) {
            Log.e(TAG, "Failed to execute rapid clicks", e)
            result.error("EXECUTION_FAILED", e.message, null)
        }
    }

    private fun simulateClick(x: Float, y: Float, result: MethodChannel.Result) {
        val service = AutoClickAccessibilityService.getInstance()
        
        if (service == null) {
            result.error("SERVICE_NOT_AVAILABLE", "Accessibility service is not running", null)
            return
        }

        try {
            service.simulateClick(x, y, object : AutoClickAccessibilityService.ClickCallback {
                override fun onClickExecuted(count: Int, x: Float, y: Float) {
                    // Click successful
                }

                override fun onSequenceCompleted(totalClicks: Int) {
                    // Not used for single clicks
                }

                override fun onClickError(error: String) {
                    Log.e(TAG, "Click simulation error: $error")
                }
            })

            result.success("Click simulated")
            
        } catch (e: Exception) {
            Log.e(TAG, "Failed to simulate click", e)
            result.error("SIMULATION_FAILED", e.message, null)
        }
    }

    private fun stopExecution(result: MethodChannel.Result) {
        val service = AutoClickAccessibilityService.getInstance()
        
        if (service != null) {
            service.stopExecution()
            result.success("Execution stopped")
        } else {
            result.error("SERVICE_NOT_AVAILABLE", "Accessibility service is not running", null)
        }
    }

    private fun emergencyStop(result: MethodChannel.Result) {
        val service = AutoClickAccessibilityService.getInstance()
        
        if (service != null) {
            service.emergencyStop()
            result.success("Emergency stop activated")
        } else {
            result.error("SERVICE_NOT_AVAILABLE", "Accessibility service is not running", null)
        }
        
        // Also stop timer service
        TimerForegroundService.stopService(this)
    }

    private fun getExecutionStats(result: MethodChannel.Result) {
        val service = AutoClickAccessibilityService.getInstance()
        
        if (service != null) {
            val stats = service.getExecutionStats()
            result.success(stats)
        } else {
            result.success(mapOf(
                "isExecuting" to false,
                "executionCount" to 0,
                "isReady" to false,
                "serviceAvailable" to false
            ))
        }
    }

    private fun openAccessibilitySettings(result: MethodChannel.Result) {
        try {
            val intent = Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS)
            intent.flags = Intent.FLAG_ACTIVITY_NEW_TASK
            startActivity(intent)
            result.success("Accessibility settings opened")
        } catch (e: Exception) {
            Log.e(TAG, "Failed to open accessibility settings", e)
            result.error("SETTINGS_FAILED", e.message, null)
        }
    }

    private fun startTimerService(targetTime: Long, description: String, result: MethodChannel.Result) {
        try {
            TimerForegroundService.startService(this, targetTime, description)
            result.success("Timer service started")
        } catch (e: Exception) {
            Log.e(TAG, "Failed to start timer service", e)
            result.error("SERVICE_START_FAILED", e.message, null)
        }
    }

    private fun stopTimerService(result: MethodChannel.Result) {
        try {
            TimerForegroundService.stopService(this)
            result.success("Timer service stopped")
        } catch (e: Exception) {
            Log.e(TAG, "Failed to stop timer service", e)
            result.error("SERVICE_STOP_FAILED", e.message, null)
        }
    }
}