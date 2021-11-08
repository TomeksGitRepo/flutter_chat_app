 package com.example.chat_app;

import android.app.Notification;
import android.app.NotificationChannel;
import android.app.NotificationManager;
import androidx.core.app.NotificationCompat;

import android.app.PendingIntent;
import android.app.RemoteInput;
import android.content.Context;
import android.content.Intent;
import android.graphics.BitmapFactory;
import android.media.RingtoneManager;
import android.net.Uri;
import android.os.Build;
import android.util.Log;
import androidx.core.app.NotificationCompat.Action;

import com.google.firebase.messaging.*;
import com.google.firebase.messaging.FirebaseMessagingService;

import java.util.HashMap;
import java.util.Map;
import java.util.Random;
import java.util.Timer;
import java.util.TimerTask;
import java.util.concurrent.atomic.AtomicInteger;

import org.json.*;



public class MyFirebaseMessagingService extends FirebaseMessagingService {

    
    @Override
    public void onMessageReceived(RemoteMessage remoteMessage) {
        Log.e("FIREBASE", "Message remoteMessage.getData() : " + remoteMessage.getData());
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            CharSequence name = "basic_channel";
            String description = "channel_description";
            int importance = NotificationManager.IMPORTANCE_HIGH;
            NotificationChannel channel = new NotificationChannel("basic_channel", name, importance );
            channel.setDescription(description);
            // Register the channel with the system; you can't change the importance
            // or other notification behaviors after this
            NotificationManager notificationManager = getSystemService(NotificationManager.class);
            notificationManager.createNotificationChannel(channel);
        }
        if (remoteMessage.getData() != null) {
            Map<String, String> MessageData = notificationDataToMap(remoteMessage);
            //TODO should remove when content always present
            if (MessageData == null) {
                return;
            }
            Log.e("FIREBASE", "MessageData.get(\"title\"): " + MessageData.get("title") );
           // Log.e("FIREBASE", "Message Notification Body: " + remoteMessage.getNotification().getBody());
//             Log.e("FIREBASE", "properties.get(title): " + properties.get("title") );
//             Log.e("FIREBASE", "properties.get(body) " + properties.get("body") );
            sendNotification(MessageData.get("title"), MessageData.get("body"), MessageData.get("channelKey"), MessageData.get("chatID"), MessageData.get("allUsersInvoledTokens"), MessageData.get("androidUsersInvolvedTokens"), MessageData.get("iosUsersInvolvedTokens"), MessageData.get("id"));
        }
    }

    private void sendNotification(String title, String content, String channelId, String chatID, String allUsersInvolvedTokens, String androidUsersInvolvedTokens, String iosUsersInvolvedTokens, String messageID) {
        Random rn = new Random();

        Intent intentAction = new Intent(this, ActionReceiver.class);
        intentAction.putExtra("action", "readed");
        Intent intentAction2 = new Intent(this, ActionReceiver.class);
        intentAction2.putExtra("action", "secend");
        intentAction2.putExtra("chatID", chatID );
        intentAction2.putExtra("allUsersInvolvedTokens", allUsersInvolvedTokens );
        intentAction2.putExtra("androidUsersInvolvedTokens", androidUsersInvolvedTokens );
        intentAction2.putExtra("iosUsersInvolvedTokens", iosUsersInvolvedTokens );
        intentAction2.putExtra("messageID", messageID);
        //PendingIntent needs to have unique requestCode becasue there are the same intent if only have some extra String's
        PendingIntent pIntentlogin = PendingIntent.getBroadcast(this,rn.nextInt(),intentAction, PendingIntent.FLAG_UPDATE_CURRENT);
        PendingIntent pIntentlogin2 = PendingIntent.getBroadcast(this,rn.nextInt(),intentAction2,PendingIntent.FLAG_UPDATE_CURRENT);
        NotificationCompat.Action action = new NotificationCompat.Action.Builder(R.drawable.app_icon, "Przeczytana", pIntentlogin).build();
        androidx.core.app.RemoteInput remoteInput = new androidx.core.app.RemoteInput.Builder(ActionReceiver.KEY_TEXT_REPLY).setLabel("Odpowiedz").build();

        NotificationCompat.Action action2 = new NotificationCompat.Action.Builder(R.drawable.app_icon, "Odpowiedz", pIntentlogin2).addRemoteInput(remoteInput).build();



        NotificationCompat.Builder builder = new NotificationCompat.Builder(getApplicationContext(), channelId)
                .setDefaults(Notification.DEFAULT_ALL)
                .setSmallIcon(R.drawable.app_icon)
                .setContentTitle(title)
                .setContentText(content)
                .setAutoCancel(true)
 //               .setAllowSystemGeneratedContextualActions(true)
//                .setGroup("my_group")
//                .setGroupSummary(true)
                .setVibrate(new long[] { 1000, 1000, 1000, 1000, 1000 })
                .setPriority(NotificationCompat.PRIORITY_HIGH)
                .addAction(action)
                .addAction(action2)
                .setContentIntent(PendingIntent.getActivity(this, 0, new Intent(getApplicationContext(), MainActivity.class), 0)); //onClickAcivity
                //With set style notificaions not getting sack up correctly in tray
                //.setStyle(new NotificationCompat.BigTextStyle().setBigContentTitle(content));

        NotificationManager notificationManager =
                (NotificationManager) getSystemService(Context.NOTIFICATION_SERVICE);
        notificationManager.notify(Integer.parseInt(messageID), builder.build());

        //notificationManager.notify(Integer.parseInt(messageID), builder.build());
        Log.e("sendNotification", "After notification builder");
    }

    private Map<String, String> notificationDataToMap(RemoteMessage remoteMessage) {
        String dataFromFirbase =  remoteMessage.getData().get("content");
        //TODO should remove when content always present
        if (dataFromFirbase == null) {
            return null;
        }
        Map<String, String> dataMap = new HashMap<>();

        String chatID;
        String privacy;
        String title;
        String body;
        String androidUsersInvolvedTokens;
        String iosUsersInvolvedTokens;
        String channelKey;
        String allUsersInvoledTokens;
        String id;
        try {
            dataFromFirbase = dataFromFirbase.replace("{content=", "");
            //dataFromFirbase = dataFromFirbase.replace("}", "");

            JSONObject object = new JSONObject(dataFromFirbase);
            chatID = object.getString("chatID");
            privacy = object.getString("privacy");
            title = object.getString("title");
            body = object.getString("body");
            id = object.getString("id");
            androidUsersInvolvedTokens = object.getString("androidUsersInvolvedTokens");
            iosUsersInvolvedTokens = object.getString("iosUsersInvolvedTokens");
            channelKey = object.getString("channelKey");
            allUsersInvoledTokens = object.getString("allUsersInvoledTokens");

            dataMap.put("chatID", chatID);
            dataMap.put("privacy", privacy);
            dataMap.put("title", title);
            dataMap.put("body", body);
            dataMap.put("id", id);
            dataMap.put("androidUsersInvolvedTokens", androidUsersInvolvedTokens);
            dataMap.put("iosUsersInvolvedTokens", iosUsersInvolvedTokens);
            dataMap.put("channelKey", channelKey);
            dataMap.put("allUsersInvoledTokens", allUsersInvoledTokens);

            return dataMap;
        } catch (org.json.JSONException e) {
            Log.e("JSONObject", "error while parsing to json " + e.getMessage() );
            return null;
        }

        //Using json parse object insted of home made parser
//        dataFromFirbase = dataFromFirbase.replace("{", "");
//        dataFromFirbase = dataFromFirbase.replace("}", "");
//        String[] splitedValues = dataFromFirbase.split("\",\"");
        //Add removed " in after split()
//        for (int i = 0; i <= splitedValues.length - 1; i++) {
//            if (!splitedValues[i].startsWith("\"")) {
//                splitedValues[i] =  "\"" + splitedValues[i];
//            }
//            if (!splitedValues[i].endsWith("\"")) {
//                splitedValues[i] = splitedValues[i] + "\"";
//            }
//        }

//        for( int i = 0; i <= splitedValues.length - 1; i++ )
//        {
//            String[] splitedValue = splitedValues[i].split(":", 2);
//            splitedValue[0] = splitedValue[0].replace("\"", "");
//            splitedValue[1] = splitedValue[1].replace("\"", "");
//            dataMap.put(splitedValue[0], splitedValue[1]);
//            Log.e("FIREBASE", "splitedValue[0]" + splitedValue[0]);
//            Log.e("FIREBASE", "splitedValue[1]" + splitedValue[1]);
//        }

    }
}