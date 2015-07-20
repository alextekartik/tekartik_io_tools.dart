library tekartik_pub_utils;

import 'package:tekartik_io_tools/process_utils.dart';
import 'platform_utils.dart';
import 'dart:async';
import 'dart:io';
import 'package:path/path.dart';

bool _DEBUG = false;

/*
Future pubBuildExample() => pubBuild(subDir: 'example', debug: true);
Future pubBuild({String projectPath, String subDir: 'web', bool debug: false}) {

  List<String> args = ['build'];

  // debug
  if (debug == true) {
    args.add('--mode=debug');
  }

  // project dir
  if (projectPath == null) {
    projectPath = projectTopPath;
  }

  // dir
  args.add(subDir);
  return run(dartPubBin, args, workingDirectory: projectPath, connectIo: true);
}
*/

enum TestPlaform {
  VM, DARTIUM, CONTENT_SHELL, CHROME, PHANTOMJS, FIREFOX
}


Map<TestPlaform, String> _testPlatformStringMap = new Map.fromIterables(
    [TestPlaform.VM, TestPlaform.DARTIUM, TestPlaform.CONTENT_SHELL, TestPlaform.CHROME, TestPlaform.PHANTOMJS, TestPlaform.FIREFOX],
    ["vm", "dartium", "content-shell", "chrome", "phantomjs", "firefox"]);

String _testPlatformString(TestPlaform platform) => _testPlatformStringMap[platform];

enum TestReporter {
  COMPACT, EXPANDED
}

Map<TestReporter, String> _testReporterStringMap = new Map.fromIterables(
    [TestReporter.COMPACT, TestReporter.EXPANDED],
    ["compact", "expanded"]);

String _testReporterString(TestReporter reporter) => _testReporterStringMap[reporter];

class PubPackage {
  String _path;

  String get path => _path;

  PubPackage(this._path);

  Future<RunResult> pub(List<String> args, {bool connectIo: false}) {
    return runPub(args, workingDirectory: _path, connectIo: connectIo);
  }

  Future<RunResult> runTest(List<String> args, {TestReporter reporter, int concurrency, List/*<TestPlatform>*/
  platforms, bool connectIo: false}) async {
    args = new List.from(args);
    args.insertAll(0, ['run', 'test']);
    if (reporter != null) {
      args.addAll(['-r', _testReporterString(reporter)]);
    }
    if (concurrency != null) {
      args.addAll(['-j', concurrency.toString()]);
    }
    if (platforms != null) {
      for (TestPlaform platform in platforms) {
        args.addAll(['-p', _testPlatformString(platform)]);
      }
    }
    return pub(args, connectIo: connectIo);
  }
}

final String _pubspecYaml = "pubspec.yaml";

/// return true if root package
Future<bool> isPubPackageRoot(String dirPath) async {
  String pubspecYamlPath = join(dirPath, _pubspecYaml);
  return await FileSystemEntity.isFile(pubspecYamlPath);
}

/// throws if no project found
Future<String> getPubPackageRoot(String resolverPath) async {
  String dirPath = normalize(absolute(resolverPath));

  while (true) {
    // Find the project root path
    if (await isPubPackageRoot(dirPath)) {
      return dirPath;
    }
    String parentDirPath = dirname(dirPath);

    if (parentDirPath == dirPath) {
      throw new Exception("No project found for path '$resolverPath");
    }
    dirPath = parentDirPath;
  }
}

Future<RunResult> runPub(List<String> args,
                         {String workingDirectory, bool connectIo: false}) async {
  if (_DEBUG) {
    print('running pub ${args}');
  }
  try {
    RunResult result = await run(dartPubBin, args,
    workingDirectory: workingDirectory, connectIo: connectIo);
    if (_DEBUG) {
      print('result: ${result}');
    }
    return result;
  }
  catch (e) {
// Caught ProcessException: No such file or directory
    if (_DEBUG) {
      print('exception: ${e}');
    }

    if (e is ProcessException) {
      print("${e.executable} ${e.arguments}");
      print(e.message);
      print(e.errorCode);

      if (e.message.contains("No such file or directory") &&
      (e.errorCode == 2)) {
        print('PUB ERROR: make sure you have pub installed in your path');
      }
    }
    throw e;
  }
}
