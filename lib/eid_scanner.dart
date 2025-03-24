library eid_scanner;

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_ml_kit/google_ml_kit.dart';
import 'package:camera/camera.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';

part 'src/eid_scanner.dart';
part 'src/emirate_id_model.dart';
part 'src/eid_scanner_camera.dart';
part 'src/eid_detect_card.dart';
part 'src/scan_box_painter.dart';
