library tekartik_io_tools.io_common;

import 'dart:mirrors';
import 'package:path/path.dart';
import 'dart:io';

class _TestUtils {
  static final String scriptPath =
      (reflectClass(_TestUtils).owner as LibraryMirror).uri.toFilePath();
}

String getOutTestPath(List<String> parts) {
  return join(dirname(_TestUtils.scriptPath), "out", joinAll(parts));
}

String clearOutTestPath(List<String> parts) {
  String outPath = getOutTestPath(parts);
  try {
    new Directory(outPath).deleteSync(recursive: true);
  } catch (e) {}
  return outPath;
}
