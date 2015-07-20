library tekartik_git_utils;

import 'dart:async';
import 'dart:io';

import 'package:tekartik_io_tools/process_utils.dart';
import 'package:path/path.dart';
import 'package:logging/logging.dart';

Logger __log;

Logger get _log {
  if (__log == null) {
    __log = new Logger("git_utils");
  }
  return __log;
}

bool _DEBUG = false;

class GitStatusResult {
  final RunResult runResult;

  GitStatusResult(this.runResult);

  bool nothingToCommit = false;
  bool branchIsAhead = false;
}

class GitPath {
  String _path;

  String get path => _path;

  GitPath(this._path);

  GitPath._();

  Future pull() {
    return gitPull(path);
  }

  Future<RunResult> _run(List<String> args) {
    return gitRun(args, workingDirectory: path);
  }

  Future<GitStatusResult> status() {
    return _run(['status']).then((RunResult result) {
      GitStatusResult statusResult = new GitStatusResult(result);

      bool showResult = true;
      if (result.exitCode == 0) {
        List<String> lines = result.out.split("\n");

        lines.forEach((String line) {
          // Linux /Win?/Mac?
          if (line.startsWith('nothing to commit')) {
            statusResult.nothingToCommit = true;
          }
          if (line.startsWith('Your branch is ahead of') ||
          line.startsWith('# Your branch is ahead of') // output of drone io
          ) {
            statusResult.branchIsAhead = true;
          }
        });

        if ((!statusResult.nothingToCommit) || (statusResult.branchIsAhead)) {
          showResult = true;
        } else {
          showResult = false;
        }

      }

      if (showResult) {
        _displayResult(result);
      }

      return statusResult;
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
    print("Git project ${_path}");
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

class GitProject extends GitPath {
  String src;

  GitProject(this.src, {String rootFolder}) : super._() {
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
    if (_log.isLoggable(Level.FINEST)) {
      args.add('--progress');
    }
    args.addAll([src, path]);
    return gitRun(args);
  }

  Future pullOrClone() {
    // TODO: check the origin branch
    if (new File(join(path, '.git', 'config')).existsSync()) {
      return pull();
    } else {
      return clone();
    }
  }
}

Future<RunResult> gitRun(List<String> args,
                         {String workingDirectory, bool connectIo: false}) {
  if (_DEBUG) {
    print('running git ${args}');
  }
  return run('git', args,
  workingDirectory: workingDirectory, connectIo: connectIo).catchError((e) {
    // Caught ProcessException: No such file or directory

    if (e is ProcessException) {
      print("${e.executable} ${e.arguments}");
      print(e.message);
      print(e.errorCode);

      if (e.message.contains("No such file or directory") &&
      (e.errorCode == 2)) {
        print('GIT ERROR: make sure you have git installed in your path');
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

Future gitPull(String path) {
  return gitRun(['pull'], workingDirectory: path);
}

Future gitStatus(String path) {
  return gitRun(['status'], workingDirectory: path);
}

Future<bool> isGitTopLevelPath(String path) async {
  String dotGit = ".git";
  String gitFile = join(path, dotGit);
  return await FileSystemEntity.isDirectory(gitFile);
}
