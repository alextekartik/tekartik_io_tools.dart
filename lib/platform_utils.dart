library tekartik_io_tools.platform_utils;

import 'dart:io';
// import 'package:tekartik_io_tools/dartbin_utils.dart' as bin;
import 'package:process_run/dartbin.dart' as bin;

// import 'dartbin_utils.dart' as bin;

// allow overriding in system environment
const String _tekartikHostname = "TEKARTIK_HOSTNAME";

String _hostname;
String get hostname {
  if (_hostname == null) {
    _hostname = Platform.environment[_tekartikHostname];
    if (_hostname == null) {
      _hostname = Platform.localHostname;
    }
  }
  return _hostname;
}

/**
 * Get dart vm either from executable or using the which command
 */
@deprecated
String get dartVmBin => bin.dartExecutable; // bin.dartVmBin;
