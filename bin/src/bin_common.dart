library tekartik_io_tools.rscstatus;

import 'dart:io';
import 'package:path/path.dart';

String get currentScriptName => basenameWithoutExtension(Platform.script.path);
