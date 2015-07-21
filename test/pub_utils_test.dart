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

Future<String> get _pubPackageRoot => getPubPackageRoot(testScriptPath);

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
      expect(await _pubPackageRoot, dirname(dirname(testScriptPath)));
      try {
        await getPubPackageRoot(join('/', 'dummy', 'path'));
        fail('no');
      } catch (e) {

      }
    });

    test('pub_package', () async {
      PubPackage pkg = new PubPackage(await _pubPackageRoot);
      RunResult runResult = await pkg.runTest(['test/data/success_test_.dart'],
      platforms: ["vm"],
      reporter: TestReporter.EXPANDED,
      concurrency: 1);

      expect(runResult.exitCode, 0);
      runResult = await pkg.runTest(['test/data/fail_test_.dart']);
      expect(runResult.exitCode, 1);
    });

    test('rpubpath', () async {
      String pubPackageRoot = await _pubPackageRoot;
      clearOutFolderSync();
      List<String> paths = [];
      await recursivePubPath([pubPackageRoot]).listen((String path) {
        paths.add(path);
      }).asFuture();
      expect(paths, [pubPackageRoot]);

      // with criteria
      paths = [];
      await recursivePubPath([pubPackageRoot], dependencies: ['test']).listen((String path) {
        paths.add(path);
      }).asFuture();
      expect(paths, [pubPackageRoot]);

      paths = [];
      await recursivePubPath([pubPackageRoot], dependencies: ['unittest']).listen((String path) {
        paths.add(path);
      }).asFuture();
      expect(paths, []);

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
