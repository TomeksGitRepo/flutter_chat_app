package com.example.chat_app;

import android.app.NotificationManager;
import android.app.RemoteInput;
import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.os.Bundle;
import android.util.Log;
import android.widget.Toast;

import com.google.android.gms.tasks.OnCompleteListener;
import com.google.android.gms.tasks.OnFailureListener;
import com.google.android.gms.tasks.OnSuccessListener;
import com.google.android.gms.tasks.Task;
import com.google.firebase.Timestamp;
import com.google.firebase.auth.FirebaseAuth;
import com.google.firebase.auth.FirebaseUser;
import com.google.firebase.firestore.DocumentReference;
import com.google.firebase.firestore.FirebaseFirestore;
import com.google.firebase.messaging.FirebaseMessaging;

import org.json.JSONArray;
import org.json.JSONObject;

import java.io.DataOutputStream;
import java.net.HttpURLConnection;
import java.net.URL;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.Map;

import androidx.annotation.NonNull;

public class ActionReceiver extends BroadcastReceiver {
    public static final String KEY_TEXT_REPLY = "key_text_reply";


    @Override
    public void onReceive(Context context, Intent intent) {

        //Toast.makeText(context,"recieved",Toast.LENGTH_SHORT).show();
        String action = intent.getStringExtra("action");
        String chatID = intent.getStringExtra("chatID");
        String allUsersInvolvedTokens = intent.getStringExtra("allUsersInvolvedTokens");
        String androidUsersInvolvedTokens = intent.getStringExtra("androidUsersInvolvedTokens");
        String iosUsersInvolvedTokens = intent.getStringExtra("iosUsersInvolvedTokens");
        String messageID = intent.getStringExtra("messageID");

        if (action.equals("readed")) {
            Log.e("NotificationAction", "Action button1 on messege clicked.");
        } else if (action.equals("secend")) {
            Bundle remoteInput = RemoteInput.getResultsFromIntent(intent);
            Log.e("NotificationAction", "Action button2 on messege clicked.");
            if (remoteInput == null) {
                return;
            }
            String reply = remoteInput.getString(KEY_TEXT_REPLY);
            Log.e("AR.onReceive reply", "reply: " + reply);
            Log.e("AR.onReceive chatID", "chatID: " + chatID);
            FirebaseAuth mAuth;
            mAuth = FirebaseAuth.getInstance();
            FirebaseUser firebaseUser = mAuth.getCurrentUser();
            Log.e("AR.onReceive reply", "firebaseUser:.getUid() " + firebaseUser.getUid());
            FirebaseFirestore db = FirebaseFirestore.getInstance();
            db.collection("users").document(firebaseUser.getUid())
                    .get()
                    .addOnCompleteListener(new OnCompleteListener<com.google.firebase.firestore.DocumentSnapshot>() {
                        @Override
                        public void onComplete(@NonNull Task<com.google.firebase.firestore.DocumentSnapshot> taskOuter) {
                            if (taskOuter.isSuccessful()) {
                                Log.e("task.isSuccessful", "task.getResult().getData().toString()" + taskOuter.getResult().getData().toString());
                                Log.e("allUsersInvoled", "allUsersInvoledTokens = " + allUsersInvolvedTokens);
                                FirebaseMessaging.getInstance().getToken()
                                        .addOnCompleteListener(new OnCompleteListener<String>() {
                                            @Override
                                            public void onComplete(@NonNull Task<String> task) {
                                                if (!task.isSuccessful()) {
                                                    Log.e("FailedGetFCMToken", "Fetching FCM registration token failed", task.getException());
                                                    return;
                                                }

                                                // Get new FCM registration token
                                                String userToken = task.getResult();
                                                Log.e("allUsersInvoledTokens", "This userToken is:" + userToken);

                                                String userName = (String) taskOuter.getResult().getData().get("username");
                                                //Send post to FCM
                                                sendPost(userName, reply, chatID, allUsersInvolvedTokens, androidUsersInvolvedTokens, iosUsersInvolvedTokens, userToken);
                                            }
                                        });


                                //Create and save message to database
                                Map<String, Object> message = new HashMap<>();
                                message.put("text", reply);
                                message.put("createdAt", Timestamp.now());
                                message.put("userName", taskOuter.getResult().getData().get("username"));
                                message.put("userUID", firebaseUser.getUid());

                                db.collection("chats").document(chatID).collection("messages").add(message).addOnSuccessListener(new OnSuccessListener<DocumentReference>() {
                                    @Override
                                    public void onSuccess(DocumentReference documentReference) {
                                        Log.d("AR.onReceive success", "DocumentSnapshot added with ID: " + documentReference.getId());
                                    }
                                })
                                        .addOnFailureListener(new OnFailureListener() {
                                            @Override
                                            public void onFailure(@NonNull Exception e) {
                                                Log.w("AR.onReceive failure", "Error adding document", e);
                                            }
                                        });

                            } else {
                                Log.e("Error in query", "Error getting documents.", taskOuter.getException());
                            }
                        }
                    });


        }


        NotificationManager notificationManager = (NotificationManager) context.getSystemService(Context.NOTIFICATION_SERVICE);
        notificationManager.cancel(Integer.parseInt(messageID));
        //This is used to close the notification tray

        // Intent it = new Intent(Intent.ACTION_CLOSE_SYSTEM_DIALOGS);
        // context.sendBroadcast(it);
    }

    public void sendPost(String title, String body, String chatID, String allUsersInvolvedTokens, String androidUsersInvolvedTokens, String iosUsersInvolvedTokens, String userToken) {
        Thread thread = new Thread(new Runnable() {
            @Override
            public void run() {
                //Android push notifications
                try {
                    boolean needSendToAndroid = false;
                    if (androidUsersInvolvedTokens.length() != 2) { //If its 2 its empty array
                        needSendToAndroid = true;
                    }
                    if (needSendToAndroid) {
                        URL url = new URL("https://fcm.googleapis.com/fcm/send");
                        HttpURLConnection conn = (HttpURLConnection) url.openConnection();
                        conn.setRequestMethod("POST");
                        conn.setRequestProperty("Content-Type", "application/json");
                        conn.setRequestProperty("Authorization", "key=xxxx");
                        //                    conn.setRequestProperty("Accept","application/json");
                        conn.setDoOutput(true);
                        conn.setDoInput(true);
                        String androidUsersInvolvedTokensContent = androidUsersInvolvedTokens.replace("[", "");
                        androidUsersInvolvedTokensContent = androidUsersInvolvedTokensContent.replace("]", "");
                        String[] usersToNotify = androidUsersInvolvedTokensContent.split(",");
                        for (int i = 0; i <= usersToNotify.length - 1; i++) {
                            if (usersToNotify[i].contains(userToken)) {
                                usersToNotify[i] = null;
                                break;
                            }
                        }

                        //Check if array is not null only
                        boolean isArrayOnlyNulls = true;
                        for (int i = 0; i <= usersToNotify.length - 1; i++) {
                            if (usersToNotify[i] != null) {
                                isArrayOnlyNulls = false;
                                break;
                            }
                        }

                        if (isArrayOnlyNulls) {
                            throw new Exception("No android user to send message to");
                        }

                        String androidUsersToNotify = "[";
                        for (int i = 0; i <= usersToNotify.length - 1; i++) {
                            if (usersToNotify[i] != null) {
                                androidUsersToNotify =  androidUsersToNotify + usersToNotify[i];
                                if (i != usersToNotify.length - 1 && usersToNotify[i + 1] != null  ) {
                                    androidUsersToNotify = androidUsersToNotify + ",";
                                }
                            }


                        }
                        androidUsersToNotify = androidUsersToNotify + "]";

                        JSONObject jsonParam = new JSONObject();
                        jsonParam.put("registration_ids", new JSONArray(androidUsersToNotify));
                        jsonParam.put("priority", "high");
                        jsonParam.put("data", new JSONObject()
                                .put("content", new JSONObject()
                                        .put("id", "100")
                                        .put("channelKey", "basic_channel")
                                        .put("title", title)
                                        .put("body", body)
                                        .put("notificationLayout", "BigPicture")
                                        .put("largeIcon", "https://avidabloga.files.wordpress.com/2012/08/emmemc3b3riadeneilarmstrong3.jpg")
                                        .put("bigPicture", "https://www.dw.com/image/49519617_303.jpg")
                                        .put("showWhen", "true")
                                        .put("autoCancel", "true")
                                        .put("privacy", "Private")
                                        .put("chatID", chatID)
                                        .put("allUsersInvoledTokens", allUsersInvolvedTokens)
                                        .put("androidUsersInvolvedTokens", androidUsersInvolvedTokens)
                                        .put("iosUsersInvolvedTokens", iosUsersInvolvedTokens)));


                        Log.i("JSON", jsonParam.toString());
                        DataOutputStream os = new DataOutputStream(conn.getOutputStream());
                        //os.writeBytes(URLEncoder.encode(jsonParam.toString(), "UTF-8"));
                        os.writeBytes(jsonParam.toString());

                        os.flush();
                        os.close();

                        Log.i("STATUS", String.valueOf(conn.getResponseCode()));
                        Log.i("STATUS", String.valueOf(conn.getResponseMessage()));
                        Log.i("MSG", conn.getResponseMessage());

                        conn.disconnect();
                    }

                } catch (Exception e) {
                    e.printStackTrace();
                }

//                //IOS push notifcionations
                try {
                    boolean needSendToIos = false;
                    if (iosUsersInvolvedTokens.length() != 2) { //If its 2 its empty array
                        needSendToIos = true;
                    }
                    if (needSendToIos) {
                        URL url = new URL("https://fcm.googleapis.com/fcm/send");
                        HttpURLConnection conn = (HttpURLConnection) url.openConnection();
                        conn.setRequestMethod("POST");
                        conn.setRequestProperty("Content-Type", "application/json");
                        conn.setRequestProperty("Authorization", "key=xxxx");
                        //                    conn.setRequestProperty("Accept","application/json");
                        conn.setDoOutput(true);
                        conn.setDoInput(true);
                        String iosUsersInvolvedTokensContent = iosUsersInvolvedTokens.replace("[", "");
                        iosUsersInvolvedTokensContent = iosUsersInvolvedTokensContent.replace("]", "");
                        String[] usersToNotify = iosUsersInvolvedTokensContent.split(",");
                        for (int i = 0; i <= usersToNotify.length - 1; i++) {
                            if (usersToNotify[i].contains(userToken)) {
                                usersToNotify[i] = null;
                                break;
                            }
                        }

                        //Check if array is not null only
                        boolean isArrayOnlyNulls = true;
                        for (int i = 0; i <= usersToNotify.length - 1; i++) {
                            if (usersToNotify[i] != null) {
                                isArrayOnlyNulls = false;
                                break;
                            }
                        }

                        if (isArrayOnlyNulls) {
                            throw new Exception("No ios user to send message to");
                        }

                        String iosUsersToNotify = "[";
                        for (int i = 0; i <= usersToNotify.length - 1; i++) {
                            if (usersToNotify[i] != null) {
                                iosUsersToNotify =  iosUsersToNotify + usersToNotify[i];
                                if (i != usersToNotify.length - 1 && usersToNotify[i + 1] != null  ) {
                                    iosUsersToNotify = iosUsersToNotify + ",";
                                }
                            }


                        }
                        iosUsersToNotify = iosUsersToNotify + "]";

                        JSONObject jsonParam = new JSONObject();
                        jsonParam.put("registration_ids", new JSONArray(iosUsersToNotify));
                        jsonParam.put("priority", "high");
                        jsonParam.put("click_action", "MESSAGE_ACTION");
                        jsonParam.put("notification", new JSONObject()
                                .put("title", title)
                                .put("body", body)
                                .put("sound", "default")
                                .put("click_action", "MESSAGE_ACTION"));
                        jsonParam.put("data", new JSONObject()
                                .put("content", new JSONObject()
                                        .put("id", "100")
                                        .put("channelKey", "basic_channel")
                                        .put("title", title)
                                        .put("body", body)
                                        .put("notificationLayout", "BigPicture")
                                        .put("largeIcon", "https://avidabloga.files.wordpress.com/2012/08/emmemc3b3riadeneilarmstrong3.jpg")
                                        .put("bigPicture", "https://www.dw.com/image/49519617_303.jpg")
                                        .put("showWhen", "true")
                                        .put("autoCancel", "true")
                                        .put("privacy", "Private")
                                        .put("chatID", chatID)
                                        .put("allUsersInvoledTokens", allUsersInvolvedTokens)
                                        .put("androidUsersInvolvedTokens", new JSONArray(androidUsersInvolvedTokens))
                                        .put("iosUsersInvolvedTokens", new JSONArray(iosUsersInvolvedTokens))));


                        Log.i("JSON", jsonParam.toString());
                        DataOutputStream os = new DataOutputStream(conn.getOutputStream());
                        //os.writeBytes(URLEncoder.encode(jsonParam.toString(), "UTF-8"));
                        os.writeBytes(jsonParam.toString());

                        os.flush();
                        os.close();

                        Log.i("STATUS", String.valueOf(conn.getResponseCode()));
                        Log.i("MSG", conn.getResponseMessage());

                        conn.disconnect();
                    }

                } catch (Exception e) {
                    e.printStackTrace();
                }

            }
        });

        thread.start();
    }

}
