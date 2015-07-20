#!/usr/bin/env dart
library tekartik.rpubtest;

// Pull recursively

import 'dart:io';
import 'package:args/args.dart';
import 'package:tekartik_core/log_utils.dart';
import 'package:tekartik_io_tools/pub_utils.dart';
import 'package:tekartik_io_tools/src/rpubpath.dart';
import 'package:pool/pool.dart';

const String _HELP = 'help';
const String _LOG = 'log';
const String _DRY_RUN = 'dry-run';
const String _CONCURRENCY = 'concurrency';

///
/// Recursively update (pull) git folders
///
/// rpubupgrade -j 10 -n
/// 
void main(List<String> arguments) {

  setupQuickLogging();

  ArgParser parser = new ArgParser(allowTrailingOptions: true);
  parser.addFlag(_HELP, abbr: 'h', help: 'Usage help', negatable: false);
  parser.addOption(_LOG, abbr: 'l', help: 'Log level (fine, debug, info...)');
  parser.addOption(_CONCURRENCY, abbr: 'j', help: 'Number of concurrent operation', defaultsTo: '1');
  parser.addFlag(_DRY_RUN, abbr: 'n', help: 'Report, do not run', negatable: false);
  ArgResults _argsResult = parser.parse(arguments);

  bool help = _argsResult[_HELP];
  if (help) {
    print(parser.usage);
    return;
  }
  String logLevel = _argsResult[_LOG];
  if (logLevel != null) {
    Logger.root.level = parseLogLevel(logLevel);
    Logger.root.info('Log level ${Logger.root.level}');
  }
  bool dryRun = _argsResult[_DRY_RUN];

  // get dirs in parameters, default to current
  List<String> dirs = _argsResult.rest;
  if (dirs.isEmpty) {
    dirs = [Directory.current.path];
  }

  int poolSize = int.parse(_argsResult[_CONCURRENCY]);

  Pool pool = new Pool(poolSize);

  recursivePubPath(dirs).listen((String path) {
    pool.withResource(() async {
      PubPackage pkg = new PubPackage(path);

      List<String> args = [];
      if (dryRun) {
        args.addAll(['--dry-run']);
      }
      await pkg.upgrade(args, connectIo: true);
    });
  });

}

