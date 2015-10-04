#!/usr/bin/env dart
library tekartik_io_tools.rpubfind;

// Pull recursively

import 'dart:io';
import 'package:args/args.dart';
import 'package:tekartik_core/log_utils.dart';
import 'package:tekartik_io_tools/src/rpubpath.dart';
import 'src/bin_common.dart';

const String _HELP = 'help';
const String _LOG = 'log';
const String _DEPENDENCY = 'dependency';

///
/// Recursively find packages
///
void main(List<String> arguments) {
  setupQuickLogging();

  ArgParser parser = new ArgParser(allowTrailingOptions: true);
  parser.addFlag(_HELP, abbr: 'h', help: 'Usage help', negatable: false);
  parser.addOption(_LOG, abbr: 'l', help: 'Log level (fine, debug, info...)');
  parser.addOption(_DEPENDENCY,
      abbr: 'd', help: 'The packages it depends on', allowMultiple: true);
  ArgResults _argsResult = parser.parse(arguments);

  bool help = _argsResult[_HELP];
  if (help) {
    stdout.writeln(
        'Find pub package recursively (default from current directory)');
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

  List<String> dependencies = _argsResult[_DEPENDENCY];

  // get dirs in parameters, default to current
  List<String> dirs = _argsResult.rest;
  if (dirs.isEmpty) {
    dirs = [Directory.current.path];
  }

  recursivePubPath(dirs, dependencies: dependencies).listen((String path) {
    //stdout.writeln(path);
    print(path);
  });
}
