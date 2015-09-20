@TestOn("vm")
library process_utils_tests;

import 'package:test/test.dart';
import 'package:tekartik_io_tools/process_utils.dart';
import 'package:tekartik_io_tools/platform_utils.dart';

void main() => defineTests();

void defineTests() {
  test('throw bad exe', () {
    expect(run('com.tekartik.dummy.bin', null), throws);
  });

  test('throw bad dart param', () {
    return run(dartVmBin, null).then((RunResult result) {
      expect(result.executable, equals(dartVmBin));
      expect(result.arguments.isEmpty, isTrue);
      expect(result.out.isEmpty, isTrue);
      expect(result.err.isEmpty, isFalse);
      expect(result.exitCode, equals(255));
    });
  });

  test('nothrow bad exe', () {
    return run('com.tekartik.dummy.bin', null, throwException: false).then((RunResult result) {
      expect(result, isNull);
    });
  });

  test('run', () {
    return run(dartVmBin, ['--version']).then((RunResult result) {
      // "Dart VM version: 1.7.0-dev.4.5 (Thu Oct  9 01:44:31 2014) on "linux_x64"\n"
      expect(result.err.contains("version"), isTrue);
    });
  });

  test('run connectIo', () {
    // change false to true to check that you get output
    return run(dartVmBin, ['--version'], connectIo: false).then((RunResult result) {
      // devPrint(result.err);
      expect(result.err.contains("version"), isTrue);
    });
  });



}
