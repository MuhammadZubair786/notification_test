import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:http/http.dart' as http;


Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print('Handling a background message: ${message.messageId}');
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
   
  );
  Stripe.publishableKey = 'pk_test_51N6z0WCSqEAeQmcoDmNyGUr7SdIKsrZdKdXNY7tlef33hU3Y7kWnWePE0cWtFKeyJLwO54UlRVUQ4XCJByFb2JVA00Dzo2VAhN';
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: NotificationPage(),
    );
  }
}

class NotificationPage extends StatefulWidget {
  @override
  _NotificationPageState createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  @override
  void initState() {
    super.initState();
    setupFirebaseMessaging();
  }

  void setupFirebaseMessaging() async {
    FirebaseMessaging messaging = FirebaseMessaging.instance;

    NotificationSettings settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('User granted permission');
    } else if (settings.authorizationStatus == AuthorizationStatus.provisional) {
      print('User granted provisional permission');
    } else {
      print('User declined or has not accepted permission');
    }

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Message received in the foreground: ${message.messageId}');
      // Show your notification in the app
    });

    String? token = await messaging.getToken();
    print('FCM Token: $token');

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('Notification clicked!');
      // Handle navigation or other actions
    });
  }


   Map<String, dynamic>? paymentIntent;

  Future<void> makePayment(amount) async {
    try {
      paymentIntent = await createPaymentIntent(amount.toString(), 'USD');

      //STEP 2: Initialize Payment Sheet
      await Stripe.instance
          .initPaymentSheet(
              paymentSheetParameters: SetupPaymentSheetParameters(
                  paymentIntentClientSecret: paymentIntent!['client_secret'], //Gotten from payment intent

                  style: ThemeMode.dark,
                  merchantDisplayName: 'My'))
          .then((value) {});

      //STEP 3: Display Payment sheet
      displayPaymentSheet();
    } catch (err) {
      print('==========================> errorrr: $err');
      throw Exception(err);
    }
  }

  displayPaymentSheet() async {
    try {
      await Stripe.instance.presentPaymentSheet().then((value) async {
      
        print(paymentIntent!["id"].toString());

       
        paymentIntent = null;
      }).onError((error, stackTrace) {
        print('Error is:---> $error');

        throw Exception(error);
      });
    } on StripeException catch (e) {
      print('Error is:---> $e');
      const AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(
                  Icons.cancel,
                  color: Colors.red,
                ),
                Text("Payment Failed"),
              ],
            ),
          ],
        ),
      );
    } catch (e) {
      print('$e');
    }
  }

  String calculateAmount(String amount) {
    final calculatedAmout = (int.parse(amount)) * 100;
    return calculatedAmout.toString();
  }

  createPaymentIntent(String amount, String currency) async {
    var secretKey = 'sk_test_51N6z0WCSqEAeQmco5oYdduocrsMEG55iW5qXyz9rB9X0MAFUM7mgZlKN0jeGemUJrIIYlAentHB2P9UDSUisLRrF00tMByKHA3';
    final uri = Uri.parse('https://api.stripe.com/v1/payment_intents');
    final headers = {'Authorization': 'Bearer $secretKey', 'Content-Type': 'application/x-www-form-urlencoded'};

    Map<String, dynamic> body = {
      'amount': calculateAmount(amount),
      'currency': currency,
    };

    try {
      final response = await http.post(uri, headers: headers, body: body);

      return json.decode(response.body);
    } catch (err) {
      throw Exception(err.toString());
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Firebase Notifications')),
      body: Column(
        children: [
          Center(child: Text('Waiting for notifications...')),
          ElevatedButton(onPressed: (){
            makePayment(100);
          }, child: Text("test"))
        ],
      ),
    );
  }
}
