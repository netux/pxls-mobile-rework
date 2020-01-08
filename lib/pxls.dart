import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:pxls_mobile/main.dart';

import 'board.dart';


class PxlsInfo {
  final String canvasCode;
  final int width, height;
  final List<Color> palette;
  final bool registrationEnabled;

  static Color hexToColor(dynamic val) {
    String hex = val as String;

    if (hex.startsWith('#')) {
      hex = hex.substring(1);
    }

    return Color(int.parse('FF' + hex, radix: 16));
  }

  PxlsInfo.fromJSON(Map<String, dynamic> json)
    : canvasCode = json['canvasCode'],
      width = json['width'],
      height = json['height'],
      palette = (json['palette'] as List).map(hexToColor).toList(growable: false),
      registrationEnabled = json['registrationEnabled'];
}

class _AppState extends State<App> {
  // TODO(netux): move board fetching to BoardPage
  Future<void> fetchFuture;
  PxlsInfo info;
  Uint8List boardData;

  @override
  void initState() {
    super.initState();

    Future infoFuture = http.get('$PXLS_URL_BASE/info')
      .then((req) {
        info = PxlsInfo.fromJSON(json.decode(req.body));
      });

    Future boardDataFuture = http.get('$PXLS_URL_BASE/boarddata')
      .then((req) {
        boardData = req.bodyBytes;
      });

    fetchFuture = Future.wait([infoFuture, boardDataFuture]);
  }

  @override
  Widget build(BuildContext ctx) {
    return MaterialApp(
      title: 'Pxls',
      theme: ThemeData(
        accentColor: Colors.blue
      ),
      home: FutureBuilder(
        future: fetchFuture,
        builder: (BuildContext ctx, AsyncSnapshot<void> snap) {
          if (snap.hasError) {
            return Center(child: Text('error: ${snap.error}'));
          } else if(!snap.hasData) {
            return Center(child: Text('loading...'));
          }

          return BoardPage(
            info: info,
            boardData: boardData
          );
        }
      )
    );
  }
}

class App extends StatefulWidget {
  const App({ Key key }) : super(key: key);

  @override
  _AppState createState() => _AppState();
}
