library tekartik_io_tools.platform_utils;

import 'dart:io';
import 'dartbin_utils.dart' as bin;

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

String _dartVmBin;

/**
 * Get dart vm either from executable or using the which command
 */
@deprecated
String get dartVmBin => bin.dartVmBin;
