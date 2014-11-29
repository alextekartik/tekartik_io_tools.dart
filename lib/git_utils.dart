library git_utils;

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

class GitPath {
  String path;
  GitPath(this.path);

  Future pull() {
    return gitPull(path);
  }
}

class GitProject extends GitPath {
  String src;
  GitProject(this.src, {String path, String rootFolder}) : super(path) {
    // Handle null
    if (path == null) {
      Uri uri = Uri.parse(src);
      var parts = posix.split(uri.path);
      for (int i = parts.length - 1; i >= 0; i--) {
        if (parts[i] == 'github.com') {
          path = joinAll(parts.sublist(i + 1));
        } else if (parts[i] == '/') {
          path = joinAll(parts.sublist(i + 1));
        }
      }
      if (path == null) {
        throw new Exception('null path only allowed for https://github.com/xxxuser/xxxproject src');
      }
      if (rootFolder != null) {
        path = join(rootFolder, path);
      }
      this.path = path;
    }
  }

  Future clone() {
    return gitClone(src, path);
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

Future<RunResult> gitRun(List<String> args) {
  return run('git', args).catchError((e) {
    // Caught ProcessException: No such file or directory

    if (e is ProcessException) {
      print("${e.executable} ${e.arguments}");
      print(e.message);
      print(e.errorCode);

      if (e.message.contains("No such file or directory") && (e.errorCode == 2)) {
        print('GIT ERROR: make sure you have git install in your path');
      }
    }
    throw e;
  });
}

Future gitClone(String src, String path) {
  // git clone [--progress] src path
  List<String> args = ['clone'];
  if (_log.isLoggable(Level.FINEST)) {
    args.add('--progress');
  }
  args.addAll([src, path]);
  return gitRun(args);

}

Future gitPull(String path) {
  return run('git', ['pull'], workingDirectory: path);

}
