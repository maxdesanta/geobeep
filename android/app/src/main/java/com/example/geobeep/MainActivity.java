package com.example.geobeep;

import android.app.NotificationManager;
import android.content.Context;
import android.os.Build;

import androidx.annotation.NonNull;

import io.flutter.embedding.android.FlutterActivity;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.plugin.common.MethodChannel;

public class MainActivity extends FlutterActivity {
    private static final String CHANNEL = "com.example.geobeep/notification";

    @Override
    public void configureFlutterEngine(@NonNull FlutterEngine flutterEngine) {
        super.configureFlutterEngine(flutterEngine);

        new MethodChannel(flutterEngine.getDartExecutor().getBinaryMessenger(), CHANNEL)
                .setMethodCallHandler(
                        (call, result) -> {
                            if (call.method.equals("setupNotificationImportance")) {
                                // Set notification importance untuk Android 8.0+
                                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                                    NotificationManager notificationManager = (NotificationManager) getSystemService(
                                            Context.NOTIFICATION_SERVICE);

                                    // Mencegah notifikasi dihilangkan
                                    android.app.NotificationChannel channel = notificationManager
                                            .getNotificationChannel("geobeep_foreground");

                                    if (channel != null) {
                                        // Kode ini membuat notifikasi tidak dapat dihilangkan
                                        // dengan menggunakan fitur importance yang lebih tinggi
                                        channel.setImportance(NotificationManager.IMPORTANCE_HIGH);
                                        notificationManager.createNotificationChannel(channel);
                                        result.success(true);
                                    } else {
                                        result.success(false);
                                    }
                                } else {
                                    result.success(false);
                                }
                            } else {
                                result.notImplemented();
                            }
                        });
    }
}
