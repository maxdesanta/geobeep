package com.example.geobeep

import android.Manifest
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.location.Location
import android.os.Build
import android.os.IBinder
import androidx.core.app.ActivityCompat
import androidx.core.app.NotificationCompat
import com.google.android.gms.location.*

class GeoBeepForegroundService : Service() {
    private lateinit var fusedLocationClient: FusedLocationProviderClient
    private lateinit var locationCallback: LocationCallback
    private var alarmTriggered = false

    // Contoh: Lokasi stasiun target (misal Stasiun Juanda)
    private val targetLat = -6.1666
    private val targetLng = 106.8300
    private val alarmRadius = 200 // meter

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        val channelId = "geobeep_foreground"
        val channelName = "GeoBeep Background Service"
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val chan =
                    NotificationChannel(channelId, channelName, NotificationManager.IMPORTANCE_LOW)
            val manager = getSystemService(NotificationManager::class.java)
            manager.createNotificationChannel(chan)
        }
        val notificationIntent = Intent(this, MainActivity::class.java)
        val pendingIntent =
                PendingIntent.getActivity(this, 0, notificationIntent, PendingIntent.FLAG_IMMUTABLE)
        val notification =
                NotificationCompat.Builder(this, channelId)
                        .setContentTitle("GeoBeep berjalan di background")
                        .setContentText("Alarm & pelacakan lokasi tetap aktif.")
                        .setSmallIcon(android.R.drawable.ic_lock_idle_alarm)
                        .setContentIntent(pendingIntent)
                        .setOngoing(true)
                        .build()
        startForeground(1002, notification)

        fusedLocationClient = LocationServices.getFusedLocationProviderClient(this)
        locationCallback =
                object : LocationCallback() {
                    override fun onLocationResult(result: LocationResult) {
                        for (location in result.locations) {
                            checkAlarm(location)
                        }
                    }
                }
        startLocationUpdates()
        return START_STICKY
    }

    private fun startLocationUpdates() {
        val request =
                LocationRequest.create().apply {
                    interval = 10000 // 10 detik
                    fastestInterval = 5000
                    priority = LocationRequest.PRIORITY_HIGH_ACCURACY
                }
        if (ActivityCompat.checkSelfPermission(this, Manifest.permission.ACCESS_FINE_LOCATION) !=
                        PackageManager.PERMISSION_GRANTED &&
                        ActivityCompat.checkSelfPermission(
                                this,
                                Manifest.permission.ACCESS_COARSE_LOCATION
                        ) != PackageManager.PERMISSION_GRANTED
        ) {
            // Permission belum diberikan
            return
        }
        fusedLocationClient.requestLocationUpdates(request, locationCallback, null)
    }

    private fun checkAlarm(location: Location) {
        val distance = FloatArray(1)
        Location.distanceBetween(
                location.latitude,
                location.longitude,
                targetLat,
                targetLng,
                distance
        )
        if (distance[0] <= alarmRadius && !alarmTriggered) {
            alarmTriggered = true
            showAlarmNotification()
        } else if (distance[0] > alarmRadius) {
            alarmTriggered = false
        }
    }

    private fun showAlarmNotification() {
        val channelId = "geobeep_alarm"
        val channelName = "GeoBeep Alarm"
        val notificationManager =
                getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel =
                    NotificationChannel(channelId, channelName, NotificationManager.IMPORTANCE_HIGH)
            notificationManager.createNotificationChannel(channel)
        }
        val notification =
                NotificationCompat.Builder(this, channelId)
                        .setContentTitle("ALARM GeoBeep!")
                        .setContentText("Anda sudah dekat dengan stasiun tujuan!")
                        .setSmallIcon(android.R.drawable.ic_lock_idle_alarm)
                        .setPriority(NotificationCompat.PRIORITY_HIGH)
                        .setAutoCancel(true)
                        .build()
        notificationManager.notify(2001, notification)
    }

    override fun onDestroy() {
        super.onDestroy()
        fusedLocationClient.removeLocationUpdates(locationCallback)
    }

    override fun onBind(intent: Intent?): IBinder? = null
}
