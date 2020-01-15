import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'dart:async';
import 'dart:typed_data';
import 'package:text_to_path_maker/text_to_path_maker.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart' show rootBundle;

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setEnabledSystemUIOverlays([]);
  SystemChrome.setPreferredOrientations(
          [DeviceOrientation.landscapeLeft, DeviceOrientation.landscapeRight])
      .then((_) {
    runApp(MyApp());
  });
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: DigitalClockPage(),
    );
  }
}

class DigitalClockPage extends StatefulWidget {
  @override
  _DigitalClockPageState createState() => _DigitalClockPageState();
}

class _DigitalClockPageState extends State<DigitalClockPage>
    with SingleTickerProviderStateMixin {
  DateTime _dateTime = DateTime.now();
  Timer _timer;
  String time;

  Color bgColor;
  int bgID;

  PMFont myFont;
  List<Path> charPaths = List<Path>();

  bool ready = false;

  void _updateTime() {
    setState(() {
      _dateTime = DateTime.now();

      if (_dateTime.hour >= 18 || _dateTime.hour <= 6) {
        bgColor = Colors.black;
        bgID = 1;
      } else {
        bgColor = Color(0xfff5f2d0);
        bgID = 0;
      }
      time = DateFormat('HH ss').format(_dateTime);

      _timer = Timer(
        Duration(minutes: 1) -
            Duration(seconds: _dateTime.second) -
            Duration(milliseconds: _dateTime.millisecond),
        _updateTime,
      );
    });
  }

  void generateFontPath() {
    rootBundle.load("assets/UtopiaStd-BlackHeadline.ttf").then((ByteData data) {
      // Create a font reader
      var reader = PMFontReader();

      // Parse the font
      myFont = reader.parseTTFAsset(data);

      // Generate the complete path for a specific character
      for (int i = 48; i < 58; i++) {
        charPaths.insert(i - 48, myFont.generatePathForCharacter(i));
      }

      setState(() {
        ready = true;
      });
    });
  }

  @override
  void initState() {
    time = DateFormat('HH mm').format(DateTime.now());

    _updateTime();

    //Generate path for each digit (0-9)
    generateFontPath();

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Stack(
          children: <Widget>[
            Center(
                child: Image.asset(
              'assets/indian_art$bgID.jpg',
              fit: BoxFit.cover,
              width: double.infinity,
              colorBlendMode: BlendMode.darken,
            )),
            ready
                ? CustomPaint(
                    willChange: true,
                    painter: ClkPainter(
                      bgColor: bgColor,
                      charPaths: charPaths,
                      time: time,
                    ),
                    size: MediaQuery.of(context).size,
                  )
                : SizedBox(),
          ],
        ),
      ),
    );
  }
}

class ClkPainter extends CustomPainter {
  List<Path> charPaths;
  String time;
  Color bgColor;

  ClkPainter({this.charPaths, this.time, this.bgColor});

  @override
  void paint(Canvas canvas, Size size) {
    // Define paint for digits border
    Paint borderPaint = Paint()
      ..blendMode = BlendMode.luminosity
      ..color = Colors.grey.shade500
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5.0
      ..strokeCap = StrokeCap.round;

    double scale = size.width * 0.25 / 640;
    double verticalPadding = size.height * 0.72;
    double horizontalPadding = scale / 0.25;

    // Create screen path and subtract digits path
    Path screenPath = Path()
      ..lineTo(size.width, 0)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    var h0 = PMTransform.moveAndScale(charPaths[int.parse(time[0])],
        15.0 * horizontalPadding, verticalPadding, scale, scale);
    screenPath = Path.combine(PathOperation.difference, screenPath, h0);
    var h1 = PMTransform.moveAndScale(charPaths[int.parse(time[1])],
        160.0 * horizontalPadding, verticalPadding, scale, scale);
    screenPath = Path.combine(PathOperation.difference, screenPath, h1);
    var m0 = PMTransform.moveAndScale(charPaths[int.parse(time[3])],
        340.0 * horizontalPadding, verticalPadding, scale, scale);
    screenPath = Path.combine(PathOperation.difference, screenPath, m0);
    var m1 = PMTransform.moveAndScale(charPaths[int.parse(time[4])],
        485.0 * horizontalPadding, verticalPadding, scale, scale);
    screenPath = Path.combine(PathOperation.difference, screenPath, m1);

    // Draw digits border
    canvas.drawPath(h0, borderPaint);
    canvas.drawPath(h1, borderPaint);
    canvas.drawPath(m0, borderPaint);
    canvas.drawPath(m1, borderPaint);

    // Draw Screen
    canvas.drawPath(screenPath, Paint()..color = bgColor);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return true;
  }
}
