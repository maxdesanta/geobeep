package com.example.geobeep

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.Bundle
import androidx.core.app.NotificationCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        showForegroundNotification()
    }

    private fun showForegroundNotification() {
        val channelId = "geobeep_foreground"
        val channelName = "GeoBeep Background Service"
        val notificationId = 1001

        val notificationManager =
                getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel =
                    NotificationChannel(channelId, channelName, NotificationManager.IMPORTANCE_LOW)
            notificationManager.createNotificationChannel(channel)
        }

        val intent = Intent(this, MainActivity::class.java)
        val pendingIntent = PendingIntent.getActivity(this, 0, intent, PendingIntent.FLAG_IMMUTABLE)

        val notification =
                NotificationCompat.Builder(this, channelId)
                        .setContentTitle("GeoBeep berjalan di latar belakang")
                        .setContentText(
                                "Alarm dan pelacakan lokasi tetap aktif meski aplikasi ditutup atau layar mati."
                        )
                        .setSmallIcon(android.R.drawable.ic_lock_idle_alarm)
                        .setContentIntent(pendingIntent)
                        .setOngoing(true)
                        .build()

        notificationManager.notify(notificationId, notification)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "com.example.geobeep/background")
                .setMethodCallHandler { call, result ->
                    if (call.method == "startService") {
                        val intent = Intent(this, GeoBeepForegroundService::class.java)
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                            startForegroundService(intent)
                        } else {
                            startService(intent)
                        }
                        result.success(true)
                    } else {
                        result.notImplemented()
                    }
                }
    }
}
