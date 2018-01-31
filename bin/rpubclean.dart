#!/usr/bin/env dart
library tekartik_io_tools.rpubclean;

// Pull recursively

import 'dart:io';
import 'package:args/args.dart';
import 'package:path/path.dart';
import 'package:tekartik_common_utils/log_utils.dart';
import 'dart:async';
import 'src/bin_common.dart';
import 'package:tekartik_pub/src/rpubpath.dart';

const String _HELP = 'help';
const String _LOG = 'log';

Future cleanPath(String path, [bool root]) async {
  List<FileSystemEntity> fses = new Directory(path).listSync();
  for (FileSystemEntity fse in fses) {
    if (root) {
      if (FileSystemEntity.isDirectorySync(fse.path)) {
        if (basename(fse.path) == '.pub') {
          fse.deleteSync(recursive: true);
          continue;
        }

        if (basename(fse.path) == 'build') {
          fse.deleteSync(recursive: true);
          continue;
        }

        if (basename(fse.path) == 'packages') {
          fse.deleteSync(recursive: true);
          continue;
        }
      }
    } else {
      if (FileSystemEntity.isLinkSync(fse.path)) {
        if (basename(fse.path) == 'packages') {
          fse.deleteSync(recursive: false);
          continue;
        }
        if (basename(fse.path) == '.packages') {
          fse.deleteSync(recursive: false);
          continue;
        }
      }
    }

    if (FileSystemEntity.isDirectorySync(fse.path) &&
        !(basename(fse.path).startsWith('.'))) {
      cleanPath(fse.path);
      //print(fse);
    }
  }
}

///
/// Recursively find packages
///
void main(List<String> arguments) {
  setupQuickLogging();

  ArgParser parser = new ArgParser(allowTrailingOptions: true);
  parser.addFlag(_HELP, abbr: 'h', help: 'Usage help', negatable: false);
  parser.addOption(_LOG, abbr: 'l', help: 'Log level (fine, debug, info...)');

  ArgResults _argsResult = parser.parse(arguments);

  bool help = _argsResult[_HELP];
  if (help) {
    stdout.writeln(
        'clean all dart generated files: build/, .pub, packages/ from pub packages recursively (default from current directory)');
    stdout.writeln();
    stdout.writeln(
        'Usage: ${currentScriptName} [<folder_paths...>] [<arguments>]');
    stdout.writeln();
    stdout.writeln("Global options:");
    stdout.writeln(parser.usage);
    return;
  }
  String logLevel = _argsResult[_LOG];
  if (logLevel != null) {
    Logger.root.level = parseLogLevel(logLevel);
    Logger.root.info('Log level ${Logger.root.level}');
  }

  // get dirs in parameters, default to current
  List<String> dirs = _argsResult.rest;
  if (dirs.isEmpty) {
    if (basename(Directory.current.path) == "tekartik_io_tools.dart") {
      stderr.writeln("Prevent running clean on its own project directory");
      dirs = [];
    } else {
      dirs = [Directory.current.path];
    }
  }

  recursivePubPath(dirs).listen((String path) {
    //stdout.writeln(path);
    cleanPath(path, true);
  });
}
