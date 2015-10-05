library tekartik_io_tools.io_common;

import 'dart:mirrors';
import 'package:path/path.dart';
import 'dart:io';
import 'package:tekartik_test/test.dart';

class _TestUtils {
  static final String scriptPath =
      (reflectClass(_TestUtils).owner as LibraryMirror).uri.toFilePath();
}

String get dataPath => join(_TestUtils.scriptPath, "data");
String get outDataPath => getOutTestPath(testDescriptions);

String getOutTestPath([List<String> parts]) {
  if (parts == null) {
    parts = testDescriptions;
  }
  return join(dirname(_TestUtils.scriptPath), "out", joinAll(parts));
}

String clearOutTestPath([List<String> parts]) {
  String outPath = getOutTestPath(parts);
  try {
    new Directory(outPath).deleteSync(recursive: true);
  } catch (e) {}
  return outPath;
}
