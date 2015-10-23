library tekartik_io_tools.src.rpubpath;

import 'dart:async';
import 'dart:io';
import 'package:path/path.dart';
import 'package:tekartik_io_tools/pub_utils.dart';
import 'package:yaml/yaml.dart';

Map getPackageYaml(String packageRoot) {
  String pubspecYaml = "pubspec.yaml";
  String pubspecYamlPath = join(packageRoot, pubspecYaml);
  String content = new File(pubspecYamlPath).readAsStringSync();
  return loadYaml(content);
}

bool yamlHasAnyDependencies(Map yaml, List<String> dependencies) {
  bool _hasDependencies(String kind, String dependency) {
    Map dependencies = yaml[kind];
    if (dependencies != null) {
      if (dependencies[dependency] != null) {
        return true;
      }
    }
    return false;
  }

  for (String dependency in dependencies) {
    if (_hasDependencies('dependencies', dependency) ||
        _hasDependencies('dev_dependencies', dependency) ||
        _hasDependencies('dependency_overrides', dependency)) {
      return true;
    }
  }

  return false;
}

bool _isToBeIgnored(String baseName) {
  if (baseName == '.' || baseName == '..') {
    return false;
  }

  return baseName.startsWith('.');
}

Stream<String> recursivePubPath(List<String> dirs,
    {List<String> dependencies}) {
  StreamController<String> ctlr = new StreamController();

  Future _handleDir(String dir) async {
    // Ignore folder starting with .
    // don't event go below
    if (!_isToBeIgnored(basename(dir))) {
      if (await isPubPackageRoot(dir)) {
        if (dependencies is List && !dependencies.isEmpty) {
          Map yaml = getPackageYaml(dir);
          if (yamlHasAnyDependencies(yaml, dependencies)) {
            ctlr.add(dir);
          }
        } else {
          // add package path
          ctlr.add(dir);
        }
      } else {
        List<Future> sub = [];
        return new Directory(dir).list().listen((FileSystemEntity fse) {
          if (FileSystemEntity.isDirectorySync(fse.path)) {
            sub.add(_handleDir(fse.path));
          }
        }).asFuture().then((_) {
          return Future.wait(sub);
        });
      }
    }
  }

  List futures = [];
  for (String dir in dirs) {
    if (FileSystemEntity.isDirectorySync(dir)) {
      Future _handle = _handleDir(dir);
      if (_handle is Future) {
        futures.add(_handle);
      }
    } else {
      throw '${dir} not a directory';
    }
  }

  Future.wait(futures).then((_) {
    ctlr.close();
  });

  return ctlr.stream;
}
