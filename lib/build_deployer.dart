library tekartik_build_utils;

import 'file_utils.dart' as fu;
import 'package:path/path.dart';
import 'dart:async';
import 'dart:io';

class LocalDeployer {
  Future lastOp;
  String src;
  String dst;
  LocalDeployer(this.src, this.dst);

  bool _inited;

  void _init() {
    if (_inited != true) {
      fu.emptyOrCreateDirSync(dst);
      _inited = true;
    }
  }

  Future deployEntryPoint(String htmlPath) {
    return deploy(htmlPath).then((_) {
      return deploy('${htmlPath}_bootstrap.dart.js');
    });
  }

  Future deployIndexEntryPoint(String htmlPath) {
    return deploy(htmlPath, dstPath: "index.html").then((_) {
      return deploy('${htmlPath}_bootstrap.dart.js');
    });
  }

//  Future deployDirNotRecursive(String path) {
//    new Directory(path).listSync(recursive: false, true) {
//
//    });
//        return deploy(htmlPath, "index.html").then((_) {
//          return deploy('${htmlPath}_bootstrap.dart.js');
//        });
//      }

  Future deployAll(List<String> paths) {
    Iterator iterator = paths.iterator;
    Future _deployNext() {
      if (iterator.moveNext()) {
        String path = iterator.current;
        //devPrint('path $path');
        return deploy(path).then((_) {
          return _deployNext();
        });
      } else {
        return new Future.value();
      }
    }

    return _deployNext();
  }

  Future deploy(String path,
      {String dstPath, bool recursive: true, List<String> but}) {
    _init();
    String src_ = join(src, path);
    String dst_ = join(dst, dstPath == null ? path : dstPath);
    if (FileSystemEntity.isDirectorySync(path)) {
      //fu.copyFilesIfNewer(src_, dst_);
      //return fu.linkDir(src_, dst_);
      return fu.linkOrCopyFilesInDirIfNewer(src_, dst_,
          recursive: recursive, but: but);
    } else {
      return fu.linkOrCopyFileIfNewer(src_, dst_);
    }
  }
}
