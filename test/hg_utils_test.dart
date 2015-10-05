@TestOn("vm")
library git_utils_tests;

import 'package:tekartik_io_tools/hg_utils.dart';
import 'package:tekartik_io_tools/process_utils.dart';
import 'dart:io';
import 'package:tekartik_test/test.dart';
import 'io_test_common.dart';
import 'package:path/path.dart';

void main() => defineTests();

void defineTests() {
  //useVMConfiguration();
  group('hg', () {
    bool _isHgSupported;

    setUp(() async {
      if (_isHgSupported == null) {
        _isHgSupported = await isHgSupported;
      }
    });

    test('version', () async {
      if (_isHgSupported) {
        await hgRun(['--version']).then((RunResult result) {
          // git version 1.9.1
          expect(result.out.startsWith("Mercurial Distributed SCM"), isTrue);
        });
      }
    });

    /*
    test('isHgTopLevelPath', () async {
      print(Platform.script);
      //await new Completer().future;
      expect(await isHgTopLevelPath(scriptDirPath), isFalse);
      expect(await isHgTopLevelPath(dirname(scriptDirPath)), isTrue, reason: dirname(scriptDirPath));
    });
    */
    test('isHgRepository', () async {
      expect(
          await isHgRepository('https://bitbucket.org/alextk/public_hg_test'),
          isTrue);
      expect(
          await isHgRepository(
              'https://bitbucket.org/alextk/public_hg_test_NO'),
          isFalse);
      expect(
          await isHgRepository('https://bitbucket.org/alextk/public_git_test'),
          isFalse);
    });

    test('HgProject', () async {
      if (_isHgSupported) {
        String outPath = clearOutTestPath(testDescriptions);
        var prj = new HgProject('https://bitbucket.org/alextk/hg_data_test',
            rootFolder: outPath);
        expect(await (isHgTopLevelPath(outPath)), isFalse);
        await prj.clone();
        expect(await (isHgTopLevelPath(outPath)), isTrue);
        HgStatusResult statusResult = await prj.status();
        expect(statusResult.nothingToCommit, true);
        HgOutgoingResult outgoingResult = await prj.outgoing();
        expect(outgoingResult.branchIsAhead, false);

        File tempFile = new File(join(prj.path, "temp_file.txt"));
        await tempFile.writeAsString("echo");
        statusResult = await prj.status();
        expect(statusResult.nothingToCommit, false);
        outgoingResult = await prj.outgoing();
        expect(outgoingResult.branchIsAhead, false);

        await prj.add(pathspec: ".");
        await prj.commit("test");
        statusResult = await prj.status();
        expect(statusResult.nothingToCommit, true);
        outgoingResult = await prj.outgoing();
        expect(outgoingResult.branchIsAhead, true);
      }
    });
  });
}
