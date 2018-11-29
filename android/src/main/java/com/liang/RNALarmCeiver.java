package com.liang;

import android.app.Notification;
import android.app.NotificationManager;
import android.app.PendingIntent;
import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.media.AudioAttributes;
import android.media.AudioManager;
import android.media.MediaPlayer;
import android.media.RingtoneManager;
import android.net.Uri;
import android.os.Build;
import android.os.CountDownTimer;

import java.io.IOException;

import static android.content.Context.NOTIFICATION_SERVICE;

/**
 * Created by GBLiang on 9/22/2017.
 */

public class RNALarmCeiver extends BroadcastReceiver {

    static MediaPlayer player = new MediaPlayer();


    @Override
    public void onReceive(Context context, Intent intent) {

        if (intent.getExtras().getBoolean("stopNotification")) {
            if (player.isPlaying()) {
                player.stop();
                player.reset();
            }
        } else {

            String title = intent.getStringExtra(RNAlarmConstants.REACT_NATIVE_ALARM_TITLE);
            Uri ringtone = RingtoneManager.getDefaultUri(RingtoneManager.TYPE_ALARM);
            if (ringtone == null) {
                // alert is null, using backup
                ringtone = RingtoneManager.getDefaultUri(RingtoneManager.TYPE_NOTIFICATION);

                // I can't see this ever being null (as always have a default notification)
                // but just incase
                if (ringtone == null) {
                    // alert backup is null, using 2nd backup
                    ringtone = RingtoneManager.getDefaultUri(RingtoneManager.TYPE_RINGTONE);
                }
            }

            PendingIntent pi = PendingIntent.getActivity(context, 100, intent, PendingIntent.FLAG_CANCEL_CURRENT);

            Notification.Builder notificationBuilder = new Notification.Builder(context)
                    .setSmallIcon(android.R.drawable.sym_def_app_icon)
                    .setVibrate(new long[]{0, 6000})
                    .setContentTitle(title)
                    .setContentText("");


            Notification notification = notificationBuilder.build();
            notificationBuilder.setDefaults(Notification.DEFAULT_ALL);
            notificationBuilder.setFullScreenIntent(pi, true);
            notificationBuilder.setDeleteIntent(createOnDismissedIntent(context));
            notificationBuilder.setAutoCancel(true);
            NotificationManager notificationManager = (NotificationManager) context.getSystemService(NOTIFICATION_SERVICE);
            notificationManager.notify(0, notification);


            try {
                player.setDataSource(context, ringtone);
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
                    AudioAttributes.Builder builder = new AudioAttributes.Builder();
                    AudioAttributes attributes = builder
                            .setUsage(AudioAttributes.USAGE_ALARM)
                            .setContentType(AudioAttributes.CONTENT_TYPE_MUSIC)
                            .build();
                    player.setAudioAttributes(attributes);
                } else {
                    player.setAudioStreamType(AudioManager.STREAM_ALARM);
                }
                player.setLooping(true);
                player.prepareAsync();
                player.setOnPreparedListener(new MediaPlayer.OnPreparedListener() {
                    @Override
                    public void onPrepared(MediaPlayer mp) {
                        player.start();
                        new CountDownTimer(50000, 10000) {
                            public void onTick(long millisUntilFinished) {

                            }

                            public void onFinish() {
                                if (player.isPlaying()) {
                                    player.stop();
                                    player.reset();
                                }
                            }
                        }.start();
                    }
                });

            } catch (IOException e) {
                e.printStackTrace();
            }
        }
    }

    private PendingIntent createOnDismissedIntent(Context context) {
        Intent intent = new Intent(RNAlarmConstants.REACT_NATIVE_ALARM);
        intent.putExtra("stopNotification", true);
        PendingIntent pendingIntent =
                PendingIntent.getBroadcast(context, 1, intent, 0);
        return pendingIntent;
    }

}
