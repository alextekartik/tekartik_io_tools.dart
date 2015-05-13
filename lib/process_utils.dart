library tekartik_io_process_utils;

import 'dart:io';
import 'dart:async';
import 'package:path/path.dart';
import 'package:logging/logging.dart';
import 'dart:convert';

class RunResult {
  // in
  String executable;
  List<String> arguments;
  String workingDirectory;

  // out
  String out;
  String err;
  int exitCode;

  String get commandLine {
    return "${executable} ${arguments}";
  }
  @override
  String toString() {
    StringBuffer sb = new StringBuffer();
    sb.writeln("-------------------------------");
    sb.writeln("exitCode ${exitCode} ${executable} ${arguments} ${workingDirectory}");
    sb.writeln("-------------------------------");
    if (out.length > 0) {
      sb.writeln("$out");
    }
    if (err.length > 0) {
      sb.writeln("ERR: ${err}");
    }
    return sb.toString();
  }
}

Logger _log = new Logger('ProcessUtils');

String processResultToString(ProcessResult result, [String msg]) {
  String out = result.stdout.trim();
  String err = result.stderr.trim();
  StringBuffer sb = new StringBuffer();
  sb.writeln("exitCode ${result.exitCode}");
  if (msg != null) {
    sb.writeln(msg);
  }
  if (out.length > 0) {
    sb.writeln("$out");
  }
  if (err.length > 0) {
    sb.writeln("ERR: ${err}");
  }
  return sb.toString();
}

logProcessResult(ProcessResult result, [String msg]) {
  String getOutput() => processResultToString(result, msg);
  if (result.exitCode != 0) {
    _log.severe('${getOutput()}');
  } else if (_log.isLoggable(Level.FINE)) {
    _log.fine('${getOutput()}');
  }
}

Future<RunResult> run(String executable, List<String> arguments, {String workingDirectory, bool throwException: true, bool connectIo, bool runInShell: false}) {
  if (arguments == null) {
    arguments = [];
  }
  if (workingDirectory != null) {
    workingDirectory =  normalize(absolute(workingDirectory));
  }

//  if (_log.isLoggable(Level.FINE)) {
//    _log.fine("running ${executable} ${arguments} ${workingDirectory}");
//  }

  RunResult newResult = new RunResult();
  newResult.executable = executable;
  newResult.arguments = arguments;
  newResult.workingDirectory = workingDirectory;
  if (_log.isLoggable(Level.FINEST)) {
    _log.finest('executing ${newResult.commandLine}...');
  }

  if (connectIo == true) {
    return Process.start(executable, arguments, workingDirectory: workingDirectory, runInShell: runInShell).then((Process process) {
      StringBuffer out = new StringBuffer();
      StringBuffer err = new StringBuffer();
      
      return Future.wait([process.stdout.listen((d) {
          stdout.add(d);
          out.write(UTF8.decode(d));
        }).asFuture(), process.stderr.listen((d) {
          stderr.add(d);
          err.write(UTF8.decode(d));
        }).asFuture(), process.exitCode.then((int exitCode) {
          newResult.exitCode = exitCode;
        })]).then((_) {
        newResult.out = out.toString().trim();
        newResult.err = err.toString().trim();

        if (_log.isLoggable(Level.FINE)) {
          _log.fine('$newResult');
        }
        return newResult;
      });
    });
  } else {
    return Process.run(executable, arguments, workingDirectory: workingDirectory).then((ProcessResult result) {
      // print("# exitCode ${result.exitCode} ${executable} ${arguments} ${workingDirectory}");


      String out = result.stdout;
      newResult.out = out.trim();
      String err = result.stderr;
      newResult.err = err.trim();
      newResult.exitCode = result.exitCode;

      if (newResult.exitCode != 0) {
        _log.severe('$newResult');
      } else if (_log.isLoggable(Level.FINE)) {
        _log.fine('$newResult');
      }
      return newResult;
    }).catchError((e) {
      // print(e);
      // print("$e running ${executable} ${arguments} ${workingDirectory}");
      if (throwException) {
        throw e;
      }

    });
  }
}
