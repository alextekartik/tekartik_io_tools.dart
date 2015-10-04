library tekartik_io_tools.rscstatus;

import 'dart:io';
import 'package:path/path.dart';

const String _HELP = 'help';
const String _LOG = 'log';

String get currentScriptName => basenameWithoutExtension(Platform.script.path);
