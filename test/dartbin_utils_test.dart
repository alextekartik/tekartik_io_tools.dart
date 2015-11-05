@TestOn("vm")
library process_utils_tests;

import 'package:dev_test/test.dart';
import 'package:tekartik_io_tools/process_utils.dart';
import 'package:tekartik_io_tools/dartbin_utils.dart';
import 'package:path/path.dart';

void main() => defineTests();

void defineTests() {
  group('dart', () {
    test('dart', () async {
      RunResult result = await run(dartVmBin, ['--version']);
      // "Dart VM version: 1.7.0-dev.4.5 (Thu Oct  9 01:44:31 2014) on "linux_x64"\n"
      expect(result.err.contains("version"), isTrue);
    });

    test('path', () {
      expect(isAbsolute(dartVmBin), isTrue);
    });

    test('connectIo', () async {
      // change false to true to check that you get output
      RunResult result = await run(dartVmBin, ['--version'], connectIo: false);
      expect(result.err.contains("version"), isTrue);
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
  });

  group('help', () {
    test('dartfmt', () {
      // change false to true to check that you get output
      return runDartFmt(['--help'], connectIo: false).then((RunResult result) {
        //print("out: ${result.out}");
        //print("err: ${result.err}");
        expect(result.out.contains("Usage: dartfmt"), isTrue);
      });
    });

    test('dartanalyzer', () async {
      // change false to true to check that you get output
      RunResult result = await runDartAnalyzer(['--help']);
      // weird help is now on stderr on dart 1.13.0-dev
      //expect(result.out.contains("Usage: dartanalyzer"), isTrue);
      expect(result.err.contains("Usage: dartanalyzer"), isTrue);
    });

    test('dart2js', () async {
      // change false to true to check that you get output
      RunResult result = await runDart2Js(['--help']);
      expect(result.out.contains("Usage: dart2js"), isTrue);
    });

    test('pub', () async {
      // change false to true to check that you get output
      RunResult result = await runPub(['--help']);
      expect(result.out.contains("Usage: pub"), isTrue);
    });
  });
}
