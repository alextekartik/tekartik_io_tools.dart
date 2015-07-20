@TestOn("vm")
library tekartik_io_tools.pub_utils_tests;

import 'package:test/test.dart';
import 'package:tekartik_test/test_utils_io.dart';
import 'package:tekartik_io_tools/pub_utils.dart';
import 'package:tekartik_io_tools/src/rpubpath.dart';
import 'package:tekartik_io_tools/process_utils.dart';
import 'package:path/path.dart';
import 'dart:async';

void main() => defineTests();

Future<String> get pubPackageRoot => getPubPackageRoot(testScriptPath);

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
      expect(await pubPackageRoot, dirname(dirname(testScriptPath)));
      try {
        await getPubPackageRoot(join('/', 'dummy', 'path'));
        fail('no');
      } catch (e) {

      }
    });

    test('pub_package', () async {
      PubPackage pkg = new PubPackage(await getPubPackageRoot(testScriptPath));
      RunResult runResult = await pkg.runTest(['test/data/success_test_.dart'],
      platforms: ["vm"],
      reporter: TestReporter.EXPANDED,
      concurrency: 1);

      expect(runResult.exitCode, 0);
      runResult = await pkg.runTest(['test/data/fail_test_.dart']);
      expect(runResult.exitCode, 1);
    });

    test('rpubpath', () async {
      clearOutFolderSync();
      List<String> paths = [];
      await recursivePubPath([await pubPackageRoot]).listen((String path) {
        paths.add(path);
      }).asFuture();

      bool failed = false;
      try {
        await recursivePubPath([join('/', 'dummy', 'path')]).last;
      } catch (e) {
        failed = true;
      }
      expect(failed, isTrue);

    });


  });


}
