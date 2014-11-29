library git_utils_tests;

import 'package:tekartik_test/test_utils_io.dart';
import 'package:tekartik_io_tools/git_utils.dart';
import 'package:tekartik_io_tools/process_utils.dart';

void main() => defineTests();

void defineTests() {
  //useVMConfiguration();
  group('git', () {
    test('version', () {
      return gitRun(['--version']).then((RunResult result) {
        // git version 1.9.1
        expect(result.out.startsWith("git version"), isTrue);
      });
    });

  });




}
