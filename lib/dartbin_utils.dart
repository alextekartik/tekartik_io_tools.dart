library tekartik_io_tools.dartbin_utils;

import 'dart:io';
import 'package:path/path.dart';
import 'process_utils.dart';
import 'dart:async';
import 'args_utils.dart';

String _dartVmBin;

bool _debug = false;

///
/// Get dart vm either from executable or using the which command
///
String get dartVmBin {
  if (_dartVmBin == null) {
    _dartVmBin = Platform.resolvedExecutable;

    if (_debug) {
      print('dartVmBin: ${_dartVmBin}');
    }
    if (FileSystemEntity.isLinkSync(_dartVmBin)) {
      String link = _dartVmBin;
      _dartVmBin = new Link(_dartVmBin).targetSync();

      // on mac, if installed with brew, we might get something like ../Cellar/dart/1.12.1/bin
      // so make sure to make it absolute
      if (!isAbsolute(_dartVmBin)) {
        _dartVmBin = absolute(normalize(join(dirname(link), _dartVmBin)));
      }
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

///
/// cmd being
/// - dartfmt
/// - dartanalyzer
Future<RunResult> _runDartBinCommand(String cmd, List<String> args,
    {String workingDirectory, bool connectIo: false, bool cmdDryRun}) async {
  if (_debug) {
    print('running ${cmd}${argsToDebugString(args)}');
  }
  if (cmdDryRun == true) {
    print('${cmd}${argsToDebugString(args)}');
    return null;
  }
  try {
    String bin = dartVmBin;
    args.insert(0, join(dartBinDirPath, 'snapshots', '${cmd}.dart.snapshot'));

    if (_debug) {
      print('running dart ${args}${argsToDebugString(args)}');
    }

    RunResult result = await run(bin, args,
        workingDirectory: workingDirectory, connectIo: connectIo);
    if (_debug) {
      print('result: ${result}');
    }
    return result;
  } catch (e) {
// Caught ProcessException: No such file or directory
    if (_debug) {
      print('exception: ${e}');
    }

    if (e is ProcessException) {
      print("${e.executable} ${e.arguments}");
      print(e.message);
      print(e.errorCode);

      if (e.message.contains("No such file or directory") &&
          (e.errorCode == 2)) {
        print('DART ERROR: make sure you have dart installed in your path');
      }
    }
    rethrow;
  }
}

Future<RunResult> runDartFmt(List<String> args,
        {String workingDirectory, bool connectIo: false, bool cmdDryRun}) =>
    _runDartBinCommand('dartfmt', args,
        workingDirectory: workingDirectory,
        connectIo: connectIo,
        cmdDryRun: cmdDryRun);

Future<RunResult> runDartAnalyzer(List<String> args,
        {String workingDirectory, bool connectIo: false, bool cmdDryRun}) =>
    _runDartBinCommand('dartanalyzer', args,
        workingDirectory: workingDirectory,
        connectIo: connectIo,
        cmdDryRun: cmdDryRun);

Future<RunResult> runDart2Js(List<String> args,
        {String workingDirectory, bool connectIo: false, bool cmdDryRun}) =>
    _runDartBinCommand('dart2js', args,
        workingDirectory: workingDirectory,
        connectIo: connectIo,
        cmdDryRun: cmdDryRun);

Future<RunResult> runPub(List<String> args,
        {String workingDirectory, bool connectIo: false, bool cmdDryRun}) =>
    _runDartBinCommand('pub', args,
        workingDirectory: workingDirectory,
        connectIo: connectIo,
        cmdDryRun: cmdDryRun);
