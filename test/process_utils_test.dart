@TestOn("vm")
library process_utils_tests;

import 'package:dev_test/test.dart';
// ignore: deprecated_member_use
import 'package:tekartik_io_tools/process_utils.dart';
// ignore: deprecated_member_use
import 'package:tekartik_io_tools/dartbin_utils.dart';

void main() => defineTests();

void defineTests() {
  test('throw bad exe', () async {
    try {
      await run('com.tekartik.dummy.bin', null);
      fail("should fail");
    } on Exception catch (e) {
      //print(e);
      expect(e.runtimeType.toString(), "ProcessException");
    }

  });

  test('nothrow bad exe', () {
    return run('com.tekartik.dummy.bin', null, throwException: false)
        .then((RunResult result) {
      expect(result, isNull);
    });
  });

  test('run', () {
    return run(dartVmBin, ['--version']).then((RunResult result) {
      // "Dart VM version: 1.7.0-dev.4.5 (Thu Oct  9 01:44:31 2014) on "linux_x64"\n"
      expect(result.err.contains("version"), isTrue);
    });
  });
}
