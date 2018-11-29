
package com.liang;

import android.app.AlarmManager;
import android.app.PendingIntent;
import android.content.Context;
import android.content.Intent;
import android.content.SharedPreferences;
import android.content.res.AssetFileDescriptor;
import android.media.MediaPlayer;
import android.support.annotation.Nullable;
import android.util.Log;

import com.facebook.react.bridge.Callback;
import com.facebook.react.bridge.ReactApplicationContext;
import com.facebook.react.bridge.ReactContextBaseJavaModule;
import com.facebook.react.bridge.ReactMethod;
import com.facebook.react.uimanager.IllegalViewOperationException;

import java.text.SimpleDateFormat;
import java.util.Calendar;
import java.util.Date;

import static android.R.attr.type;

public class RNAlarmModule extends ReactContextBaseJavaModule {

    private final ReactApplicationContext reactContext;
    private SharedPreferences sharedPreferences;

    public RNAlarmModule(ReactApplicationContext reactContext) {
        super(reactContext);
        this.reactContext = reactContext;
        this.sharedPreferences = reactContext.getSharedPreferences(getName(), Context.MODE_PRIVATE);
    }

    @Override
    public String getName() {
        return "RNAlarm";
    }

    public Boolean getAlarmStatus(String triggerTime) {
        String value = sharedPreferences.getString(triggerTime, null);
        if (value == null)
            return null;
        else {
            return value == "error" ? false : true;
        }
    }

    public void setAlarm1(String triggerTime, String value) {
        SharedPreferences.Editor editor = sharedPreferences.edit();
        editor.putString(triggerTime, value);
        editor.commit();
    }

    @ReactMethod
    public void playTipSound(String fileName) {
        MediaPlayer mp = new MediaPlayer();
        try {
            if (mp.isPlaying()) {
                mp.stop();
            }
            if (mp != null) {
                mp.release();
                mp = new MediaPlayer();
            }
            AssetFileDescriptor descriptor = reactContext.getResources().getAssets().openFd(fileName + ".mp3");
            mp.setDataSource(descriptor.getFileDescriptor(), descriptor.getStartOffset(),
                    descriptor.getLength());
            mp.prepare();
            mp.setOnPreparedListener(new MediaPlayer.OnPreparedListener() {
                @Override
                public void onPrepared(MediaPlayer mp) {
                    mp.setLooping(false);
                    mp.start();
                }
            });
        } catch (Exception ex) {
            ex.printStackTrace();
        }

    }

    @ReactMethod
    public void initAlarm(@Nullable Callback successCallback) {
        if (successCallback != null) {
            successCallback.invoke(true);
        }
    }

    @ReactMethod
    public void clearAlarm() {
        SharedPreferences sharedPreferences = reactContext.getSharedPreferences(getName(), Context.MODE_PRIVATE);
        SharedPreferences.Editor editor = sharedPreferences.edit();
        editor.clear();
    }

    @ReactMethod
    public void setAlarm(String triggerTime, String title, @Nullable Callback successCallback, @Nullable Callback errorCallback) {
        try {
            Boolean alarmStatus = getAlarmStatus(triggerTime);

            if (alarmStatus != null) {
                if (alarmStatus) {
                    successCallback.invoke();
                    return;
                } else {
                    errorCallback.invoke();
                    return;
                }
            }

            AlarmManager alarmManager = (AlarmManager) reactContext.getSystemService(Context.ALARM_SERVICE);
            Intent intent = new Intent(RNAlarmConstants.REACT_NATIVE_ALARM);
            intent.putExtra(RNAlarmConstants.REACT_NATIVE_ALARM_TITLE, title);
            PendingIntent pendingIntent = PendingIntent.getBroadcast(reactContext, type, intent, PendingIntent.FLAG_UPDATE_CURRENT);

            SimpleDateFormat formatter = new SimpleDateFormat("dd/MM/yyyy hh:mm:ss");

            long triggerTimeMillis = Long.parseLong(triggerTime);
            Calendar originalTimeCal = Calendar.getInstance();
            originalTimeCal.setTimeInMillis(triggerTimeMillis);
            Log.w("originalTimeCal", formatter.format(originalTimeCal.getTime()));

            Calendar currentTimeCal = Calendar.getInstance();
            currentTimeCal.setTime(new Date());
            Log.w("currentTimeCal", formatter.format(currentTimeCal.getTime()));

            //compare alarm and currentTime
            if (triggerTimeMillis - currentTimeCal.getTimeInMillis() > 0) {
                Calendar calendar = Calendar.getInstance();
                calendar.setTimeInMillis(triggerTimeMillis);
                formatter.format(calendar.getTime());


                alarmManager.set(AlarmManager.RTC_WAKEUP, triggerTimeMillis, pendingIntent);
                setAlarm1(triggerTime, triggerTime);

                successCallback.invoke();
                return;

            } else {
                setAlarm1(triggerTime, "error");
                if (errorCallback != null) {
                    errorCallback.invoke("-1");
                    return;
                }
            }

        } catch (IllegalViewOperationException e) {
            if (errorCallback == null) {
                System.out.print(e.toString());
            } else {
                setAlarm1(triggerTime, "error");
                errorCallback.invoke(e.getMessage());
            }
        } catch (NumberFormatException e) {
            if (errorCallback == null) {
                System.out.print(e.toString());
            } else {
                setAlarm1(triggerTime, "error");
                errorCallback.invoke(e.getMessage());
            }
        }
    }
}