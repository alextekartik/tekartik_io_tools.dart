#!/usr/bin/env dart
library tekartik.rpubtest;

// Pull recursively

import 'dart:io';
import 'dart:async';
import 'package:path/path.dart';
import 'package:args/args.dart';
import 'package:yaml/yaml.dart';
import 'package:tekartik_core/log_utils.dart';
import 'package:tekartik_io_tools/pub_utils.dart';
import 'package:tekartik_io_tools/process_utils.dart';
import 'package:tekartik_io_tools/src/rpubpath.dart';
import 'package:pool/pool.dart';

const String _HELP = 'help';
const String _LOG = 'log';
const String _DRY_RUN = 'dry-run';
const String _CONCURRENCY = 'concurrency';
const String _PLATFORM = 'platform';

const List<String> allPlatforms = const [
  "vm",
  "dartium",
  "content-shell",
  "chrome",
  "phantomjs",
  "firefox",
  "safari",
  "ie"
];
///
/// Recursively update (pull) git folders
/// 
void main(List<String> arguments) {

  setupQuickLogging();

  ArgParser parser = new ArgParser(allowTrailingOptions: true);
  parser.addFlag(_HELP, abbr: 'h', help: 'Usage help', negatable: false);
  parser.addOption(_LOG, abbr: 'l', help: 'Log level (fine, debug, info...)');
  parser.addFlag(_DRY_RUN, abbr: 'n', help: 'Do not run test, simple show packages to be tested', negatable: false);
  parser.addOption(_CONCURRENCY, abbr: 'j', help: 'Number of concurrent packages tested', defaultsTo: '10');
  parser.addOption(_PLATFORM,
  abbr: 'p',
  help: 'The platform(s) on which to run the tests.',
  allowed: allPlatforms,
  defaultsTo: 'vm',
  allowMultiple: true);
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

  List<String> platforms = _argsResult[_PLATFORM];

  Future _handleProject(String path) async {
    PubPackage pkg = new PubPackage(path);
    //print(pkg);
    if (dryRun) {
      print('test on ${pkg.path}');
    } else {
      try {
        RunResult result = await pkg.runTest([], concurrency: 1,
        //reporter: TestReporter.EXPANDED,
        platforms:platforms, connectIo: true);
        if (result.exitCode != 0) {
          stderr.writeln('test error in ${path}');
        }
      } catch (e) {
        stderr.writeln('error thrown in ${path}');
        stderr.flush();
        throw e;
      }
    }
  }

  int poolSize = int.parse(_argsResult[_CONCURRENCY]);

  Pool pool = new Pool(poolSize);

  recursivePubPath(dirs, dependencies: ['test']).listen((String path) {
    pool.withResource(() async {
      return await _handleProject(path);
    });
  });
}

