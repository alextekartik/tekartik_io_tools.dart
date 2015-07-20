library tekartik_io_tools.pub_utils_tests;

import 'package:test/test.dart';
import 'package:tekartik_test/test_utils_io.dart';
import 'package:tekartik_io_tools/pub_utils.dart';
import 'package:tekartik_io_tools/process_utils.dart';
import 'package:path/path.dart';

void main() => defineTests();

void defineTests() {
  //useVMConfiguration();
  group('pub', () {


    test('version', () async {
      RunResult result = await runPub(['--version']);
      expect(result.out.startsWith("Pub"), isTrue);
    });

    test('root', () async {
      expect(await isPubPackageRoot(dirname(testScriptPath)), isFalse);
      expect(await isPubPackageRoot(dirname(dirname(dirname(testScriptPath)))), isFalse);
      expect(await isPubPackageRoot(dirname(dirname(testScriptPath))), isTrue);
      expect(await getPubPackageRoot(testScriptPath), dirname(dirname(testScriptPath)));
      try {
        await getPubPackageRoot(join('/', 'dummy', 'path'));
        fail('no');
      } catch (e) {

      }
    });

    test('pub_package', () async {
      PubPackage pkg = new PubPackage(await getPubPackageRoot(testScriptPath));
      RunResult runResult = await pkg.runTest(['test/data/success_test_.dart'],
      platforms: [TestPlaform.VM],
      reporter: TestReporter.EXPANDED,
      concurrency: 1);

      expect(runResult.exitCode, 0);
      runResult = await pkg.runTest(['test/data/fail_test_.dart']);
      expect(runResult.exitCode, 1);
    });


  });


}
