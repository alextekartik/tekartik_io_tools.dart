library tekartik_io_tools.pub_utils;

import 'package:tekartik_io_tools/dartbin_utils.dart';
import 'package:tekartik_io_tools/process_utils.dart';
import 'dartbin_utils.dart';
import 'dart:async';
import 'dart:io';
import 'package:path/path.dart';

bool _DEBUG = false;

enum TestReporter { COMPACT, EXPANDED }

final Map<String, TestReporter> _testReporterMap = new Map.fromIterables(
    ["compact", "expanded"], [TestReporter.COMPACT, TestReporter.EXPANDED]);

final Map<TestReporter, String> _testReporterStringMap =
    new Map.fromIterables(_testReporterMap.values, _testReporterMap.keys);

String testReporterString(TestReporter reporter) =>
    _testReporterStringMap[reporter];

List<String> testReporterStrings = new List.from(_testReporterStringMap.values);
TestReporter testReporterFromString(String reporterString) =>
    _testReporterMap[reporterString];

class PubPackage {
  String _path;

  String get path => _path;

  PubPackage(this._path);

  Future<RunResult> pub(List<String> args, {bool connectIo: false}) {
    return runPub(args, workingDirectory: _path, connectIo: connectIo);
  }

  Future<RunResult> upgrade(List<String> args, {bool connectIo: false}) {
    args = new List.from(args);
    args.insertAll(0, ['upgrade']);
    return pub(args, connectIo: connectIo);
  }

  Future<RunResult> runTest(List<String> args,
      {TestReporter reporter,
      bool color,
      int concurrency,
      List<String> platforms,
      bool connectIo: false,
      String name}) {
    args = new List.from(args);
    args.insertAll(0, ['run', 'test']);
    if (reporter != null) {
      args.addAll(['-r', testReporterString(reporter)]);
    }
    if (concurrency != null) {
      args.addAll(['-j', concurrency.toString()]);
    }
    if (name != null) {
      args.addAll(['-n', name]);
    }
    if (color != null) {
      if (color) {
        args.add('--color');
      } else {
        args.add('--no-color');
      }
    }
    if (platforms != null) {
      for (String platform in platforms) {
        args.addAll(['-p', platform]);
      }
    }
    return pub(args, connectIo: connectIo);
  }

  // same package is same path

  @override
  int get hashCode => path.hashCode;

  @override
  bool operator ==(o) => path == o.path;

  @override
  String toString() => path;
}

final String _pubspecYaml = "pubspec.yaml";

/// return true if root package
Future<bool> isPubPackageRoot(String dirPath) async {
  String pubspecYamlPath = join(dirPath, _pubspecYaml);
  return await FileSystemEntity.isFile(pubspecYamlPath);
}

bool isPubPackageRootSync(String dirPath) {
  String pubspecYamlPath = join(dirPath, _pubspecYaml);
  return FileSystemEntity.isFileSync(pubspecYamlPath);
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

String getPubPackageRootSync(String resolverPath) {
  String dirPath = normalize(absolute(resolverPath));

  while (true) {
    // Find the project root path
    if (isPubPackageRootSync(dirPath)) {
      return dirPath;
    }
    String parentDirPath = dirname(dirPath);

    if (parentDirPath == dirPath) {
      throw new Exception("No project found for path '$resolverPath");
    }
    dirPath = parentDirPath;
  }
}
/*
@deprecated
Future<RunResult> runPub(List<String> args,
    {String workingDirectory, bool connectIo: false}) async {
  if (_DEBUG) {
    print('running pub ${args}');
  }
  try {
    String bin;
    args = new List.from(args);
    if (Platform.isWindows) {
      bin = dartVmBin;
      args.insert(0, join(dartBinDirPath, 'snapshots', 'pub.dart.snapshot'));
    } else {
      bin = dartPubBin;
    }
    if (_DEBUG) {
      print('running pub ${args} ${dartPubBin}');
    }

    RunResult result = await run(bin, args,
        workingDirectory: workingDirectory, connectIo: connectIo);
    if (_DEBUG) {
      print('result: ${result}');
    }
    return result;
  } catch (e) {
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
*/
