@TestOn("vm")
library git_utils_tests;

import 'package:test/test.dart';
import 'package:tekartik_test/test_utils_io.dart';
import 'package:tekartik_io_tools/git_utils.dart';
import 'package:tekartik_io_tools/process_utils.dart';
import 'dart:io';

import 'package:path/path.dart';

void main() {
  //useVMConfiguration();
  group('git', () {
    bool _isGitSupported;

    setUp(() async {
      if (_isGitSupported == null) {
        _isGitSupported = await isGitSupported;
      }
    });

    test('version', () async {
      if (_isGitSupported) {
        await gitRun(['--version']).then((RunResult result) {
          // git version 1.9.1
          expect(result.out.startsWith("git version"), isTrue);
        });
      }
    });


    /*
    test('isGitTopLevelPath', () async {
      print(Platform.script);
      //await new Completer().future;
      expect(await isGitTopLevelPath(scriptDirPath), isFalse);
      expect(await isGitTopLevelPath(dirname(scriptDirPath)), isTrue, reason: dirname(scriptDirPath));
    });
    */

    test('GitProject', () async {
      if (_isGitSupported) {
        //print(join("1", "2"));
        clearOutFolderSync();
        var prj = new GitProject('https://github.com/alextekartik/data_test.git', rootFolder: outDataPath);
        // stderr.write("XXXXX ${outDataPath} XXXX");
        //print(outDataPath);
        await prj.clone();
        GitStatusResult statusResult = await prj.status();
        expect(statusResult.nothingToCommit, true);
        expect(statusResult.branchIsAhead, false);

        File tempFile = new File(join(prj.path, "temp_file.txt"));
        await tempFile.writeAsString("echo");
        statusResult = await prj.status();
        expect(statusResult.nothingToCommit, false);
        expect(statusResult.branchIsAhead, false);

        await prj.add(pathspec: ".");
        await prj.commit("test");
        statusResult = await prj.status();
        expect(statusResult.nothingToCommit, true);
        expect(statusResult.branchIsAhead, true);
      }

    });

  });




}
