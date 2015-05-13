library git_utils_tests;

import 'package:test/test.dart';
import 'package:tekartik_test/test_utils_io.dart';
import 'package:tekartik_io_tools/hg_utils.dart';
import 'package:tekartik_io_tools/platform_utils.dart';
import 'package:tekartik_io_tools/process_utils.dart';
import 'dart:io';
import 'dart:isolate';
import 'dart:async';

import 'package:path/path.dart';

void main() => defineTests();

void defineTests() {
  //useVMConfiguration();
  group('hg', () {
    test('version', () {
      return hgRun(['--version']).then((RunResult result) {
        // git version 1.9.1
        expect(result.out.startsWith("Mercurial Distributed SCM"), isTrue);
      });
    });

    /*
    test('isHgTopLevelPath', () async {
      print(Platform.script);
      //await new Completer().future;
      expect(await isHgTopLevelPath(scriptDirPath), isFalse);
      expect(await isHgTopLevelPath(dirname(scriptDirPath)), isTrue, reason: dirname(scriptDirPath));
    });
    */

    test('HgProject', () async {
      clearOutFolderSync();
      var prj = new HgProject('https://alextk@bitbucket.org/alextk/hg_data_test', rootFolder: outDataPath);
      await prj.clone();
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
      /*
      await tempFile.delete();
      statusResult = await prj.status();
      expect(statusResult.nothingToCommit, true);
      */


      /*
      await prj.checkout(commit: "aa910bac096ac549156e8ea33428bbfc224724c0");
      statusResult = await prj.status();
      expect(statusResult.nothingToCommit, true
      );
      */

    });

  });




}
