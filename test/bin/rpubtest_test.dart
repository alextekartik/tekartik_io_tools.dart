@TestOn("vm")
library tekartik_io_tools.bin.rpubtest_test;

import 'package:dev_test/test.dart';
import '../io_test_common.dart';
import 'package:tekartik_io_tools/pub_utils.dart';
import 'package:tekartik_io_tools/process_utils.dart';
import 'package:tekartik_io_tools/dartbin_utils.dart';

void main() {
  test('rpubtest', () async {
    String pkgPath = getPubPackageRootSync(testScriptPath);

    return run(dartVmBin,
        ['bin/rpubtest.dart', 'test/sub/', 'bin', 'test/file_utils_test.dart'],
        workingDirectory: pkgPath).then((RunResult result) {
      expect(result.out.contains("All tests passed"), isTrue);
    });
  });
}
