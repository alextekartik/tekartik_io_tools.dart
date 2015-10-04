#!/usr/bin/env dart
library tekartik_io_tools.scclone;

// Pull recursively

import 'dart:io';
import 'dart:async';
import 'package:args/args.dart';
import 'package:tekartik_core/log_utils.dart';
import 'package:tekartik_io_tools/git_utils.dart';
import 'package:tekartik_io_tools/hg_utils.dart';
import 'package:tekartik_io_tools/src/scpath.dart';
import 'package:path/path.dart';
import 'src/bin_common.dart';

const String _HELP = 'help';
const String _LOG = 'log';
const String _DRY_RUN = 'dry-run';

///
/// clone hg or git repository
///
main(List<String> arguments) async {
  Logger log;
  //setupQuickLogging();

  ArgParser parser = new ArgParser(allowTrailingOptions: true);
  parser.addFlag(_HELP, abbr: 'h', help: 'Usage help', negatable: false);
  parser.addOption(_LOG, abbr: 'l', help: 'Log level (fine, debug, info...)');
  parser.addFlag(_DRY_RUN,
      abbr: 'd',
      help: 'Do not clone, simple show the folders created',
      negatable: false);
  ArgResults _argsResult = parser.parse(arguments);

  bool help = _argsResult[_HELP];

  _printUsage() {
    stdout.writeln(
        'clone one or multiple projects by their url and create pre-defined directory structure');
    stdout.writeln();
    stdout.writeln(
        'Usage: ${currentScriptName} <source_control_uris...> [<arguments>]');
    stdout.writeln();
    stdout.writeln(
        'Example: ${currentScriptName} https://github.com/alextekartik/tekartik_io_tools.dart');
    stdout.writeln(
        'will clone the project into ./git/github.com/alextekartik/tekartik_io_tools.dart');
    stdout.writeln();
    stdout.writeln("Global options:");
    stdout.writeln(parser.usage);
  }

  if (help) {
    _printUsage();
    return;
  }
  bool dryRun = _argsResult[_DRY_RUN];
  String logLevel = _argsResult[_LOG];
  if (logLevel != null) {
    setupQuickLogging(parseLogLevel(logLevel));
  }
  log = new Logger("scclone");
  log.fine('Log level ${Logger.root.level}');

  // get uris in parameters, default to current
  List<String> uris = _argsResult.rest;
  if (uris.isEmpty) {
    _printUsage();
  }

  Future _handleUri(String uri) async {
    log.fine("repository: ${uri}");
    List<String> parts = scUriToPathParts(uri);
    log.fine("parts ${parts}");

    String topDirName = basename(Directory.current.path);

    // try git first
    if (await isGitSupported && await isGitRepository(uri)) {
      // Check if remote is a git repository
      List<String> gitParts = new List.from(parts);
      if (topDirName != "git") {
        gitParts.insert(0, "git");
        log.fine("git parts ${gitParts}");
      }
      String path = absolute(joinAll(gitParts));
      if (await isGitTopLevelPath(path)) {
        stdout.writeln("git: ${path} already exists");
      } else {
        GitProject prj = new GitProject(uri, path: path);
        if (dryRun) {
          print("git clone ${prj.src} ${prj.path}");
        } else {
          await prj.clone(connectIo: true);
        }
      }
    } else if (await isHgSupported && await isHgRepository(uri)) {
      // try hg then
      List<String> hgParts = new List.from(parts);
      if (topDirName != "hg") {
        hgParts.insert(0, "hg");
        log.fine("hg parts ${hgParts}");
      }
      String path = absolute(joinAll(hgParts));
      if (await isHgTopLevelPath(path)) {
        stdout.writeln("hg: ${path} already exists");
      } else {
        HgProject prj = new HgProject(uri, path: path);
        if (dryRun) {
          print("hg clone ${prj.src} ${prj.path}");
        } else {
          await prj.clone(connectIo: true);
        }
      }
    }
  }

  // handle all uris
  for (String uri in uris) {
    await _handleUri(uri);
  }
}
