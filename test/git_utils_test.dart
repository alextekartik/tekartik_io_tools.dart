library git_utils_tests;

import 'package:tekartik_core/test/test_utils_io.dart';
import '../lib/git_utils.dart';
import 'package:tekartik_core/process_utils.dart';

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
