#!/usr/bin/env dart
library tekartik_io_tools.rpubtest;

// Pull recursively

import 'dart:io';
import 'dart:async';
import 'package:path/path.dart';
import 'package:args/args.dart';
import 'package:tekartik_core/log_utils.dart';
import 'package:tekartik_io_tools/pub_utils.dart';
import 'package:tekartik_io_tools/process_utils.dart';
import 'package:tekartik_io_tools/src/rpubpath.dart';
import 'package:pool/pool.dart';
import 'src/bin_common.dart';

const String _HELP = 'help';
const String _LOG = 'log';
const String _DRY_RUN = 'dry-run';
const String _CONCURRENCY = 'concurrency';
const String _PLATFORM = 'platform';
const String _NAME = 'name';
const String _reporterOption = "reporter";
const String _reporterOptionAbbr = "r";

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
  parser.addOption(_reporterOption,
      abbr: _reporterOptionAbbr,
      help: 'test result output',
      allowed: testReporterStrings);
  parser.addFlag(_DRY_RUN,
      abbr: 'd',
      help: 'Do not run test, simple show packages to be tested',
      negatable: false);
  parser.addOption(_CONCURRENCY,
      abbr: 'j',
      help: 'Number of concurrent packages tested',
      defaultsTo: '10');
  parser.addOption(_NAME,
      abbr: 'n', help: 'A substring of the name of the test to run');
  parser.addOption(_PLATFORM,
      abbr: 'p',
      help: 'The platform(s) on which to run the tests.',
      allowed: allPlatforms,
      defaultsTo: 'vm',
      allowMultiple: true);
  ArgResults _argsResult = parser.parse(arguments);

  bool help = _argsResult[_HELP];
  if (help) {
    stdout.writeln(
        "Call 'pub run test' recursively (default from current directory)");
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
  bool dryRun = _argsResult[_DRY_RUN];
  TestReporter reporter;
  String reporterString = _argsResult[_reporterOption];
  if (reporterString != null) {
    reporter = testReporterFromString(reporterString);
  }

  String name = _argsResult[_NAME];

  // get dirs in parameters, default to current
  List<String> dirs = new List.from(_argsResult.rest);
  if (dirs.isEmpty) {
    dirs = [Directory.current.path];
  }

  List<String> platforms;
  if (_argsResult.wasParsed(_PLATFORM)) {
    platforms = _argsResult[_PLATFORM];
  } else {
    String envPlatforms = Platform.environment["TEKARTIK_RPUBTEST_PLATFORMS"];
    if (envPlatforms != null) {
      stdout.writeln("Using platforms: ${envPlatforms}");
      platforms = envPlatforms.split(",");
    }
  }

  Future _handleProject(String path, [String file]) async {
    PubPackage pkg = new PubPackage(path);

    // if no file is given make sure the test/folder exists
    if (file == null) {
      // no tests found
      if (!(await FileSystemEntity.isDirectory(join(path, "test")))) {
        return;
      }
    }
    if (dryRun) {
      print('test on ${pkg.path}');
    } else {
      try {
        List<String> args = [];
        if (file != null) {
          args.add(file);
        }
        RunResult result = await pkg.runTest(args,
            concurrency: 1,
            reporter: reporter,
            platforms: platforms,
            connectIo: true,
            name: name);
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

  // Handle direct dart test file access
  List<String> testFiles = [];
  List<String> testDirs = [];
  for (String dir in dirs) {
    if (FileSystemEntity.isFileSync(dir)) {
      testFiles.add(dir);
    } else {
      testDirs.add(dir);
    }
  }

  // Handle pub sub path
  for (String testDir in testDirs) {
    if (!isPubPackageRootSync(testDir)) {
      String packageDir;
      try {
        packageDir = getPubPackageRootSync(testDir);
      } catch (_) {}
      if (packageDir != null) {
        // if it is the test dir, assume testing the package instead
        if (testDir == "test") {
          dirs.add(packageDir);
        } else {
          if (yamlHasAnyDependencies(getPackageYaml(packageDir), ['test'])) {
            for (FileSystemEntity entity in new Directory(testDir)
                .listSync(recursive: true, followLinks: false)) {
              if (entity.path.endsWith("_test.dart")) {
                testFiles.add(entity.path);
              }
            }
          }
        }
      }
    }
  }

  // Handle direct dart files
  for (String testFile in testFiles) {
    dirs.remove(testFile);

    pool.withResource(() async {
      String path = await getPubPackageRoot(testFile);
      testFile = relative(testFile, from: path);
      return await _handleProject(path, testFile);
    });
  }

  // Handle recursive projects
  recursivePubPath(dirs, dependencies: ['test']).listen((String path) {
    pool.withResource(() async {
      return await _handleProject(path);
    });
  });
}
