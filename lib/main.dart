import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';
import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Red Eye',
      home: SplashScreen(),
    );
  }
}

class SplashScreen extends StatefulWidget {
    @override
    State createState() => new SplashScreenState();
}

class SplashScreenState extends State<SplashScreen> {
  String tip = '';

  Future<String> loadTips() async {
    String jsonString = await rootBundle.loadString('assets/data/tips.json');
    Map decoded = jsonDecode(jsonString);
    final index =  (new Random()).nextInt(decoded['data'].length);
    return decoded['data'][index];
  }

  @override
  void initState() {
    loadTips().then((result) {
      setState(() {
        tip = result;
      });
    });
    super.initState();
  }

  @override
  Widget build (BuildContext context) {
    final content = [
      Image.asset('assets/images/logo-l.png',),
      Padding(
        padding: EdgeInsets.all(20.0),
        child: new Text(
          tip, textAlign: TextAlign.center, style: new TextStyle(fontWeight: FontWeight.bold, color: Colors.grey[850]),
      )),
      new FlatButton.icon(
        label: Text("Next"), icon: Icon(Icons.arrow_forward_ios), color: Colors.green[200], textColor: Colors.grey[850],
        onPressed: () {
          Navigator.pushAndRemoveUntil(context,new MaterialPageRoute(builder: (context) => new TimerScreen()),
            ModalRoute.withName("/Main"));
        },
      ),
    ];

    return new Scaffold(
      body: Center(child: new Column(mainAxisAlignment: MainAxisAlignment.center, children: content))
    );
  }
}

class TimerScreen extends StatefulWidget {
    @override
    State createState() => new TimerScreenState();
}

class TimerScreenState extends State<TimerScreen> with WidgetsBindingObserver {
  AppLifecycleState state; 
  Timer timer;
  int sRestMinutes = 1;
  int lRestminutes = 0;

  int timerSeconds = 0;
  int timerMinutes = 0;

  void notify() async {
    FlutterLocalNotificationsPlugin plugin = new FlutterLocalNotificationsPlugin();
    var details = new NotificationDetails(
        new AndroidNotificationDetails('redeye', 'redeye', 'redeye'), new IOSNotificationDetails());
    await plugin.show(0, 'RedEye', 'Let your eyes take a rest buddy!', details);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState s) {
    setState(() => state = s);
  }

  @override
  void dispose() {
    super.dispose();
    WidgetsBinding.instance.removeObserver(this);
  }

  isBackground() {
    return state != null && state != AppLifecycleState.resumed
     && (state == AppLifecycleState.paused || state == AppLifecycleState.inactive);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    timer = Timer.periodic(new Duration(seconds: 1), (timer) {
      setState(() {
        if(timerSeconds == 59)
          timerMinutes += 1;
        timerSeconds = timerSeconds == 59 ? 0: timerSeconds + 1;
        if(timerMinutes == sRestMinutes) {
          timerMinutes = 0;
          if(isBackground())
            notify();
        }
      });
    });
  }

  @override
  Widget build (BuildContext context) {
    final List<Widget> content = [
      Padding(padding: EdgeInsets.all(20.0), child: new Text(
        "${isBackground()} - ${state} - ${timerMinutes <= 9 ? '0' + timerMinutes.toString() : timerMinutes}:${timerSeconds <= 9 ? '0' + timerSeconds.toString() : timerSeconds}",
        textAlign: TextAlign.center,
        style: new TextStyle(fontSize: 38, fontWeight: FontWeight.bold, color: Colors.grey[850]),
      )),
    ];

    return new Scaffold(
      body: Center(child: new Column(mainAxisAlignment: MainAxisAlignment.center, children: content))
    );
  }
}
