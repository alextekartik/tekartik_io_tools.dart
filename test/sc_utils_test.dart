@TestOn("vm")
library git_utils_tests;

// ignore: deprecated_member_use
import 'package:tekartik_io_tools/hg_utils.dart';
// ignore: deprecated_member_use
import 'package:tekartik_io_tools/git_utils.dart';
// ignore: deprecated_member_use
import 'package:tekartik_io_tools/sc_utils.dart';
import 'package:path/path.dart';
import 'io_test_common.dart';

void main() => defineTests();

void defineTests() {
  group('sc', () {
    test('git', () async {
      bool _isGitSupported = await isGitSupported;

      if (_isGitSupported) {
        String outPath = clearOutTestPath();

        var prj = new GitProject('https://bitbucket.org/alextk/public_git_test',
            rootFolder: outPath);
        await prj.clone();

        expect(await isScTopLevelPath(outPath), isTrue);
        expect(await getScName(outPath), "git");
        expect(await findScTopLevelPath(outPath), outPath);
        String sub = join(outPath, "sub");
        expect(await findScTopLevelPath(sub), outPath);
        expect(await getScName(sub), isNull);
      }
    });

    test('hg', () async {
      bool _isHgSupported = await isHgSupported;

      if (_isHgSupported) {
        String outPath = clearOutTestPath();

        var prj = new HgProject('https://bitbucket.org/alextk/hg_data_test',
            rootFolder: outPath);
        await prj.clone();

        expect(await isScTopLevelPath(outPath), isTrue);
        expect(await getScName(outPath), "hg");
        expect(await findScTopLevelPath(outPath), outPath);
        String sub = join(outPath, "sub");
        expect(await findScTopLevelPath(sub), outPath);
        expect(await getScName(sub), isNull);
      }
    });
  });
}
