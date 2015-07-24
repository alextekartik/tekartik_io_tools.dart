#!/usr/bin/env dart
library tekartik_io_tools.rscpull;

// Pull recursively

import 'dart:io';
import 'dart:async';
import 'package:args/args.dart';
import 'package:path/path.dart';
import 'package:tekartik_core/log_utils.dart';
import 'package:tekartik_io_tools/git_utils.dart';
import 'package:tekartik_io_tools/hg_utils.dart';

const String _HELP = 'help';
const String _LOG = 'log';
const String _DRY_RUN = 'dry-run';

///
/// Recursively update (pull) git folders
///
///
main(List<String> arguments) async {

  Logger log;
  //setupQuickLogging();

  ArgParser parser = new ArgParser(allowTrailingOptions: true);
  parser.addFlag(_HELP, abbr: 'h', help: 'Usage help', negatable: false);
  parser.addOption(_LOG, abbr: 'l', help: 'Log level (fine, debug, info...)');
  parser.addFlag(_DRY_RUN, abbr: 'n', help: 'Do not run test, simple show packages to be tested', negatable: false);

  ArgResults _argsResult = parser.parse(arguments);

  bool help = _argsResult[_HELP];
  if (help) {
    print(parser.usage);
    return;
  }
  bool dryRun = _argsResult[_DRY_RUN];

  String logLevel = _argsResult[_LOG];
  if (logLevel != null) {
    setupQuickLogging(parseLogLevel(logLevel));
  }
  log = new Logger("rscstatus");
  log.fine('Log level ${Logger.root.level}');

  // get dirs in parameters, default to current
  List<String> dirs = _argsResult.rest;
  if (dirs.isEmpty) {
    dirs = [Directory.current.path];
  }

  List<Future> futures = [];

  bool _isHgSupported = await isHgSupported;
  bool _isGitSupported = await isGitSupported;

  Future _handleDir(String dir) async {
    log.finest(dir);
    // Ignore folder starting with .
    // don't event go below
    if (!basename(dir).startsWith('.') &&
    (await FileSystemEntity.isDirectory(dir))) {
      log.finer(dir);
      if (_isGitSupported && await isGitTopLevelPath(dir)) {
        GitPath prj = new GitPath(dir);
        await(prj.pull(dryRun: dryRun));
      } else if (_isHgSupported && await isHgTopLevelPath(dir)) {
        HgPath prj = new HgPath(dir);
        await(prj.pull(dryRun: dryRun));
      } else {
        try {
          await new Directory(dir).list().listen((FileSystemEntity fse) {
            _handleDir(fse.path);
          }).asFuture();
        } catch (e, st) {
          log.fine(e.toString(), e, st);
        }
      }
    }
    /*
    // this is a directoru
    String dotGit = ".git";
    return (FileSystemEntity.isDirectory(dir)).then((bool isDir) {
      //print("dir $dir: ${isDir}");
      if (isDir) {
        String gitFile = join(dir, dotGit);
        return FileSystemEntity.isDirectory(gitFile).then((bool containsDotGit) {
          //print("gitFile $gitFile: ${containsDotGit}");
          if (containsDotGit) {
            gitPull(dir);
            print("git folder: ${dir}");
          } else {
            List<Future> sub = [];

            return new Directory(dir).list().listen((FileSystemEntity fse) {
              sub.add(_handleDir(fse.path));
            }).asFuture().then((_) {
              Future.wait(sub);
            });
          }
        });
      }
    });
    */
  }
  for (String dir in dirs) {
    print(dir);
    var _handle = _handleDir(dir);
    if (_handle is Future) {
      futures.add(_handle);
    }
  }
}

