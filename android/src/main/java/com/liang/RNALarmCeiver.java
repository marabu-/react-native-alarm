package com.liang;

import android.app.Notification;
import android.app.NotificationManager;
import android.app.PendingIntent;
import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.media.RingtoneManager;
import android.net.Uri;

import static android.content.Context.NOTIFICATION_SERVICE;

/**
 * Created by GBLiang on 9/22/2017.
 */

public class RNALarmCeiver extends BroadcastReceiver {

    @Override
    public void onReceive(Context context, Intent intent) {

        try {
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
            
            notificationBuilder.setDefaults(Notification.DEFAULT_ALL);
            notificationBuilder.setFullScreenIntent(pi, true);
            notificationBuilder.setDeleteIntent(createOnDismissedIntent(context));
            notificationBuilder.setAutoCancel(true);
            notificationBuilder.setSound(ringtone);
            Notification notification = notificationBuilder.build();
            NotificationManager notificationManager = (NotificationManager) context.getSystemService(NOTIFICATION_SERVICE);
            notificationManager.notify(0, notification);

        } catch (Exception e) {
            e.printStackTrace();
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
