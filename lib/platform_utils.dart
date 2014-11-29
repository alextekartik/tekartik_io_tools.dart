library platform_utils;

import 'dart:io';
import 'dart:async';
import 'package:path/path.dart';
import 'process_utils.dart';

// allow overriding in system environment
const String _TEKARTIK_HOST_NAME = "TEKARTIK_HOSTNAME";

String _hostname;
String get hostname {
  if (_hostname == null) {
    _hostname = Platform.environment[_TEKARTIK_HOST_NAME];
    if (_hostname == null) {
      _hostname = Platform.localHostname;
    }
  }
  return _hostname;
}

String _dartTopPath;

set dartTopPath(String path) {
  _dartTopPath = path;
}

void setDevDartTopPath() {
  _dartTopPath = join(dirname(dartTopPath), 'dart_dev');
}

String get dartTopPath {
  if (_dartTopPath == null) {
    _dartTopPath = dirname(dirname(dirname(dartVmBin)));
  }
  return _dartTopPath;
}

String _dartVmBin;

/**
 * Get dart vm either from executable or using the which command
 */
String get dartVmBin {
  if (_dartVmBin == null) {
    _dartVmBin = Platform.executable;
    if (!isAbsolute(_dartVmBin)) {
      if (!Platform.isWindows) {
        _dartVmBin = (Process.runSync('which', [_dartVmBin]).stdout as String).trim();
      }
    }
    if (FileSystemEntity.isLinkSync(_dartVmBin)) {
      _dartVmBin = new Link(_dartVmBin).targetSync();
    }
  }
  return _dartVmBin;
}

String get dartBinDirPath {
  String _dartBinDirPath = dirname(dartVmBin);
  return _dartBinDirPath;
}

String get dartPubBin {
  return join(dartBinDirPath, 'pub');
}

String get dartEditorBin {
  if (Platform.isMacOS) {
    return join(dartTopPath, 'DartEditor.app');
  } else if (Platform.isWindows) {
    return join(dartTopPath, 'DartEditor.exe');
  } else {
    return join(dartTopPath, 'DartEditor');
  }
}

String get dart2jsBin {
  if (Platform.isWindows) {
    return join(dartBinDirPath, 'dart2js.bat');
  } else {
    return join(dartBinDirPath, 'dart2js');
  }
}

String get scriptDirPath {
  String script = Platform.script.toFilePath(); // pathFromFileUriOrPath(Platform.script);
  //print('script path: $script');
  return isAbsolute(script) ? normalize(dirname(script)) : Directory.current.path;
}

String get scriptFilePath {
  String script = absolute(Platform.script.toFilePath());
  return script;
}

List<String> runPubArgs(List<String> args) {
  List<String> runArgs = new List();
  runArgs.add(join(dartBinDirPath, 'snapshots', 'pub.dart.snapshot'));
  runArgs.addAll(args);
  return runArgs;    
}

Future<RunResult> runPub(List<String> args, {String workingDirectory}) {

  List<String> runArgs = runPubArgs(args);

  return run(dartVmBin, runArgs, workingDirectory: workingDirectory, connectIo: true);
}
