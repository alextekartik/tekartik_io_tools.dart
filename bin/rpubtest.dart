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

const String _HELP = 'help';
const String _LOG = 'log';
const String _DRY_RUN = 'dry-run';

///
/// Recursively update (pull) git folders
/// 
void main(List<String> arguments) {

  setupQuickLogging();

  ArgParser parser = new ArgParser(allowTrailingOptions: true);
  parser.addFlag(_HELP, abbr: 'h', help: 'Usage help', negatable: false);
  parser.addOption(_LOG, abbr: 'l', help: 'Log level (fine, debug, info...)');
  parser.addFlag(_DRY_RUN, abbr: 'd', help: 'Do not run test, simple show packages to be tested', negatable: false);

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

  List<Future> futures = [];

  Future _handleProject(String path) async {
    PubPackage pkg = new PubPackage(path);
    //print(pkg);
    if (dryRun) {
      print('test on ${pkg.path}');
    } else {
      await pkg.runTest([], concurrency: 1, reporter: TestReporter.EXPANDED, platforms:[TestPlaform.VM, TestPlaform.CONTENT_SHELL], connectIo: true);
    }
  }


  Future _handleYaml(String yamlPath) async {
    try {
      String content = await new File(yamlPath).readAsString();
      var doc = loadYaml(content);

      bool _hasDependencies(String kind) {
        Map dependencies = doc[kind];
        if (dependencies != null) {
          if (dependencies['test'] != null) {
            return true;
          }
        }
        return false;
      }

      if (_hasDependencies('dependencies') || _hasDependencies('dev_dependencies')) {
        await _handleProject(dirname(yamlPath));
      }
    } catch (e, st) {
      print('Error parsing $yamlPath');
      print(e);
      print(st);
    }

  }

  Future _handleDir(String dir) async {


    // Ignore folder starting with .
    // don't event go below
    if (!basename(dir).startsWith('.')) {
      if (await isPubPackageRoot(dir)) {
        String pubspecYaml = "pubspec.yaml";
        String pubspecYamlPath = join(dir, pubspecYaml);
        await _handleYaml(pubspecYamlPath);
      } else {
        List<Future> sub = [];
        return new Directory(dir).list().listen((FileSystemEntity fse) {
          sub.add(_handleDir(fse.path));
        }).asFuture().then((_) {
          return Future.wait(sub);
        });
      }
    }
  }

  for (String dir in dirs) {
    var _handle = _handleDir(dir);
    if (_handle is Future) {
      futures.add(_handle);
    }
  }
}

