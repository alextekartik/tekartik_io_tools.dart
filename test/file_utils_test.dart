@TestOn("vm")
library file_utils_tests;

import 'package:test/test.dart';
import 'package:tekartik_io_tools/file_utils.dart';

import 'package:tekartik_test/test_utils_io.dart';
import 'package:path/path.dart';

import 'dart:io';

void main() => defineTests();

void defineTests() {
  group('copy_file', () {
    setUp(() {
      clearOutFolderSync();
    });

    test('copy_file_if_newer', () {
      String path1 = outDataFilenamePath(SIMPLE_FILE_NAME);
      String path2 = outDataFilenamePath(SIMPLE_FILE_NAME_2);
      writeStringContentSync(path1, SIMPLE_CONTENT);

      return copyFileIfNewer(path1, path2).then((int copied) {
        expect(new File(path2).readAsStringSync(), equals(SIMPLE_CONTENT));
        expect(copied, equals(1));
        return copyFileIfNewer(path1, path2).then((int copied) {
          expect(copied, equals(0));
        });
      });
    });

    test('link_or_copy_file_if_newer', () {
      String path1 = outDataFilenamePath(SIMPLE_FILE_NAME);
      String path2 = outDataFilenamePath(SIMPLE_FILE_NAME_2);

      writeStringContentSync(path1, SIMPLE_CONTENT);

      return linkOrCopyFileIfNewer(path1, path2).then((int copied) {
        if (!Platform.isWindows) {
          expect(FileSystemEntity.isFileSync(path2), isTrue);
        }
        expect(new File(path2).readAsStringSync(), equals(SIMPLE_CONTENT));
        expect(copied, equals(1));
        return linkOrCopyFileIfNewer(path1, path2).then((int copied) {
          expect(copied, equals(0));
        });
      });
    });

    test('copy_files_if_newer', () {
      String sub1 = outDataFilenamePath('sub1');
      String file1 = join(sub1, SIMPLE_FILE_NAME);
      writeStringContentSync(file1, SIMPLE_CONTENT + "1");
      String file2 = join(sub1, SIMPLE_FILE_NAME_2);
      writeStringContentSync(file2, SIMPLE_CONTENT + "2");
      String subSub1 = outDataFilenamePath(join('sub1', 'sub1'));
      String file3 = join(subSub1, SIMPLE_FILE_NAME);
      writeStringContentSync(file3, SIMPLE_CONTENT + "3");

      String sub2 = outDataFilenamePath('sub2');

      return copyFilesIfNewer(sub1, sub2).then((int copied) {
        // check sub
        expect(new File(join(sub2, SIMPLE_FILE_NAME)).readAsStringSync(),
            equals(SIMPLE_CONTENT + "1"));
        expect(new File(join(sub2, SIMPLE_FILE_NAME_2)).readAsStringSync(),
            equals(SIMPLE_CONTENT + "2"));

        // and subSub
        expect(
            new File(join(sub2, 'sub1', SIMPLE_FILE_NAME)).readAsStringSync(),
            equals(SIMPLE_CONTENT + "3"));
        return copyFilesIfNewer(sub1, sub2).then((int copied) {
          expect(copied, equals(0));
        });
      });
    });

    test('link_or_copy_if_newer_file', () {
      String path1 = outDataFilenamePath(SIMPLE_FILE_NAME);
      String path2 = outDataFilenamePath(SIMPLE_FILE_NAME_2);
      writeStringContentSync(path1, SIMPLE_CONTENT);

      return linkOrCopyIfNewer(path1, path2).then((int copied) {
        expect(new File(path2).readAsStringSync(), equals(SIMPLE_CONTENT));
        expect(copied, equals(1));
        return linkOrCopyIfNewer(path1, path2).then((int copied) {
          expect(copied, equals(0));
        });
      });
    });

    test('link_or_copy_if_newer_dir', () {
      String sub1 = outDataFilenamePath('sub1');
      String file1 = join(sub1, SIMPLE_FILE_NAME);
      writeStringContentSync(file1, SIMPLE_CONTENT + "1");

      String sub2 = outDataFilenamePath('sub2');

      return linkOrCopyIfNewer(sub1, sub2).then((int copied) {
        expect(copied, equals(1));
        // check sub
        expect(new File(join(sub2, SIMPLE_FILE_NAME)).readAsStringSync(),
            equals(SIMPLE_CONTENT + "1"));

        return linkOrCopyIfNewer(sub1, sub2).then((int copied) {
          expect(copied, equals(0));
        });
      });
    });

    test('deployEntityIfNewer', () async {
      String sub1 = outDataFilenamePath('sub1');
      String file1 = join(sub1, SIMPLE_FILE_NAME);
      writeStringContentSync(file1, SIMPLE_CONTENT + "1");
      String file2 = join(sub1, SIMPLE_FILE_NAME_2);
      writeStringContentSync(file2, SIMPLE_CONTENT + "2");

      String sub2 = outDataFilenamePath('sub2');

      await deployEntitiesIfNewer(
          sub1, sub2, [SIMPLE_FILE_NAME, SIMPLE_FILE_NAME_2]);
      expect(new File(join(sub2, SIMPLE_FILE_NAME)).readAsStringSync(),
          equals(SIMPLE_CONTENT + "1"));

      int copied = await deployEntitiesIfNewer(
          sub1, sub2, [SIMPLE_FILE_NAME, SIMPLE_FILE_NAME_2]);
      expect(copied, equals(0));
    });
  });

  group('symlink', () {
    setUp(() {
      clearOutFolderSync();
    });

    // new way to link a dir (work on linux/windows
    test('link_dir', () async {
      String sub1 = outDataFilenamePath('sub1');
      String file1 = join(sub1, SIMPLE_FILE_NAME);
      writeStringContentSync(file1, SIMPLE_CONTENT);

      String sub2 = outDataFilenamePath('sub2');
      await linkDir(sub1, sub2).then((count) async {
        expect(FileSystemEntity.isLinkSync(sub2), isTrue);
        if (!Platform.isWindows) {
          expect(FileSystemEntity.isDirectorySync(sub2), isTrue);
        }
        expect(count, equals(1));

        // 2nd time nothing is done
        await linkDir(sub1, sub2).then((count) {
          expect(count, equals(0));
        });
      });
    });

    test('create file symlink', () async {
      // file symlink not supported on windows
      if (Platform.isWindows) {
        return null;
      }
      String path1 = outDataFilenamePath(SIMPLE_FILE_NAME);
      String path2 = outDataFilenamePath(SIMPLE_FILE_NAME_2);
      writeStringContentSync(path1, SIMPLE_CONTENT);

      await linkFile(path1, path2).then((int result) {
        expect(result, 1);
        expect(new File(path2).readAsStringSync(), equals(SIMPLE_CONTENT));
      });
    });
//
//    test('create dir symlink', () {
//      if (Platform.isWindows) {
//        return null;
//      }
//
//      Directory inDir = new Directory(scriptDirPath).parent;
//      Directory outDir = outDataDir;
//
//      return fu.createSymlink(inDir, outDir, 'packages').then((int result) {
//        expect(fu.file(outDir, 'packages/browser/dart.js').existsSync(), isTrue);
//
//      });
//    });
//
//
//
//
//    });
  });
}
