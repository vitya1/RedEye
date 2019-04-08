import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(home: EyeTimer());
  }
}

class EyeTimer extends StatefulWidget {
    @override
    State createState() => new EyeTimerState();
}

class EyeTimerState extends State<EyeTimer> with WidgetsBindingObserver {
  AppLifecycleState state; 
  Timer timer;
  Map texts;

  final name = 'redeye';
  final sRestMinutes = 20;
  final cyclesToGo = 3;

  int tSeconds = 0;
  int tMinutes = 0;
  int cycles = 0;

  bool isAlerting = false;

  Future<void> loadTexts() async {
    String json = await rootBundle.loadString('assets/data/texts.json');
    texts = jsonDecode(json);
  }

  void notify() async {
    FlutterLocalNotificationsPlugin plugin = new FlutterLocalNotificationsPlugin();
    var setting = new InitializationSettings(
        new AndroidInitializationSettings('@mipmap/ic_launcher'), new IOSInitializationSettings());
    plugin.initialize(setting);
    var details = new NotificationDetails(
        new AndroidNotificationDetails(name, name, name), new IOSNotificationDetails());
    await plugin.show(0, 'RedEye', texts['notify'], details);
  }

  bool isBackground() {
    return state != null && state != AppLifecycleState.resumed
     && (state == AppLifecycleState.paused || state == AppLifecycleState.inactive);
  }

  showAlert(text) {
    if(isAlerting) 
      return;
    isAlerting = true;
    final FlatButton button = new FlatButton(child: new Text("Ok"), onPressed: () {
      isAlerting = false;
      Navigator.of(context).pop();
    });
    showDialog(
      context: context,
      builder: (BuildContext context) => AlertDialog(content: new Text(text), actions: <Widget>[button])
    );
  }

  iterateTimer() {
    if(tSeconds == 59) {
      tMinutes += 1;
      tSeconds = 0;
    } else {
      tSeconds++;
    }
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

  applyPadding(Widget w, EdgeInsets p) {
    return Padding(padding: p, child: w);
  }

  getTextStyle(double s) {
    return new TextStyle(fontSize: s, color: Colors.grey[200]);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    loadTexts().then((result)  => startTimer());
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

  @override
  Widget build (BuildContext context) {
    var notice = applyPadding(new Text("Working time:", style: getTextStyle(14)), EdgeInsets.only(top: 20.0));

    var text = "${tMinutes.toString().padLeft(2, '0')}:${tSeconds.toString().padLeft(2, '0')}";
    var timer = applyPadding(new Text(text, style: getTextStyle(88), textAlign: TextAlign.center), EdgeInsets.only(bottom: 20.0));

    var restartButton = FloatingActionButton(
      onPressed: () => startTimer(), backgroundColor: Colors.orange[200], foregroundColor: Colors.grey[850], child: Icon(Icons.update),
    );

    return new Scaffold(
      body: new Container(
        decoration: new BoxDecoration(
          image: new DecorationImage(image: new AssetImage("assets/images/bg-main.png"), fit: BoxFit.cover)
        ),
        child: Center(child: new Column(mainAxisAlignment: MainAxisAlignment.center, children: [notice, timer, restartButton]))
      )
    );
  }
}