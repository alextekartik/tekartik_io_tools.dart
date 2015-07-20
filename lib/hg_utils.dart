library tekartik_hg_utils;

import 'dart:async';
import 'dart:io';

import 'package:tekartik_io_tools/process_utils.dart';
import 'package:path/path.dart';
// import 'package:logging/logging.dart';

/*
Logger __log;
Logger get _log {
  if (__log == null) {
    __log = new Logger("hg_utils");
  }
  return __log;
}
*/

bool _DEBUG = false;

class HgStatusResult {
  final RunResult runResult;
  HgStatusResult(this.runResult);
  bool nothingToCommit = false;
  //bool branchIsAhead = false;
}

class HgOutgoingResult {
  final RunResult runResult;
  HgOutgoingResult(this.runResult);
  bool branchIsAhead = false;
}

class HgPath {
  String _path;
  String get path => _path;
  HgPath(this._path);
  HgPath._();

  Future pull() {
    return _run(['pull']);
  }

  Future<RunResult> _run(List<String> args) {
    return hgRun(args, workingDirectory: path);
  }

  Future<HgStatusResult> status() {
    return _run(['status']).then((RunResult result) {
      HgStatusResult statusResult = new HgStatusResult(result);

      //bool showResult = true;
      if (result.exitCode == 0) {
        if (result.out.isEmpty) {
          statusResult.nothingToCommit = true;
        }
        /*
        List<String> lines = result.out.split("\n");

        lines.forEach((String line) {
          // Linux /Win?/Mac?
          if (line.startsWith('nothing to commit')) {
            statusResult.nothingToCommit = true;
          }
          if (line.startsWith('Your branch is ahead of')) {
            statusResult.branchIsAhead = true;
          }
        });
        */
      }
      if (!statusResult.nothingToCommit) {
        _displayResult(result);
      }

      return statusResult;
    });
  }

  Future<HgOutgoingResult> outgoing() {
    return _run(['outgoing']).then((RunResult result) {
      HgOutgoingResult outgoingResult = new HgOutgoingResult(result);

      bool showResult = true;

      switch (result.exitCode) {
        case 0:
        case 1:
          {
            List<String> lines = result.out.split("\n");
            //print(lines.last);
            if (lines.last.startsWith('no changes found') ||
                lines.last.startsWith('aucun changement')) {
              outgoingResult.branchIsAhead = false;
            } else {
              outgoingResult.branchIsAhead = true;
            }
          }
          if (outgoingResult.branchIsAhead) {
            showResult = true;
          } else {
            showResult = false;
          }
      }

      if (showResult) {
        _displayResult(result);
      }

      return outgoingResult;
    });
  }

  Future<RunResult> add({String pathspec}) {
    List<String> args = ['add', pathspec];
    return _run(args);
  }

  Future<RunResult> commit(String message, {bool all}) {
    List<String> args = ['commit'];
    if (all == true) {
      args.add("--all");
    }
    args.addAll(['-m', message]);
    return _run(args);
  }

  ///
  /// branch can be a commit/revision number
  Future<RunResult> checkout({String commit}) {
    return _run(['checkout', commit]);
  }

  void _displayResult(RunResult result) {
    print("-------------------------------");
    print("Hg project ${_path}");
    print(
        "exitCode ${result.exitCode} ${result.executable} ${result.arguments} ${result.workingDirectory}");
    print("-------------------------------");
    if (result.err.length > 0) {
      print("${result.out}");
      print("ERROR: ${result.err}");
    } else {
      print("${result.out}");
    }
  }
}

class HgProject extends HgPath {
  String src;
  HgProject(this.src, {String rootFolder}) : super._() {
    // Handle null
    if (path == null) {
      Uri uri = Uri.parse(src);
      var parts = posix.split(uri.path);

      for (int i = parts.length - 1; i >= 0; i--) {
        if (parts[i] == 'github.com') {
          _path = joinAll(parts.sublist(i + 1));
        } else if (parts[i] == '/') {
          _path = joinAll(parts.sublist(i + 1));
        }
      }
      if (_path == null) {
        throw new Exception(
            'null path only allowed for https://github.com/xxxuser/xxxproject src');
      }
      if (rootFolder != null) {
        _path = join(rootFolder, path);
      }
      this._path = path;
    }
  }

  Future clone() {
    List<String> args = ['clone'];
    args.addAll([src, path]);
    return hgRun(args);
  }

  Future pullOrClone() {
    // TODO: check the origin branch
    if (new File(join(path, '.hg', 'hgrc')).existsSync()) {
      return pull();
    } else {
      return clone();
    }
  }
}

Future<RunResult> hgRun(List<String> args,
    {String workingDirectory, bool connectIo: false}) {
  if (_DEBUG) {
    print('running hg ${args}');
  }
  return run('hg', args,
      workingDirectory: workingDirectory, connectIo: connectIo).catchError((e) {
    // Caught ProcessException: No such file or directory
    if (_DEBUG) {
      print('exception: ${e}');
    }

    if (e is ProcessException) {
      print("${e.executable} ${e.arguments}");
      print(e.message);
      print(e.errorCode);

      if (e.message.contains("No such file or directory") &&
          (e.errorCode == 2)) {
        print('HG ERROR: make sure you have hg installed in your path');
      }
    }
    throw e;
  }).then((RunResult result) {
    if (_DEBUG) {
      print('result: ${result}');
    }
    return result;
  });
}

Future<bool> isHgTopLevelPath(String path) async {
  String dotHg = ".hg";
  String hgFile = join(path, dotHg);
  return await FileSystemEntity.isDirectory(hgFile);
}
