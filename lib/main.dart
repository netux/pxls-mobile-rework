import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'pxls.dart';

const PXLS_URL_BASE = 'https://pxls.space';

void main() {
  SystemChrome.setEnabledSystemUIOverlays([]);
  runApp(App());
}
