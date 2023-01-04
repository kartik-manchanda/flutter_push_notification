import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/container.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String? mtoken = "";
  late FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  TextEditingController username = TextEditingController();
  TextEditingController title = TextEditingController();
  TextEditingController body = TextEditingController();

  @override
  void initState() {
    super.initState();

    requestPermission();
    // getToken();
    initInfo();
  }

  initInfo() {
    var androidInitialize =
        const AndroidInitializationSettings("@mipmap/ic_launcher");
    var iosInitialize = const DarwinInitializationSettings();
    var inializationsSettings =
        InitializationSettings(android: androidInitialize, iOS: iosInitialize);
    flutterLocalNotificationsPlugin.initialize(
      inializationsSettings,
      onDidReceiveNotificationResponse: (payload) async {
        try {
          if (payload != null && payload.toString().isNotEmpty) {
          } else {}
        } catch (e) {}
        return;
      },
    );

    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      print('...........onMessage............');
      print(
          'Message data: ${message.notification?.title}/${message.notification?.body}');

      BigTextStyleInformation bigTextStyleInformation = BigTextStyleInformation(
          message.notification!.body.toString(),
          htmlFormatBigText: true,
          contentTitle: message.notification!.title.toString(),
          htmlFormatContentTitle: true);

      AndroidNotificationDetails androidNotificationDetails =
          AndroidNotificationDetails('dbfood', 'dbfood',
              importance: Importance.high,
              styleInformation: bigTextStyleInformation,
              priority: Priority.high,
              playSound: true);

      NotificationDetails platformChannelSpecifics = NotificationDetails(
          android: androidNotificationDetails,
          iOS: DarwinNotificationDetails());

      await flutterLocalNotificationsPlugin.show(0, message.notification?.title,
          message.notification?.body, platformChannelSpecifics,
          payload: message.data['body']);
    });
  }

  void requestPermission() async {
    FirebaseMessaging messaging = FirebaseMessaging.instance;
    NotificationSettings settings = await messaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true);

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print("User granted permision");
    } else if (settings.authorizationStatus ==
        AuthorizationStatus.provisional) {
      print("User granted provisional permision");
    } else {
      print("User declined permission");
    }
  }

   getToken() async {
    await FirebaseMessaging.instance.getToken().then((token) {
      setState(() {
        mtoken = token;
        print("My token is $mtoken");
      });
      saveToken(token!);
    });
  }

  Future<void> saveToken(String token) async {
    await FirebaseFirestore.instance
        .collection("UserTokens")
        .doc(username.text.toString())
        .set({'token': token});
  }

  void sendPushMessage(String token, String body, String title) async {
    try {
      await http.post(Uri.parse('https://fcm.googleapis.com/fcm/send'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization':
                'key=AAAAdDHWlj4:APA91bGm-a9usxjQem2Ts4eJzZH-U49sl4DA5V5xoEn4gZZ4EbMzUnPt2Fl0JqymDy_c4UlltqnC0T6A_2MlI2L3-z63NqFX5uBlijcL-OSPABcHq6SKtLeS_b-LOFcLs9_T3AOdlRcS'
          },
          body: jsonEncode(<String, dynamic>{
            'priority': 'high',
            "data": <String, dynamic>{
              "click_action": "FLUTTER_NOTIFICATION_CLICK",
              'status': 'done',
              'body': body,
              'title': title
            },
            "notification": {
              "title": title,
              "body": body,
              "android_channel_id": "dbfood"
            },
            "to": token,
          }));
    } catch (e) {
      if (kDebugMode) {
        print("error push notification");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          TextFormField(
            controller: username,
          ),
          TextFormField(
            controller: title,
          ),
          TextFormField(
            controller: body,
          ),
          GestureDetector(
            onTap: () async {
              String name = username.text.trim();
              String titleText = title.text.toString();
              String bodyText = body.text.toString();

              if (name != "") {
                await getToken();
                DocumentSnapshot snap = await FirebaseFirestore.instance
                    .collection("UserTokens")
                    .doc(name)
                    .get();

                String token = snap['token'];
                print(token);
                sendPushMessage(token, titleText, bodyText);
              }
            },
            child: Container(
              margin: EdgeInsets.all(20),
              height: 40,
              width: 200,
              child: Center(child: Text("Button")),
              decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(color: Colors.redAccent.withOpacity(0.5))
                  ]),
            ),
          )
        ]),
      ),
    );
  }
}
