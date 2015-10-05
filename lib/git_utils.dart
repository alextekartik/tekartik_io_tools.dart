library tekartik_io_tools.git_utils;

import 'dart:async';
import 'dart:io';

import 'package:tekartik_io_tools/process_utils.dart';
import 'package:tekartik_io_tools/src/scpath.dart';
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

  Future pull({bool dryRun}) {
    return _run(['pull'], dryRun: dryRun);
  }

  Future<RunResult> _run(List<String> args, {bool dryRun}) async {
    if (dryRun == true) {
      stdout.writeln("git ${args.join(' ')} [$path]");
      return new RunResult();
    } else {
      return gitRun(args, workingDirectory: path);
    }
  }

  /// printResultIfChanges: show result if different than 'nothing to commit'
  Future<GitStatusResult> status({bool printResultIfChanges}) {
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
                  line.startsWith(
                      '# Your branch is ahead of') // output of drone io
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

      if (showResult && (printResultIfChanges == true)) {
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

  GitProject(this.src, {String path, String rootFolder}) : super._() {
    // Handle null
    if (path == null) {
      var parts = scUriToPathParts(src);

      _path = joinAll(parts);

      if (_path == null) {
        throw new Exception(
            'null path only allowed for https://github.com/xxxuser/xxxproject src');
      }
      if (rootFolder != null) {
        _path = absolute(join(rootFolder, path));
      } else {
        _path = absolute(_path);
      }
    } else {
      this._path = path;
    }
  }

  Future clone({bool connectIo: false}) {
    List<String> args = ['clone'];
    if (_log.isLoggable(Level.FINEST)) {
      args.add('--progress');
    }
    args.addAll([src, path]);
    return gitRun(args, connectIo: connectIo);
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

Future<bool> get isGitSupported async {
  try {
    await gitRun(['--version']);
    return true;
  } catch (e) {
    return false;
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

@deprecated
Future gitPull(String path) {
  return gitRun(['pull'], workingDirectory: path);
}

@deprecated
Future gitStatus(String path) {
  return gitRun(['status'], workingDirectory: path);
}

Future<bool> isGitRepository(String uri) async {
  RunResult runResult = await gitRun(['ls-remote', '--exit-code', '-h', uri]);
  // 2 is returned if not found
  // 128 if an error occured
  return (runResult.exitCode == 0) || (runResult.exitCode == 2);
}

Future<bool> isGitTopLevelPath(String path) async {
  String dotGit = ".git";
  String gitFile = join(path, dotGit);
  return await FileSystemEntity.isDirectory(gitFile);
}
