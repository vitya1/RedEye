import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';
import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: TimerScreen(),
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
  Map texts;
  String tip = '';

  final String name = 'redeye';
  final int sRestMinutes = 1;
  final int cyclesToGo = 3;

  int tSeconds = 0;
  int tMinutes = 0;
  int cycles = 0;

  bool isAvtiveAlert = false;

  Future<void> loadTexts() async {
    String jsonString = await rootBundle.loadString('assets/data/texts.json');
    texts = jsonDecode(jsonString);
    tip = texts['tips'][(new Random()).nextInt(texts['tips'].length)];
  }

  void notify() async {
    FlutterLocalNotificationsPlugin plugin = new FlutterLocalNotificationsPlugin();
    var settings = new InitializationSettings(
        new AndroidInitializationSettings('@mipmap/ic_launcher'), new IOSInitializationSettings());
    plugin.initialize(settings);

    var d = new NotificationDetails(
        new AndroidNotificationDetails(name, name, name), new IOSNotificationDetails());
    await plugin.show(0, 'RedEye', texts['notify'], d);
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

  bool isBackground() {
    return state != null && state != AppLifecycleState.resumed
     && (state == AppLifecycleState.paused || state == AppLifecycleState.inactive);
  }

  showAlert(text) {
    if(isAvtiveAlert) 
      return;
    isAvtiveAlert = true;
    final FlatButton button = new FlatButton(child: new Text("Ok"), onPressed: () {
      isAvtiveAlert = false;
      Navigator.of(context).pop();
    });
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(content: new Text(text), actions: <Widget>[button]);
    });
  }

  iterateTimer() {
    if(tSeconds == 59)
      tMinutes += 1;
    tSeconds = tSeconds == 59 ? 0: tSeconds + 1;
    if(tMinutes == sRestMinutes) {
      tMinutes = 0;
      cycles++;
      var text = cycles == cyclesToGo ? texts['hour'] : texts['20minutes'];
      showAlert(text);
      if(isBackground())
        notify();
    }
    if(cycles == cyclesToGo)
      cycles = 0;
  }

  startTimer() {
    setState(() {
      tSeconds = tMinutes = 0;
    });
    if(timer != null)
      timer.cancel();
    timer = Timer.periodic(new Duration(seconds: 1), (t) => setState(() => iterateTimer()));
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    loadTexts().then((result) {
      startTimer();
      showAlert(tip);
    });
  }

  @override
  Widget build (BuildContext context) {
    final List<Widget> content = [
      Padding(padding: EdgeInsets.only(top: 20.0), child: new Text(
        "Working time:", style: new TextStyle(color: Colors.grey[200])
      )),
      Padding(padding: EdgeInsets.only(bottom: 20.0), child: new Text(
        "${tMinutes <= 9 ? '0' + tMinutes.toString() : tMinutes}:${tSeconds <= 9 ? '0' + tSeconds.toString() : tSeconds}",
        textAlign: TextAlign.center,
        style: new TextStyle(fontSize: 88, color: Colors.grey[200]),
      )),
      FloatingActionButton(
        onPressed: () => startTimer(),
        backgroundColor: Colors.orange[200],
        foregroundColor: Colors.grey[850],
        child: Icon(Icons.update),
      ),
    ];

    return new Scaffold(
      body: new Container(
        decoration: new BoxDecoration(
          image: new DecorationImage(
            image: new AssetImage("assets/images/main-background.png"), fit: BoxFit.cover,
          )
        ),
        child: Center(child: new Column(mainAxisAlignment: MainAxisAlignment.center, children: content))
      )
    );
  }
}
