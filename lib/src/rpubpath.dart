library tekartik_io_tools.rpubpath;

import 'dart:async';
import 'dart:io';
import 'package:path/path.dart';
import 'package:tekartik_io_tools/pub_utils.dart';
import 'package:yaml/yaml.dart';

Stream<String> recursivePubPath(List<String> dirs, {List<String> dependencies}) {
  StreamController<String> ctlr = new StreamController();

  Future _handleDir(String dir) async {

    // Ignore folder starting with .
    // don't event go below
    if (!basename(dir).startsWith('.')) {
      if (await isPubPackageRoot(dir)) {
        if (dependencies is List && !dependencies.isEmpty) {
          Future _handleYaml(String yamlPath) async {
            try {
              String content = await new File(yamlPath).readAsString();
              var doc = loadYaml(content);

              bool _hasDependencies(String kind, String dependency) {
                Map dependencies = doc[kind];
                if (dependencies != null) {
                  if (dependencies[dependency] != null) {
                    return true;
                  }
                }
                return false;
              }

              for (String dependency in dependencies) {

                if (_hasDependencies('dependencies', dependency) || _hasDependencies('dev_dependencies', dependency)) {
                  ctlr.add(dir);
                }
              }
            } catch (e, st) {
              print('Error parsing $yamlPath');
              print(e);
              print(st);
            }
          }

          String pubspecYaml = "pubspec.yaml";
          String pubspecYamlPath = join(dir, pubspecYaml);
          await _handleYaml(pubspecYamlPath);
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