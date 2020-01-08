import 'dart:typed_data';
import 'dart:ui';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'pxls.dart';


class _BoardPainter extends CustomPainter {
  Uint8List data;
  List<Paint> palette;
  int boardWidth;

  _BoardPainter(this.data, this.boardWidth, List<Color> palette) {
    this.palette = palette.map((c) => Paint()..color = c).toList();
  }

  @override
  void paint(Canvas canvas, Size size) {
    for (int i = 0; i < data.lengthInBytes; i++) {
      double x = (i % boardWidth).toDouble();
      if (x >= size.width) {
        // Out of bounds, avoid drawing.
        continue;
      }
      double y = i / boardWidth;
      if (y >= size.height) {
        // Out of bounds, avoid drawing.
        // Since we are drawing top to bottom, we can stop earlier here.
        break;
      }

      int colorIdx = data[i];
      if (colorIdx == 255) {
        // Transparent pixel, avoid drawing.
        continue;
      }

      Paint paint = palette[colorIdx % palette.length];
      canvas.drawRect(Rect.fromLTWH(x, y, 1, 1), paint);
    }
  }

  @override
  bool shouldRepaint(_BoardPainter old) {
    // return old.data != data || old.boardWidth != boardWidth || old.palette != palette;
    return false;
  }
}


class _Board extends StatefulWidget {
  final Uint8List boardData;
  final int boardWidth;
  final List<Color> palette;

  int get boardHeight => (boardData.length / boardWidth).floor();

  _Board({
    Key key,
    @required this.boardData,
    @required this.boardWidth,
    @required this.palette
  }) : super(key: key);

  @override
  _BoardState createState() => _BoardState();
}

class _BoardState extends State<_Board> {
  Offset pan = Offset(0, 0);
  double zoom = 1;
  Uint8List boardData;

  @override
  void initState() {
    super.initState();

    PictureRecorder recorder = PictureRecorder();
    Canvas boardCanvas = Canvas(recorder);
    for (int i = 0; i < widget.boardData.lengthInBytes; i++) {
      double x = (i % widget.boardWidth).toDouble();
      double y = i / widget.boardWidth;

      int colorIdx = widget.boardData[i];
      if (colorIdx == 255) {
        // Transparent pixel, avoid drawing.
        continue;
      }

      Paint paint = Paint()..color = widget.palette[colorIdx % widget.palette.length];
      boardCanvas.drawRect(Rect.fromLTWH(x, y, 1, 1), paint);
    }

    Picture boardPic = recorder.endRecording();
    boardPic.toImage(widget.boardWidth, widget.boardHeight)
      .then((img) => img.toByteData(format: ui.ImageByteFormat.png))
      .then((bd) => bd.buffer.asUint8List())
      .then((data) {
        setState(() {
          boardData = data;
        });
      });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      child: Transform(
        transform: Matrix4.identity()
          ..translate(pan.dx, pan.dy, 0)
          ..scale(zoom),
        child: this.boardData == null
          ? Container(
            width: widget.boardWidth.toDouble(),
            height: widget.boardHeight.toDouble()
          )
          : SizedBox(
              width: widget.boardWidth.toDouble(),
              height: widget.boardHeight.toDouble(),
              child: Image.memory(
                this.boardData,
                filterQuality: FilterQuality.none
              )
            )
        // child: CustomPaint(
        //   size: boardSize,
        //   painter: widget.painter,
        //   isComplex: true
        // ),
      ),
      // onHorizontalDragUpdate: (DragUpdateDetails e) {
      //   double x = pan.dx + e.primaryDelta / zoom;
      //   setState(() {
      //     pan += Offset(x, 0);
      //   });
      // },
      // onVerticalDragUpdate: (DragUpdateDetails e) {
      //   double y = pan.dy + e.primaryDelta / zoom;
      //   setState(() {
      //     pan += Offset(0, y);
      //   });
      // },
      onScaleUpdate: (ScaleUpdateDetails e) {
        double x = pan.dx + e.focalPoint.dx / zoom;
        double y = pan.dy + e.focalPoint.dy/ zoom;

        setState(() {
          zoom += e.scale;
          // x -= e.focalPoint.dx / zoom;
          // y -= e.focalPoint.dy / zoom;
          pan = Offset(x, y);
        });
      },
    );
  }
}

class BoardPage extends StatefulWidget {
  final PxlsInfo info;
  final Uint8List boardData;

  const BoardPage({
    Key key,
    @required this.info,
    @required this.boardData
  }) : super(key: key);

  @override
  _BoardPageState createState() => _BoardPageState();
}

class _BoardPageState extends State<BoardPage> {
  @override
  Widget build(BuildContext ctx) {
    return Stack(
      fit: StackFit.expand,
      children: <Widget>[
        _Board(
          boardData: widget.boardData,
          boardWidth: widget.info.width,
          palette: widget.info.palette
        ),
        Column(
          children: <Widget>[
            Container(
              child: const Text('Top bar'),
              color: const Color.fromARGB(127, 255, 255, 255)
            ),
            Spacer(),
            Container(
              child: const Text('Bottom bar'),
              color: const Color.fromARGB(127, 255, 255, 255)
            ),
          ],
        )
      ],
    );
  }
}
