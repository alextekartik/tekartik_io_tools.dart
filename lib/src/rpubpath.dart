library tekartik_io_tools.rpubpath;

import 'dart:async';
import 'dart:io';
import 'package:path/path.dart';
import 'package:tekartik_io_tools/pub_utils.dart';

Stream<String> recursivePubPath(List<String> dirs) {
  StreamController<String> ctlr = new StreamController();

  Future _handleDir(String dir) async {


    // Ignore folder starting with .
    // don't event go below
    if (!basename(dir).startsWith('.')) {
      if (await isPubPackageRoot(dir)) {
        ctlr.add(dir);
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